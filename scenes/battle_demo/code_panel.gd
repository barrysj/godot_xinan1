extends Control
## Flat combat HUD. Hover pause never owns or clears the player's manual pause.
const Codes = preload("res://game/combat/code_catalog.gd")
const Sockets = preload("res://scenes/battle_demo/code_sockets.gd")
const Icon = preload("res://scenes/battle_demo/code_action_icon.gd")
const Picker = preload("res://scenes/battle_demo/code_type_picker.gd")
var game
var sim
var running := false
var bank_labels := {}
var program_controls := {}
var item_controls := {}
var code_fx: Control
var canvas: Control
var programs: HBoxContainer
var items: VBoxContainer
var summary: Label
var selectors: Array[OptionButton] = []
var selection_box: HBoxContainer
var loadout_key := ""
var pointer := Vector2(-10000,-10000)

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = preload("res://resources/theme/theme-main.tres")
	add_theme_font_override("font",preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
	sim = game.simulation
	get_window().mouse_exited.connect(func(): pointer = Vector2(-10000,-10000))
	canvas = Control.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(canvas)
	var back := ColorRect.new()
	back.color = Color("172332",0.96)
	back.position = Vector2(28,80)
	back.size = Vector2(1208,66)
	back.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(back)
	var bank := HBoxContainer.new()
	bank.position = Vector2(38,82)
	bank.scale = Vector2.ONE*0.6
	canvas.add_child(bank)
	for kind in Codes.RULES.types:
		var sockets := Sockets.new()
		bank.add_child(sockets)
		bank_labels[kind] = sockets
	summary = _label(canvas,"",12)
	summary.position = Vector2(38,128)
	summary.size = Vector2(670,18)
	programs = HBoxContainer.new()
	programs.position = Vector2(770,81)
	programs.add_theme_constant_override("separation",14)
	canvas.add_child(programs)
	selection_box = HBoxContainer.new()
	selection_box.position = Vector2(770,91)
	canvas.add_child(selection_box)
	for slot in range(2):
		var picker := OptionButton.new()
		picker.add_theme_font_size_override("font_size",18)
		for program in Codes.RULES.programs: picker.add_item(program.display_name)
		picker.item_selected.connect(func(index): _select_program(slot,index))
		selection_box.add_child(picker)
		selectors.append(picker)
	items = VBoxContainer.new()
	items.position = Vector2(12,206)
	items.add_theme_constant_override("separation",12)
	canvas.add_child(items)
	for entry in Codes.RULES.items:
		var card := _card(items)
		_label(card,entry.display_name,12)
		var button = Icon.new()
		button.action_id = entry.id
		button.pressed.connect(func(): _use_code_item(entry.id))
		card.add_child(button)
		var controls := {"card":card.get_parent(),"button":button}
		if entry.effect == "convert":
			_label(card,"消耗 2",11)
			controls.source = _picker(card)
		_label(card,"生成 %d" % entry.amount,11)
		controls.destination = _picker(card)
		if entry.effect == "convert": controls.destination.select(1)
		item_controls[entry.id] = controls
	var motion := CheckButton.new()
	motion.text = "简化特效"
	motion.add_theme_font_size_override("font_size",12)
	motion.position = Vector2(1090,151)
	motion.toggled.connect(func(value): code_fx.reduced_motion = value)
	canvas.add_child(motion)
	code_fx = preload("res://scenes/battle_demo/code_fx.gd").new()
	code_fx.host = self
	add_child(code_fx)

func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label

func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("132533",0.97)
	style.border_color = Color("446477")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	for side in ["left","right","top","bottom"]: style.set("content_margin_"+side,5.0)
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",3)
	panel.add_child(box)
	return box

func _picker(parent: Node) -> HBoxContainer:
	var picker := Picker.new()
	parent.add_child(picker)
	picker.item_selected.connect(func(_index): _update_hud())
	return picker

func _select_program(slot: int,index: int) -> void:
	if game.phase != "prepare": return
	var before: Array = sim.loadout.duplicate()
	var chosen: Array = before.duplicate()
	var id: String = Codes.RULES.programs[index].id
	var other := chosen.find(id)
	if other >= 0: chosen[other] = chosen[slot]
	chosen[slot] = id
	var build = game.get("run")
	if build != null: build.code_programs = chosen.duplicate()
	else: game.code_programs = chosen.duplicate()
	sim.loadout = chosen
	if game.has_method("_checkpoint") and not game._checkpoint():
		if build != null: build.code_programs = before.duplicate()
		else: game.code_programs = before.duplicate()
		sim.loadout = before

func _process(_delta: float) -> void:
	var screen = game.get("screen")
	visible = (screen == null or screen == "battle") and game.phase in ["prepare","battle"]
	if not visible: return
	sim = game.simulation
	running = game.phase == "battle"
	var factor: float = minf(game.size.x/1280.0,game.size.y/720.0)
	canvas.scale = Vector2.ONE*factor
	canvas.position = (game.size-Vector2(1280,720)*factor)/2
	programs.visible = running
	items.visible = running
	selection_box.visible = not running
	for slot in range(selectors.size()):
		for index in range(Codes.RULES.programs.size()):
			if Codes.RULES.programs[index].id == sim.loadout[slot]: selectors[slot].select(index)
	var key: String = str(sim.loadout)
	if key != loadout_key:
		loadout_key = key
		for child in programs.get_children(): child.free()
		program_controls.clear()
		for id in sim.loadout:
			var data = Codes.program(id)
			var card := _card(programs)
			var button = Icon.new()
			button.action_id = id
			button.custom_minimum_size = Vector2(160,34)
			button.pressed.connect(func(): _cast_code(id))
			card.add_child(button)
			button.custom_minimum_size = Vector2(160,34)
			var name_label := _label(button,data.display_name,13)
			name_label.position = Vector2(8,7)
			var cost := HBoxContainer.new()
			cost.add_theme_constant_override("separation",8)
			card.add_child(cost)
			var recipe := {}
			for kind in data.cost:
				recipe[kind] = _label(cost,"%s %d" % [Codes.RULES.types[kind].name,data.cost[kind]],12)
			program_controls[id] = {"card":card.get_parent(),"button":button,"recipe":recipe}
	_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse: pointer = event.position

func hover_paused() -> bool:
	if not is_visible_in_tree() or game.phase != "battle" or game.get("screen") not in [null,"battle"]: return false
	for group in [program_controls,item_controls]:
		for controls in group.values():
			if controls.card.is_visible_in_tree() and controls.card.get_global_rect().has_point(pointer): return true
	return false

func _update_hud() -> void:
	for kind in bank_labels: bank_labels[kind].configure(kind,sim.blocks.get(kind,0),Codes.RULES.cache_cap)
	for id in program_controls:
		var controls: Dictionary = program_controls[id]
		var error: String = sim.program_error(id)
		controls.button.disabled = not error.is_empty() or game.paused
		controls.button.available = error.is_empty()
		controls.button.queue_redraw()
		controls.card.tooltip_text = Codes.program(id).description+"\n"+("就绪 · 点击释放" if error.is_empty() else error)+"\n悬停暂停 · 移开继续"
		for kind in controls.recipe:
			var color: Color = Codes.RULES.types[kind].color
			controls.recipe[kind].modulate = color if sim.blocks.get(kind,0) >= Codes.program(id).cost[kind] else Color(color,0.42)
	for id in item_controls:
		var controls: Dictionary = item_controls[id]
		var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
		var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
		var error: String = sim.item_error(id,destination,source)
		controls.button.disabled = not error.is_empty() or game.paused
		controls.button.available = error.is_empty()
		controls.button.remaining = sim.items.get(id,0)
		controls.button.queue_redraw()
		controls.card.tooltip_text = Codes.item(id).description+"\n"+("就绪 · 点击使用" if error.is_empty() else error)+"\n悬停暂停 · 移开继续"
	summary.text = ("悬停暂停  ·  " if hover_paused() and not game.paused else "")+"羁绊："+("、".join(sim.tags) if not sim.tags.is_empty() else "未激活")+"  ·  "+sim.system_status()+"  ·  下次维护 %.1f秒" % maxf(0,sim.next_pulse-sim.elapsed)

func code_origin(event: Dictionary) -> Vector2:
	return game.origin+(game._project(event.from)-Vector2(0,35))*game.scale_factor
func consume(event: Dictionary) -> void:
	if is_instance_valid(code_fx): code_fx.consume(event)
func _consume_pending() -> void:
	for event in sim.drain_events(): game._present_simulation_event(event)
func _cast_code(id: String) -> void:
	if not running or game.paused or not sim.cast_program(id): return
	_consume_pending()
	_update_hud()
func _use_code_item(id: String) -> void:
	if not running or game.paused: return
	var controls: Dictionary = item_controls[id]
	var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
	var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
	if sim.use_item(id,destination,source): _consume_pending()
	_update_hud()
func feedback_frozen() -> bool:
	return game.paused or hover_paused()
