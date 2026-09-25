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
var program_preview: PanelContainer
var preview_title: Label
var preview_effect: Label
var preview_state: Label
var preview_release: Button
var preview_program_id := ""
var preview_pinned := false
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
	_build_program_preview()
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

func _build_program_preview() -> void:
	program_preview = PanelContainer.new()
	program_preview.custom_minimum_size.x = 218
	program_preview.z_index = 4
	program_preview.visible = false
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color(0.05,0.11,0.18,0.82)
	surface.border_color = Color("76e5cb",0.85)
	surface.set_border_width_all(2)
	surface.set_corner_radius_all(6)
	for side in ["left","right","top","bottom"]: surface.set("content_margin_"+side,9.0)
	program_preview.add_theme_stylebox_override("panel",surface)
	canvas.add_child(program_preview)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",5)
	program_preview.add_child(content)
	preview_title = _label(content,"",16)
	preview_effect = _label(content,"",12)
	preview_effect.custom_minimum_size.x = 196
	preview_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_state = _label(content,"",11)
	preview_release = Button.new()
	preview_release.text = "释放"
	preview_release.custom_minimum_size.y = 35
	for state in ["normal","hover","pressed","disabled"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("248979") if state == "normal" else Color("35b59b") if state == "hover" else Color("176c60") if state == "pressed" else Color("263a45",0.75)
		button_style.set_corner_radius_all(4)
		preview_release.add_theme_stylebox_override(state,button_style)
	preview_release.add_theme_color_override("font_color",Color.WHITE)
	preview_release.add_theme_color_override("font_hover_color",Color.WHITE)
	preview_release.pressed.connect(func(): _cast_code(preview_program_id))
	content.add_child(preview_release)

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
		_hide_program_preview()
		if not selected_item.is_empty(): _select_item("")
		return
	sim = game.simulation
	running = game.phase == "battle"
	if not running: _hide_program_preview()
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
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(160,34)
			button.pressed.connect(func(): _show_program_preview(id,true))
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
	_sync_program_preview()
	_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		pointer = event.position
		if event is InputEventMouseButton and event.pressed and preview_pinned and not _pointer_on_program_area(pointer):
			_hide_program_preview()
	elif event is InputEventScreenTouch and event.pressed:
		if not running or game.paused: return
		var at: Vector2 = event.position
		if program_preview.visible and preview_release.get_global_rect().has_point(at):
			_cast_code(preview_program_id)
			get_viewport().set_input_as_handled()
			return
		for id in program_controls:
			if program_controls[id].card.get_global_rect().has_point(at):
				_show_program_preview(id,true)
				get_viewport().set_input_as_handled()
				return
		if preview_pinned and not _pointer_on_program_area(at): _hide_program_preview()

func _pointer_on_program_area(at: Vector2) -> bool:
	if program_preview.visible and program_preview.get_global_rect().has_point(at): return true
	for controls in program_controls.values():
		if controls.card.is_visible_in_tree() and controls.card.get_global_rect().has_point(at): return true
	return false

func _show_program_preview(id: String, pin: bool) -> void:
	if not running or game.paused or not program_controls.has(id): return
	preview_program_id = id
	preview_pinned = pin
	program_preview.visible = true
	var data = Codes.program(id)
	preview_title.text = data.display_name
	preview_effect.text = data.description
	for program_id in program_controls:
		program_controls[program_id].button.button_pressed = program_id == id
	_position_program_preview()
	_update_hud()

func _hide_program_preview() -> void:
	if preview_program_id.is_empty(): return
	preview_program_id = ""
	preview_pinned = false
	program_preview.visible = false
	for controls in program_controls.values(): controls.button.button_pressed = false

func _sync_program_preview() -> void:
	if not running or not is_visible_in_tree(): return
	if preview_pinned:
		_position_program_preview()
		return
	for id in program_controls:
		if program_controls[id].card.get_global_rect().has_point(pointer):
			if preview_program_id != id: _show_program_preview(id,false)
			else: _position_program_preview()
			return
	if program_preview.visible and program_preview.get_global_rect().has_point(pointer): return
	_hide_program_preview()

func _position_program_preview() -> void:
	if not program_controls.has(preview_program_id): return
	var card: Control = program_controls[preview_program_id].card
	var x: float = programs.position.x + card.position.x
	program_preview.position = Vector2(minf(x, 1230 - maxf(program_preview.size.x,218)), programs.position.y + maxf(card.size.y,66) - 1)

func _select_item(id: String) -> void:
	if not id.is_empty() and (not running or game.paused): return
	selected_item = "" if id == selected_item else id
	for item_id in item_controls:
		item_controls[item_id].card.visible = item_id == selected_item
		item_controls[item_id].icon.button_pressed = item_id == selected_item
	_update_hud()

func hover_paused() -> bool:
	if not is_visible_in_tree() or game.phase != "battle" or game.get("screen") not in [null,"battle"]: return false
	if preview_pinned and program_preview.visible: return true
	for controls in program_controls.values():
		if controls.card.is_visible_in_tree() and controls.card.get_global_rect().has_point(pointer): return true
	if program_preview.visible and program_preview.get_global_rect().has_point(pointer): return true
	for controls in item_controls.values():
		if controls.icon.is_visible_in_tree() and controls.icon.get_global_rect().has_point(pointer): return true
		if controls.card.is_visible_in_tree() and controls.card.get_global_rect().has_point(pointer): return true
	return false

func _update_hud() -> void:
	for kind in bank_labels: bank_labels[kind].configure(kind,sim.blocks.get(kind,0),Codes.RULES.cache_cap)
	for id in program_controls:
		var controls: Dictionary = program_controls[id]
		var error: String = sim.program_error(id)
		controls.button.disabled = game.paused
		controls.button.available = error.is_empty()
		controls.button.queue_redraw()
		for kind in controls.recipe:
			controls.recipe[kind].configure(kind, Codes.program(id).cost[kind], sim.blocks.get(kind,0) >= Codes.program(id).cost[kind])
	if not preview_program_id.is_empty():
		var preview_error: String = sim.program_error(preview_program_id)
		preview_state.text = "就绪" if preview_error.is_empty() else preview_error
		preview_release.disabled = not preview_error.is_empty() or game.paused
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
	summary.text = (("操作暂停  ·  " if preview_pinned else "悬停暂停  ·  ") if hover_paused() and not game.paused else "")+"羁绊："+("、".join(sim.tags) if not sim.tags.is_empty() else "未激活")+"  ·  "+sim.system_status()+"  ·  下次维护 %.1f秒" % maxf(0,sim.next_pulse-sim.elapsed)

func code_origin(event: Dictionary) -> Vector2:
	return game.origin+(game._project(event.from)-Vector2(0,35))*game.scale_factor
func consume(event: Dictionary) -> void:
	if is_instance_valid(code_fx): code_fx.consume(event)
func _consume_pending() -> void:
	for event in sim.drain_events(): game._present_simulation_event(event)
func _cast_code(id: String) -> void:
	if not running or game.paused or not program_preview.visible or preview_program_id != id or not sim.cast_program(id): return
	_consume_pending()
	_hide_program_preview()
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
