extends Control
## Flat combat HUD. Hover pause never owns or clears the player's manual pause.
const Codes = preload("res://game/combat/code_catalog.gd")
const Sockets = preload("res://scenes/battle_demo/code_sockets.gd")
const Chip = preload("res://scenes/battle_demo/code_resource_chip.gd")
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
var item_details: Control
var selected_item := ""
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
	items.add_theme_constant_override("separation",8)
	canvas.add_child(items)
	item_details = Control.new()
	item_details.position = Vector2(76,206)
	item_details.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(item_details)
	for entry in Codes.RULES.items:
		var icon := Icon.new()
		icon.action_id = entry.id
		icon.toggle_mode = true
		icon.pressed.connect(func(): _select_item(entry.id))
		items.add_child(icon)
		var card := _card(item_details)
		card.get_parent().custom_minimum_size.x = 182
		card.get_parent().visible = false
		_label(card,entry.display_name,15)
		var effect := _label(card,entry.description,12)
		effect.custom_minimum_size.x = 170
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var controls := {"card":card.get_parent(),"icon":icon}
		if entry.effect == "convert":
			controls.source_preview = Chip.new()
			card.add_child(controls.source_preview)
			controls.source = _picker(card)
		controls.destination_preview = Chip.new()
		card.add_child(controls.destination_preview)
		controls.destination = _picker(card)
		if entry.effect == "convert": controls.destination.select(1)
		controls.state = _label(card,"",11)
		var use_button := Button.new()
		use_button.text = "使用"
		use_button.custom_minimum_size.y = 34
		use_button.pressed.connect(func(): _use_code_item(entry.id))
		card.add_child(use_button)
		controls.button = use_button
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
	if not visible:
		if not selected_item.is_empty(): _select_item("")
		return
	sim = game.simulation
	running = game.phase == "battle"
	if not running and not selected_item.is_empty(): _select_item("")
	var factor: float = minf(game.size.x/1280.0,game.size.y/720.0)
	canvas.scale = Vector2.ONE*factor
	canvas.position = (game.size-Vector2(1280,720)*factor)/2
	programs.visible = running
	items.visible = running
	item_details.visible = running
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
				var chip := Chip.new()
				chip.configure(kind, data.cost[kind], false)
				cost.add_child(chip)
				recipe[kind] = chip
			program_controls[id] = {"card":card.get_parent(),"button":button,"recipe":recipe}
	_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse: pointer = event.position

func _select_item(id: String) -> void:
	if not id.is_empty() and (not running or game.paused): return
	selected_item = "" if id == selected_item else id
	for item_id in item_controls:
		item_controls[item_id].card.visible = item_id == selected_item
		item_controls[item_id].icon.button_pressed = item_id == selected_item
	_update_hud()

func hover_paused() -> bool:
	if not is_visible_in_tree() or game.phase != "battle" or game.get("screen") not in [null,"battle"]: return false
	for controls in program_controls.values():
		if controls.card.is_visible_in_tree() and controls.card.get_global_rect().has_point(pointer): return true
	for controls in item_controls.values():
		if controls.icon.is_visible_in_tree() and controls.icon.get_global_rect().has_point(pointer): return true
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
			controls.recipe[kind].configure(kind, Codes.program(id).cost[kind], sim.blocks.get(kind,0) >= Codes.program(id).cost[kind])
	for id in item_controls:
		var controls: Dictionary = item_controls[id]
		var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
		var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
		var error: String = sim.item_error(id,destination,source)
		if controls.has("source_preview"):
			controls.source_preview.configure(source, 2, sim.blocks.get(source,0) >= 2, "−")
		controls.destination_preview.configure(destination, Codes.item(id).amount, sim.blocks.get(destination,0) + Codes.item(id).amount <= Codes.RULES.cache_cap, "+")
		controls.button.disabled = not error.is_empty() or game.paused
		controls.state.text = "就绪" if error.is_empty() else error
		controls.icon.available = sim.items.get(id,0) > 0
		controls.icon.remaining = sim.items.get(id,0)
		controls.icon.tooltip_text = Codes.item(id).display_name+" · 点击查看"
		controls.icon.queue_redraw()
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
	if not running or game.paused or selected_item != id: return
	var controls: Dictionary = item_controls[id]
	var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
	var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
	if sim.use_item(id,destination,source):
		_consume_pending()
		_select_item("")
	_update_hud()
func feedback_frozen() -> bool:
	return game.paused or hover_paused()
