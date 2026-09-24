extends Control
## Original battle UI extension. No trial flow, roster or board is instantiated here.
const Codes = preload("res://game/combat/code_catalog.gd")
const Sockets = preload("res://scenes/battle_demo/code_sockets.gd")
var game
var sim
var paused := false
var running := false
var console: PanelContainer
var console_shade: ColorRect
var console_labels := {}
var bank_labels := {}
var program_controls := {}
var item_controls := {}
var code_fx: Control
var hud_back: ColorRect
var hud: HBoxContainer
var open_button: Button
var summary: Label
var selectors: Array[OptionButton] = []
var selection_box: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = preload("res://resources/theme/theme-main.tres")
	add_theme_font_override("font", preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
	sim = game.simulation
	hud_back = ColorRect.new()
	hud_back.color = Color("172332",0.96)
	hud_back.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(hud_back)
	hud = HBoxContainer.new()
	add_child(hud)
	hud.add_theme_constant_override("separation", 8)
	bank_labels = _code_row(hud)
	open_button = _button(hud,"破解",_open_console)
	selection_box = HBoxContainer.new()
	hud.add_child(selection_box)
	for slot in range(2):
		var picker := OptionButton.new()
		for program in Codes.RULES.programs: picker.add_item(program.display_name)
		picker.item_selected.connect(func(index): _select_program(slot,index))
		selection_box.add_child(picker)
		selectors.append(picker)
	summary = _label(self,"",17)
	_build_console()
	code_fx = preload("res://scenes/battle_demo/code_fx.gd").new()
	code_fx.host = self
	add_child(code_fx)

func _select_program(slot: int,index: int) -> void:
	if game.phase != "prepare": return
	var before: Array = sim.loadout.duplicate()
	var programs: Array = before.duplicate()
	var id: String = Codes.RULES.programs[index].id
	var other := programs.find(id)
	if other >= 0: programs[other] = programs[slot]
	programs[slot] = id
	var build = game.get("run")
	if build != null: build.code_programs = programs.duplicate()
	else: game.code_programs = programs.duplicate()
	sim.loadout = programs
	if game.has_method("_checkpoint") and not game._checkpoint():
		if build != null: game.run.code_programs = before.duplicate()
		else: game.code_programs = before.duplicate()
		sim.loadout = before

func _process(_delta: float) -> void:
	var screen = game.get("screen")
	visible = (screen == null or screen == "battle") and game.phase in ["prepare","battle"]
	if not visible:
		if paused: _close_console()
		return
	sim = game.simulation
	running = game.phase == "battle"
	var factor: float = minf(game.size.x/1280.0,game.size.y/720.0)
	var offset: Vector2 = (game.size-Vector2(1280,720)*factor)/2
	hud.position = offset+Vector2(38,82)*factor
	hud.scale = Vector2.ONE*factor*0.6
	hud.size = Vector2(1640,76)
	hud_back.position = offset+Vector2(28,80)*factor
	hud_back.size = Vector2(1208,66)*factor
	summary.position = offset+Vector2(40,125)*factor
	summary.size.x = 1150*factor
	selection_box.visible = not running
	open_button.visible = running
	for slot in range(selectors.size()):
		for index in range(Codes.RULES.programs.size()):
			if Codes.RULES.programs[index].id == sim.loadout[slot]: selectors[slot].select(index)
	_update_hud()
	if paused:
		console.size = Vector2(1120,700)
		console.position = (size-console.size)/2

func _open_console() -> void:
	if not running or sim.finished or game.paused: return
	if is_instance_valid(game.deployment): game.deployment.cancel()
	if is_instance_valid(game.inspector): game.inspector.hide()
	console.free()
	console_shade.free()
	console_labels.clear()
	program_controls.clear()
	item_controls.clear()
	_build_console()
	paused = true
	game.paused = true
	for node in [console,console_shade]: node.show()
	_update_hud()
	var focusables: Array[Control] = []
	_collect_console_focus(console,focusables)
	if not focusables.is_empty(): focusables[0].grab_focus()

func _close_console() -> void:
	console.hide()
	console_shade.hide()
	paused = false
	game.paused = false
	game.accumulator = 0
	if is_instance_valid(game.inspector): game.inspector.show()
	open_button.grab_focus()

func code_origin(event: Dictionary) -> Vector2:
	return game.origin + (game._project(event.from)-Vector2(0,35))*game.scale_factor

func consume(event: Dictionary) -> void:
	if is_instance_valid(code_fx): code_fx.consume(event)

func _consume_pending() -> void:
	for event in sim.drain_events(): game._present_simulation_event(event)

func _update_hud() -> void:
	for group in [bank_labels,console_labels]:
		for kind in group: group[kind].configure(kind,sim.blocks.get(kind,0),Codes.RULES.cache_cap)
	for id in program_controls:
		var error: String = sim.program_error(id)
		program_controls[id].button.disabled = not error.is_empty()
		program_controls[id].state.text = "就绪" if error.is_empty() else error
		for kind in program_controls[id].recipe:
			program_controls[id].recipe[kind].configure(kind,mini(sim.blocks.get(kind,0),Codes.program(id).cost[kind]),Codes.program(id).cost[kind])
	for id in item_controls:
		var controls: Dictionary = item_controls[id]
		var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
		var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
		var error: String = sim.item_error(id,destination,source)
		controls.button.disabled = not error.is_empty()
		controls.preview.configure(destination,Codes.item(id).amount,Codes.item(id).amount,"生成 · "+Codes.RULES.types[destination].name)
		controls.state.text = "剩余%d次 · %s" % [sim.items.get(id,0),error if not error.is_empty() else "就绪"]
	summary.text = "羁绊："+("、".join(sim.tags) if not sim.tags.is_empty() else "未激活")+"  ·  "+sim.system_status()+"  ·  下次维护 %.1f秒" % maxf(0,sim.next_pulse-sim.elapsed)
	if paused: _link_console_focus()
func _label(parent: Node, text: String, font_size := 23) -> Label:
	var label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 48)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _row(parent: Node) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	return row

func _code_row(parent: Node) -> Dictionary:
	var row := _row(parent)
	var sockets := {}
	for kind in Codes.RULES.types:
		var display := Sockets.new()
		display.configure(kind, 0, Codes.RULES.cache_cap)
		row.add_child(display)
		sockets[kind] = display
	return sockets

func _code_card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172b3e")
	style.border_color = Color("38556c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box
func _build_console() -> void:
	console_shade = ColorRect.new()
	console_shade.color = Color(0, 0, 0, 0.72)
	console_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	console_shade.z_index = 3998
	console_shade.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: _close_console())
	add_child(console_shade)
	console_shade.hide()
	console = PanelContainer.new()
	console.name = "CodeConsole"
	console.custom_minimum_size = Vector2(1120, 700)
	console.size = Vector2(1120, 700)
	console.z_index = 3999
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("101f30")
	surface.border_color = Color("76e5cb")
	surface.set_border_width_all(2)
	surface.set_corner_radius_all(12)
	console.add_theme_stylebox_override("panel", surface)
	add_child(console)
	console.hide()
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 22)
	console.add_child(margin)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 1072
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	var heading := _row(box)
	_label(heading, "代码终端 · 战斗已暂停", 26)
	_button(heading, "继续", _close_console)
	var motion := CheckButton.new()
	motion.text = "简化特效"
	motion.button_pressed = is_instance_valid(code_fx) and code_fx.reduced_motion
	motion.toggled.connect(func(value: bool): code_fx.reduced_motion = value)
	heading.add_child(motion)
	console_labels = _code_row(box)
	_label(box, "实心代码已备齐 · 空槽仍需收集  /  程序共享3秒冷却", 17)
	var programs := _row(box)
	for id in sim.loadout:
		var program = Codes.program(id)
		var card := _code_card(programs)
		var header := _row(card)
		var symbols := {"disconnect":"⌁", "redirect":"⇄", "repair":"+", "takeover":"#"}
		_label(header, symbols[id] + "  " + program.display_name, 26)
		var button := _button(header, "执行", func(): _cast_code(id))
		button.tooltip_text = program.description
		var ingredients := _row(card)
		var recipe := {}
		for kind in program.cost:
			var sockets := Sockets.new()
			sockets.configure(kind, 0, program.cost[kind])
			ingredients.add_child(sockets)
			recipe[kind] = sockets
		_label(card, program.description, 17)
		var state := _label(card, "", 17)
		program_controls[id] = {"button":button, "state":state, "recipe":recipe}
	var items := _row(box)
	for entry in Codes.RULES.items:
		var id: String = entry.id
		var card := _code_card(items)
		var header := _row(card)
		_label(header, ("⊞  " if entry.effect == "generate" else "⇄  ") + entry.display_name, 22)
		var button := _button(header, "使用", func(): _use_code_item(id))
		button.tooltip_text = entry.description
		var row := _row(card)
		var controls := {"button":button}
		if entry.effect == "convert":
			controls.source = _type_picker(row)
			var arrow := _label(row, "−2 →", 18)
			arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
			arrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		controls.destination = _type_picker(row)
		if entry.effect == "convert": controls.destination.select(1)
		controls.preview = Sockets.new()
		card.add_child(controls.preview)
		controls.state = _label(card, "", 17)
		item_controls[id] = controls
func _type_picker(parent: Node) -> OptionButton:
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(150, 44)
	for kind in Codes.RULES.types:
		var data: Dictionary = Codes.RULES.types[kind]
		picker.add_item(data.symbol + " " + data.name)
	parent.add_child(picker)
	picker.item_selected.connect(func(_index): _update_hud())
	return picker

func _link_console_focus() -> void:
	var buttons: Array[Control] = []
	_collect_console_focus(console, buttons)
	for index in range(buttons.size()):
		buttons[index].focus_next = buttons[index].get_path_to(buttons[(index + 1) % buttons.size()])
		buttons[index].focus_previous = buttons[index].get_path_to(buttons[posmod(index - 1, buttons.size())])

func _collect_console_focus(node: Node, output: Array[Control]) -> void:
	for child in node.get_children():
		if child is BaseButton and not child.disabled: output.append(child)
		_collect_console_focus(child, output)

func _cast_code(id: String) -> void:
	if not running or not paused or not sim.cast_program(id): return
	_consume_pending()
	_update_hud()
	_close_console()

func _use_code_item(id: String) -> void:
	if not running or not paused: return
	var controls: Dictionary = item_controls[id]
	var destination: String = Codes.RULES.types.keys()[controls.destination.selected]
	var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
	if sim.use_item(id, destination, source): _consume_pending()
	_update_hud()






func feedback_frozen() -> bool:
	return game.paused
