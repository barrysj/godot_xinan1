extends Control
## Flat combat HUD. Hover pause never owns or clears the player's manual pause.
const Codes = preload("res://game/combat/code_catalog.gd")
const Sockets = preload("res://scenes/battle_demo/code_sockets.gd")
const Chip = preload("res://scenes/battle_demo/code_resource_chip.gd")
const Icon = preload("res://scenes/battle_demo/code_action_icon.gd")
const Picker = preload("res://scenes/battle_demo/code_type_picker.gd")
var game
var activity: Control
var buff_button: Button
var buff_details: RichTextLabel
var dock: PanelContainer
var playback: VBoxContainer
var clock: Label
var pause_control: Button
var speed_control: HBoxContainer
var speed_down: Button
var speed_up: Button
var speed_value: Label
var item_group: VBoxContainer
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
var preview_effect: RichTextLabel
var preview_state: Label
var preview_release: Button
var preview_target: OptionButton
var preview_payment: HBoxContainer
var payment_inputs := {}
var target_key := ""
var payment_editing := false
var preview_program_id := ""
var preview_pinned := false
var items: HBoxContainer
var item_details: Control
var selected_item := ""
var summary: Label
var bond_panel: PanelContainer
var bond_list: VBoxContainer
var bond_rows := {}
var bond_counts := {}
var bond_members := {}
var bond_key := ""
var selectors: Array[OptionButton] = []
var selection_box: HBoxContainer
var loadout_key := ""
var pointer := Vector2(-10000,-10000)
var hud_dirty := true
var hud_time := -1.0
var hud_pause := false
var hud_hover_pause := false
var top_row: HBoxContainer
var journal_stack: VBoxContainer
var warning_surface: PanelContainer
var warning_row: HBoxContainer
var warning_text: Label
var warning_progress: ProgressBar
var simulation_ref

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = preload("res://resources/theme/theme-main.tres")
	add_theme_font_override("font",preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
	sim = game.simulation
	get_window().mouse_exited.connect(func(): pointer = Vector2(-10000,-10000))
	canvas = Control.new()
	canvas.size = Vector2(1280,720)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(canvas)
	dock = PanelContainer.new()
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_left = 40
	dock.offset_right = -40
	dock.offset_top = -100
	dock.offset_bottom = -12
	dock.mouse_filter = MOUSE_FILTER_IGNORE
	var dock_style := StyleBoxFlat.new()
	dock_style.bg_color = Color("101f2c")
	dock_style.border_color = Color("557584")
	dock_style.set_border_width_all(1)
	dock_style.border_width_top = 2
	dock_style.set_corner_radius_all(8)
	dock_style.content_margin_left = 16
	dock_style.content_margin_right = 16
	dock_style.content_margin_top = 6
	dock_style.content_margin_bottom = 6
	dock.add_theme_stylebox_override("panel",dock_style)
	canvas.add_child(dock)
	var dock_row := HBoxContainer.new()
	dock_row.mouse_filter = MOUSE_FILTER_IGNORE
	dock_row.add_theme_constant_override("separation",18)
	dock.add_child(dock_row)
	var stock_group := _dock_group(dock_row,"代码",Color("7eb8ec"))
	var bank := GridContainer.new()
	bank.columns = 2
	bank.add_theme_constant_override("h_separation",8)
	bank.add_theme_constant_override("v_separation",3)
	stock_group.add_child(bank)
	for kind in Codes.RULES.types:
		var sockets := Sockets.new()
		sockets.slim = true
		sockets.mouse_filter = MOUSE_FILTER_PASS
		sockets.kind = kind
		sockets.custom_minimum_size = Vector2(94,26)
		bank.add_child(sockets)
		bank_labels[kind] = sockets
	var hack_group := _dock_group(dock_row,"破解",Color("75e0c7"))
	item_group = _dock_group(dock_row,"道具",Color("edc482"))
	var gap := Control.new()
	gap.mouse_filter = MOUSE_FILTER_IGNORE
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	dock_row.add_child(gap)
	playback = VBoxContainer.new()
	playback.add_theme_constant_override("separation",4)
	playback.size_flags_vertical = SIZE_SHRINK_CENTER
	dock_row.add_child(playback)
	var timing_row := HBoxContainer.new()
	timing_row.add_theme_constant_override("separation",4)
	timing_row.custom_minimum_size = Vector2(88,18)
	playback.add_child(timing_row)
	clock = _label(timing_row,"00:00",12)
	clock.size_flags_horizontal = SIZE_EXPAND_FILL
	clock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clock.tooltip_text = "本场战斗用时"
	summary = _label(timing_row,"进行中",10)
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_control = _playback_button(playback,"Ⅱ",Color("6cddc2"))
	pause_control.custom_minimum_size = Vector2(88,24)
	pause_control.tooltip_text = "暂停 / 继续（P）"
	pause_control.pressed.connect(func(): game._toggle_manual_pause())
	speed_control = HBoxContainer.new()
	speed_control.custom_minimum_size = Vector2(88,24)
	speed_control.add_theme_constant_override("separation",0)
	playback.add_child(speed_control)
	speed_down = _speed_button("−",-1)
	var speed_surface := PanelContainer.new()
	speed_surface.custom_minimum_size = Vector2(52,24)
	var speed_style := StyleBoxFlat.new()
	speed_style.bg_color = Color("e9c183")
	speed_surface.add_theme_stylebox_override("panel",speed_style)
	speed_control.add_child(speed_surface)
	speed_value = _label(speed_surface,"1.0×",11)
	speed_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speed_value.add_theme_color_override("font_color",Color("10232d"))
	speed_up = _speed_button("+",1)

	top_row = HBoxContainer.new()
	top_row.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	top_row.offset_left = 28
	top_row.offset_right = -28
	top_row.offset_top = 62
	top_row.offset_bottom = 118
	top_row.add_theme_constant_override("separation",16)
	top_row.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(top_row)
	bond_panel = PanelContainer.new()
	bond_panel.size_flags_vertical = SIZE_SHRINK_BEGIN
	bond_panel.z_index = 20
	bond_panel.custom_minimum_size = Vector2(244,40)
	var bond_style := StyleBoxFlat.new()
	bond_style.bg_color = Color("132533",0.96)
	bond_style.set_content_margin_all(4)
	bond_style.border_color = Color("446477")
	bond_style.set_border_width_all(1)
	bond_style.set_corner_radius_all(4)
	bond_panel.add_theme_stylebox_override("panel",bond_style)
	top_row.add_child(bond_panel)
	bond_list = VBoxContainer.new()
	bond_list.add_theme_constant_override("separation",0)
	bond_panel.add_child(bond_list)
	for definition in preload("res://game/combat/combat_content_catalog.gd").MANIFEST.synergies:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",4)
		bond_list.add_child(row)
		var entry = preload("res://scenes/ui/glossary_text.gd").make("",11)
		entry.custom_minimum_size.x = 72
		row.add_child(entry)
		var count := _label(row,"0/2",11)
		count.custom_minimum_size.x = 28
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bond_rows[definition.id] = entry
		bond_counts[definition.id] = count
		var members := HBoxContainer.new()
		members.add_theme_constant_override("separation",2)
		row.add_child(members)
		bond_members[definition.id] = members
	var left_gap := Control.new()
	left_gap.mouse_filter = MOUSE_FILTER_IGNORE
	left_gap.size_flags_horizontal = SIZE_EXPAND_FILL
	top_row.add_child(left_gap)
	var warning_slot := Control.new()
	warning_slot.custom_minimum_size = Vector2(450,32)
	warning_slot.mouse_filter = MOUSE_FILTER_IGNORE
	warning_slot.size_flags_vertical = SIZE_SHRINK_BEGIN
	top_row.add_child(warning_slot)
	warning_surface = PanelContainer.new()
	warning_surface.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	warning_surface.mouse_filter = MOUSE_FILTER_IGNORE
	var warning_style: StyleBoxFlat = game._compact_button_style()
	warning_style.bg_color = Color("2e2525",0.96)
	warning_style.border_color = Color("ae785e")
	warning_style.border_width_left = 3
	warning_style.set_content_margin_all(7)
	warning_surface.add_theme_stylebox_override("panel",warning_style)
	warning_slot.add_child(warning_surface)
	warning_row = HBoxContainer.new()
	warning_row.mouse_filter = MOUSE_FILTER_IGNORE
	warning_surface.add_child(warning_row)
	var right_gap := Control.new()
	right_gap.mouse_filter = MOUSE_FILTER_IGNORE
	right_gap.size_flags_horizontal = SIZE_EXPAND_FILL
	top_row.add_child(right_gap)
	journal_stack = VBoxContainer.new()
	journal_stack.z_index = 35
	journal_stack.custom_minimum_size.x = 302
	journal_stack.size_flags_vertical = SIZE_SHRINK_BEGIN
	journal_stack.add_theme_constant_override("separation",6)
	journal_stack.mouse_filter = MOUSE_FILTER_IGNORE
	top_row.add_child(journal_stack)
	warning_text = _label(warning_row,"",12)
	warning_text.modulate = Color("ffad87")
	warning_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning_text.clip_text = true
	warning_text.mouse_filter = MOUSE_FILTER_IGNORE
	warning_progress = ProgressBar.new()
	warning_progress.custom_minimum_size = Vector2(92,6)
	warning_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	warning_progress.show_percentage = false
	warning_progress.max_value = 3.0
	for state in ["background","fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ff8b6d") if state == "fill" else Color("364957")
		style.set_corner_radius_all(3)
		warning_progress.add_theme_stylebox_override(state,style)
	warning_progress.mouse_filter = MOUSE_FILTER_IGNORE
	warning_row.add_child(warning_progress)
	warning_progress.hide()
	programs = HBoxContainer.new()
	programs.add_theme_constant_override("separation",8)
	hack_group.add_child(programs)
	_build_program_preview()
	selection_box = HBoxContainer.new()
	selection_box.position = Vector2(28,84)
	selection_box.add_theme_constant_override("separation",12)
	canvas.add_child(selection_box)
	for slot in range(Codes.MAX_LOADOUT):
		var picker := OptionButton.new()
		picker.add_theme_font_size_override("font_size",14)
		picker.add_item("空槽")
		for program in Codes.RULES.programs: picker.add_item(program.display_name)
		picker.item_selected.connect(func(index): _select_program(slot,index))
		selection_box.add_child(picker)
		selectors.append(picker)
	items = HBoxContainer.new()
	items.add_theme_constant_override("separation",8)
	item_group.add_child(items)
	items.size_flags_vertical = SIZE_SHRINK_CENTER
	item_details = Control.new()
	item_details.z_index = 40
	item_details.position = Vector2(742,380)
	item_details.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(item_details)
	for entry in Codes.RULES.items:
		var icon := Icon.new()
		icon.action_id = entry.id
		icon.toggle_mode = true
		icon.pressed.connect(func(): _select_item(entry.id))
		items.add_child(icon)
		icon.custom_minimum_size = Vector2(52,48)
		var card := _card(item_details)
		card.get_parent().custom_minimum_size.x = 250
		card.get_parent().visible = false
		_label(card,entry.display_name,15)
		var effect := preload("res://scenes/ui/glossary_text.gd").make(entry.description,12)
		card.add_child(effect)
		effect.custom_minimum_size.x = 238
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var controls := {"card":card.get_parent(),"icon":icon}
		if entry.effect == "convert":
			controls.source_preview = Chip.new()
			card.add_child(controls.source_preview)
			controls.source = _picker(card)
		if entry.effect in ["shield","revive"]:
			controls.destination = OptionButton.new()
			controls.destination.custom_minimum_size.y = 30
			controls.destination.add_theme_font_size_override("font_size",14)
			card.add_child(controls.destination)
		else:
			controls.destination_preview = Chip.new()
			card.add_child(controls.destination_preview)
			controls.destination = _picker(card)
		if entry.effect == "convert": controls.destination.select(1)
		controls.state = _label(card,"",11)
		var use_button := Button.new()
		use_button.text = "使用"
		use_button.custom_minimum_size.y = 30
		use_button.add_theme_font_size_override("font_size",14)
		use_button.pressed.connect(func(): _use_code_item(entry.id))
		card.add_child(use_button)
		controls.button = use_button
		item_controls[entry.id] = controls
	activity = preload("res://scenes/battle_demo/battle_activity.gd").new()
	activity.host = self
	canvas.add_child(activity)
	buff_button = Button.new()
	buff_button.position = Vector2(1036,16)
	buff_button.custom_minimum_size = Vector2(64,32)
	for state in ["normal","hover","pressed","focus"]:
		buff_button.add_theme_stylebox_override(state,game._compact_button_style())
	buff_button.add_theme_font_size_override("font_size",12)
	buff_button.text = "增益 0"
	canvas.add_child(buff_button)
	buff_details = preload("res://scenes/ui/glossary_text.gd").make("",12)
	buff_details.position = Vector2(908,64)
	buff_details.size = Vector2(234,220)
	buff_details.fit_content = false
	buff_details.scroll_active = true
	var buff_style := StyleBoxFlat.new()
	buff_style.bg_color = Color("132533",0.96)
	buff_style.set_content_margin_all(10)
	buff_details.add_theme_stylebox_override("normal",buff_style)
	buff_details.hide()
	buff_details.z_index = 35
	canvas.add_child(buff_details)
	buff_button.pressed.connect(func():
		buff_details.visible = not buff_details.visible
		if buff_details.visible: activity.set_expanded(false))
	code_fx = preload("res://scenes/battle_demo/code_fx.gd").new()
	code_fx.reduced_motion = GGT_GameConfig.config.get_value("game","reduced_motion",false)
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
	program_preview.custom_minimum_size.x = 280
	program_preview.z_index = 40
	program_preview.visible = false
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("132533",0.98)
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
	preview_effect = preload("res://scenes/ui/glossary_text.gd").make("",12)
	content.add_child(preview_effect)
	preview_effect.custom_minimum_size.x = 258
	preview_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_target = OptionButton.new()
	preview_target.clip_text = true
	preview_target.add_theme_font_size_override("font_size",14)
	preview_target.custom_minimum_size.y = 30
	preview_target.item_selected.connect(func(_index): _update_hud())
	content.add_child(preview_target)
	preview_payment = HBoxContainer.new()
	content.add_child(preview_payment)
	for color in Codes.RULES.types:
		var column := VBoxContainer.new()
		preview_payment.add_child(column)
		var label := _label(column, Codes.RULES.types[color].symbol, 12)
		label.modulate = Codes.RULES.types[color].color
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = Codes.RULES.cache_cap
		spin.step = 1
		spin.custom_minimum_size.x = 45
		spin.value_changed.connect(func(_value):
			if payment_editing: _update_hud())
		column.add_child(spin)
		payment_inputs[color] = spin
	preview_state = _label(content,"",11)
	preview_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_state.custom_minimum_size.x = 258
	preview_release = Button.new()
	preview_release.text = "释放"
	preview_release.custom_minimum_size.y = 30
	preview_release.add_theme_font_size_override("font_size",14)
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
	if index == 0:
		if slot >= chosen.size() or chosen.size() == 1: return
		chosen.remove_at(slot)
	else:
		var id: String = Codes.RULES.programs[index-1].id
		var other := chosen.find(id)
		if slot >= chosen.size():
			if other >= 0: return
			chosen.append(id)
		else:
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
		if is_instance_valid(buff_details): buff_details.hide()
		_hide_program_preview()
		if not selected_item.is_empty(): _select_item("")
		return
	sim = game.simulation
	if simulation_ref != sim:
		simulation_ref = sim
		for controls in program_controls.values(): controls.button.reset_readiness()
	var battle_started: bool = not running and game.phase == "battle"
	running = game.phase == "battle"
	if not running: _hide_program_preview(); warning_row.hide(); warning_surface.hide()
	if not running and not selected_item.is_empty(): _select_item("")
	var factor: float = minf(game.size.x/1280.0,game.size.y/720.0)
	canvas.scale = Vector2.ONE*factor
	canvas.position = (game.size-Vector2(1280,720)*factor)/2
	dock.visible = running
	journal_stack.visible = running
	playback.visible = running
	pause_control.text = "▶" if game.paused else "Ⅱ"
	_refresh_speed_controls()
	programs.visible = running
	items.visible = running
	item_details.visible = running
	selection_box.visible = game.phase == "prepare"
	for slot in range(selectors.size()):
		selectors[slot].select(0)
		if slot >= sim.loadout.size(): continue
		for index in range(Codes.RULES.programs.size()):
			if Codes.RULES.programs[index].id == sim.loadout[slot]: selectors[slot].select(index+1)
	var key: String = str(sim.loadout)
	if key != loadout_key:
		loadout_key = key
		for child in programs.get_children(): child.free()
		program_controls.clear()
		for id in sim.loadout:
			var data = Codes.program(id)
			var card := _card(programs)
			card.get_parent().custom_minimum_size = Vector2(138,56)
			var button = Icon.new()
			button.program_card = true
			button.action_id = id
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(128,30)
			button.pressed.connect(func(): _show_program_preview(id,true))
			card.add_child(button)
			button.custom_minimum_size = Vector2(128,30)
			var name_label := _label(button,data.display_name,12)
			name_label.position = Vector2(36,6)
			name_label.size = Vector2(58,20)
			name_label.clip_text = true
			var cost := HBoxContainer.new()
			cost.add_theme_constant_override("separation",2)
			card.add_child(cost)
			var recipe := {}
			if data.any_cost > 0:
				var any_chip := Chip.new()
				any_chip.configure("any",data.any_cost,true)
				any_chip.mouse_filter = MOUSE_FILTER_PASS
				cost.add_child(any_chip)
				recipe["any"] = any_chip
			for kind in data.cost:
				var chip := Chip.new()
				chip.configure(kind, data.cost[kind], false)
				cost.add_child(chip)
				recipe[kind] = chip
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cost.add_child(spacer)
			var state_label := _label(cost,"缺码",12)
			state_label.hide()
			state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			program_controls[id] = {"card":card.get_parent(),"button":button,"recipe":recipe,"state":state_label,"name":name_label}
			button.tooltip_text = "确认查看 · Esc关闭"
		for slot in range(sim.loadout.size(),Codes.MAX_LOADOUT):
			var empty := _card(programs)
			empty.get_parent().custom_minimum_size = Vector2(138,56)
			var hint := _label(empty,"空槽",12)
			hint.modulate = Color("738796")
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint.size_flags_vertical = SIZE_EXPAND_FILL
		var buttons: Array = program_controls.values().map(func(c): return c.button)
		for item in item_controls.values(): buttons.append(item.icon)
		for index in buttons.size():
			buttons[index].focus_next = buttons[(index+1)%buttons.size()].get_path()
			buttons[index].focus_previous = buttons[posmod(index-1,buttons.size())].get_path()
		if running and get_viewport().gui_get_focus_owner() == null: buttons[0].grab_focus()
		hud_dirty = true
	if battle_started and not program_controls.is_empty():
		program_controls.values()[0].button.grab_focus()
	_update_bonds()
	_update_absorption_cycle()
	_sync_program_preview()
	# Discrete simulation events refresh immediately; only countdowns need a 10 Hz clock.
	if hud_dirty or absf(sim.elapsed-hud_time) >= 0.1 or hud_pause != game.paused or hud_hover_pause != hover_paused():
		_update_hud()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not running: return
	if event is InputEventMouse and _guide_owns_pointer(event.position):
		pointer = Vector2(-10000,-10000)
		return
	if event.is_action_pressed("ui_cancel") and buff_details.visible:
		buff_details.hide()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and (program_preview.visible or not selected_item.is_empty()):
		if program_preview.visible: _hide_program_preview()
		if not selected_item.is_empty(): _select_item("")
		pointer = Vector2(-10000,-10000)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouse:
		pointer = event.position
		if event is InputEventMouseButton and event.pressed and preview_pinned and not _pointer_on_program_area(pointer):
			_hide_program_preview()
		if event is InputEventMouseButton and event.pressed and not selected_item.is_empty():
			var selected: Dictionary = item_controls[selected_item]
			if not selected.card.get_global_rect().has_point(pointer) and not selected.icon.get_global_rect().has_point(pointer): _select_item("")
	elif event is InputEventScreenTouch and event.pressed:
		if not running: return
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
	if not running or not program_controls.has(id): return
	if not selected_item.is_empty(): _select_item("")
	preview_program_id = id
	preview_pinned = pin
	program_preview.visible = true
	hud_dirty = true
	var data = Codes.program(id)
	preview_title.text = data.display_name
	var effect_copy: String = data.description
	if effect_copy.begins_with("消耗") and effect_copy.contains("，"):
		effect_copy = effect_copy.substr(effect_copy.find("，")+1)
	preview_effect.set_copy(effect_copy)
	target_key = ""
	payment_editing = false
	var payment: Dictionary = sim.payment_for(id)
	for color in payment_inputs: payment_inputs[color].value = payment.get(color, 0)
	payment_editing = true
	for program_id in program_controls:
		program_controls[program_id].button.button_pressed = program_id == id
	_position_program_preview()
	_update_hud()
	if pin:
		if preview_target.visible and preview_target.item_count > 0: preview_target.grab_focus()
		elif not preview_release.disabled: preview_release.grab_focus()

func _hide_program_preview() -> void:
	if preview_program_id.is_empty(): return
	var focused := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused) and program_preview.is_ancestor_of(focused) and program_controls.has(preview_program_id):
		program_controls[preview_program_id].button.grab_focus()
	preview_program_id = ""
	preview_pinned = false
	program_preview.visible = false
	hud_dirty = true
	for controls in program_controls.values(): controls.button.button_pressed = false

func _sync_program_preview() -> void:
	if preview_effect.pinned: return
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
	program_preview.reset_size()
	program_preview.size.x = maxf(280,program_preview.get_combined_minimum_size().x)
	var card: Control = program_controls[preview_program_id].card
	var anchor: Vector2 = canvas.get_global_transform().affine_inverse()*card.global_position
	var x: float = anchor.x
	var preview_height := maxf(program_preview.size.y,program_preview.get_combined_minimum_size().y)
	program_preview.position = Vector2(clampf(x,30,1230-program_preview.size.x),maxf(128,anchor.y-preview_height-4))

func _select_item(id: String) -> void:
	if not id.is_empty() and not running: return
	if not id.is_empty(): _hide_program_preview()
	var previous := selected_item
	selected_item = "" if id == selected_item else id
	if selected_item.is_empty() and item_controls.has(previous):
		var focused := get_viewport().gui_get_focus_owner()
		if is_instance_valid(focused) and item_controls[previous].card.is_ancestor_of(focused): item_controls[previous].icon.grab_focus()
	for item_id in item_controls:
		item_controls[item_id].card.visible = item_id == selected_item
		item_controls[item_id].icon.button_pressed = item_id == selected_item
	_update_hud()
	if not selected_item.is_empty():
		var destination_control: Control = item_controls[selected_item].destination
		if destination_control is OptionButton: destination_control.grab_focus()
		else: destination_control.get_child(0).grab_focus()

func hover_paused() -> bool:
	if is_visible_in_tree() and ((is_instance_valid(activity) and activity.expanded) or (is_instance_valid(buff_details) and buff_details.visible)): return true
	if is_instance_valid(preview_effect) and preview_effect.pinned: return true
	if not is_visible_in_tree() or game.phase != "battle" or game.get("screen") not in [null,"battle"]: return false
	if bond_panel.get_global_rect().has_point(pointer): return true
	for entry in bond_rows.values():
		if entry.pinned: return true
	if is_instance_valid(game.battle_status_layer) and game.battle_status_layer.hover_paused(): return true
	if (preview_pinned and program_preview.visible) or not selected_item.is_empty(): return true
	for controls in program_controls.values():
		if controls.card.is_visible_in_tree() and controls.card.get_global_rect().has_point(pointer): return true
	if program_preview.visible and program_preview.get_global_rect().has_point(pointer): return true
	for controls in item_controls.values():
		if controls.icon.is_visible_in_tree() and controls.icon.get_global_rect().has_point(pointer): return true
		if controls.card.is_visible_in_tree() and controls.card.get_global_rect().has_point(pointer): return true
	return false

func _update_hud() -> void:
	hud_dirty = false
	hud_time = sim.elapsed
	hud_pause = game.paused
	hud_hover_pause = hover_paused()
	var warnings: Array = sim.warnings.keys().filter(func(id): return sim.unit(id).hp > 0)
	warnings.sort_custom(func(a,b): return sim.warnings[a].fire_at < sim.warnings[b].fire_at)
	warning_row.visible = running and not warnings.is_empty()
	warning_surface.visible = warning_row.visible
	if warning_row.visible:
		var id: int = warnings[0]
		var remaining: float = maxf(0,sim.warnings[id].fire_at-sim.elapsed)
		warning_text.text = "%s · %s · %.1f秒" % [sim.unit(id).name,sim.warnings[id].label,remaining]
		warning_progress.value = remaining
	for kind in bank_labels:
		bank_labels[kind].absorbed = sim.absorbed
		bank_labels[kind].reduced_motion = code_fx.reduced_motion
		bank_labels[kind].configure(kind,sim.blocks.get(kind,0),Codes.RULES.cache_cap)
	for id in program_controls:
		var controls: Dictionary = program_controls[id]
		var error: String = sim.program_error(id)
		controls.button.disabled = false
		controls.button.set_readiness(error.is_empty(), code_fx.reduced_motion)
		var resources: Dictionary = sim.payment_for(id)
		var missing: bool = false
		var paid_total := 0
		for kind in resources:
			paid_total += resources[kind]
			if sim.blocks.get(kind,0) < resources[kind]: missing = true
		if Codes.program(id).any_cost > paid_total: missing = true
		controls.state.text = "" if error.is_empty() else "缺码" if missing else "冷却中" if error.contains("冷却") else "次数用尽" if error.contains("次数") else "待目标"
		controls.button.state_code = "ready" if error.is_empty() else "cooldown" if error.contains("冷却") else "spent" if error.contains("次数") else "missing" if missing else "target"
		controls.name.modulate = Color.WHITE if error.is_empty() else Color("89949f")
		controls.button.cooldown_duration = maxf(Codes.program(id).cooldown,Codes.RULES.shared_cooldown)
		controls.button.cooldown_left = maxf(0,maxf(sim.ready_at,sim.program_ready.get(id,0.0))-sim.elapsed)
		controls.state.modulate = Color("76e5cb") if error.is_empty() else Color("ffbf66") if missing else Color("b6c6d3")
		controls.button.tooltip_text = "点击确认释放" if error.is_empty() else error
		for kind in controls.recipe:
			controls.recipe[kind].stock = paid_total if kind == "any" else int(sim.blocks.get(kind,0))
			controls.recipe[kind].configure("any",Codes.program(id).any_cost,not missing) if kind == "any" else controls.recipe[kind].configure(kind, Codes.program(id).cost[kind], sim.blocks.get(kind,0) >= Codes.program(id).cost[kind])
	if not preview_program_id.is_empty():
		var data = Codes.program(preview_program_id)
		var targets: Array[Dictionary] = sim.program_targets(preview_program_id)
		preview_target.visible = data.effect in ["pursuit","repair"]
		var key := str(targets.map(func(u): return u.id))
		if key != target_key:
			var old_id := preview_target.get_selected_id()
			preview_target.clear()
			var default_index := 0
			for u in targets:
				preview_target.add_item("%s · %d生命 / %d盾" % [u.name, int(u.hp), int(u.shield)], u.id)
				if u.id == old_id: default_index = preview_target.item_count - 1
			if preview_target.item_count > 0: preview_target.select(default_index)
			preview_target.disabled = targets.is_empty()
			if targets.is_empty(): preview_target.text = "暂无目标"
			target_key = key
		for index in targets.size():
			var u: Dictionary = targets[index]
			preview_target.set_item_text(index,"%s · %d生命 / %d盾" % [u.name,int(u.hp),int(u.shield)])
		preview_payment.visible = data.any_cost > 0
		var payment: Dictionary = _selected_payment() if data.any_cost > 0 else {}
		var preview_error: String = sim.program_error(preview_program_id, _selected_target(), payment)
		preview_state.text = preview_error
		preview_release.disabled = not preview_error.is_empty() or game.paused
		if game.paused: preview_state.text = "继续战斗后可释放"
		preview_state.visible = not preview_state.text.is_empty()
	for id in item_controls:
		var controls: Dictionary = item_controls[id]
		if Codes.item(id).effect in ["shield","revive"]:
			var targets: Array = sim.units.filter(func(u): return u.side == 0 and ((u.hp <= 0) if id == "revive" else (u.hp > 0)))
			var old: int = controls.destination.get_selected_id()
			controls.destination.clear()
			for target in targets:
				controls.destination.add_item(target.name,target.id)
				if target.id == old: controls.destination.select(controls.destination.item_count-1)
		var destination := _item_destination(id)
		var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
		var error: String = sim.item_error(id,destination,source)
		if controls.has("source_preview"):
			controls.source_preview.configure(source, 2, sim.blocks.get(source,0) >= 2, "−")
		if controls.has("destination_preview"):
			controls.destination_preview.configure(destination, Codes.item(id).amount, sim.blocks.get(destination,0) + Codes.item(id).amount <= Codes.RULES.cache_cap, "+")
		controls.button.disabled = not error.is_empty() or game.paused
		controls.state.text = "暂停中可查看，继续战斗后使用" if game.paused else "就绪" if error.is_empty() else error
		controls.icon.available = sim.items.get(id,0) > 0
		controls.icon.remaining = sim.items.get(id,0)
		controls.icon.tooltip_text = Codes.item(id).display_name+" · 点击查看"
		controls.icon.queue_redraw()
	clock.text = "%02d:%02d" % [int(sim.elapsed)/60,int(sim.elapsed)%60]
	summary.text = "已暂停" if game.paused else "查看中" if hover_paused() else "进行中"
	summary.tooltip_text = "查看中 · 战斗暂停" if hover_paused() and not game.paused else summary.text
	summary.modulate = Color("e9c183") if game.paused else Color("82dfcc") if hover_paused() else Color("a4b5bf")

func _update_bonds() -> void:
	var counts := {}
	for unit in sim.units:
		if unit.side != 0: continue
		for tag in unit.get("tags",[]): counts[tag] = counts.get(tag,0)+1
	var key := str(counts)+str(sim.tag_ids)+str(sim.upgrades)+str(game.formation)
	if key == bond_key: return
	bond_key = key
	for definition in preload("res://game/combat/combat_content_catalog.gd").MANIFEST.synergies:
		var count: int = counts.get(definition.id,0)
		var activated: bool = sim.tag_ids.has(definition.id)
		bond_rows[definition.id].set_copy(definition.display_name)
		var members: HBoxContainer = bond_members[definition.id]
		for child in members.get_children(): child.free()
		for unit in sim.units:
			if unit.side != 0 or not unit.get("tags",[]).has(definition.id): continue
			var portrait := TextureRect.new()
			portrait.texture = unit.portrait
			portrait.custom_minimum_size = Vector2(22,22)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.tooltip_text = unit.name
			members.add_child(portrait)
		bond_counts[definition.id].text = "%d/%d" % [count,definition.required_count]
		bond_counts[definition.id].modulate.a = 1.0 if activated else 0.48
		bond_rows[definition.id].modulate.a = 1.0 if activated else 0.48

	var descriptions: Array[String] = []
	for id in sim.upgrades:
		var reward = preload("res://game/combat/combat_content_catalog.gd").reward(id)
		if reward != null and reward.category in ["羁绊","程序"]:
			descriptions.append(reward.display_name+"\n"+reward.description)
	buff_button.text = "增益 %d" % descriptions.size()
	buff_button.visible = not descriptions.is_empty()
	buff_details.set_copy("\n\n".join(descriptions) if not descriptions.is_empty() else "暂无队伍常驻增益")

func code_origin(event: Dictionary) -> Vector2:
	return game.origin+(game._project(event.from)-Vector2(0,35))*game.scale_factor
func consume(event: Dictionary) -> void:
	hud_dirty = true
	if event.get("kind","") == "code_generated" and event.get("actual",0) > 0 and bank_labels.has(event.get("code_type","")):
		bank_labels[event.code_type].celebrate()
	if is_instance_valid(code_fx): code_fx.consume(event)
	if is_instance_valid(activity): activity.consume(event)
func _consume_pending() -> void:
	for event in sim.drain_events(): game._present_simulation_event(event)
func _cast_code(id: String) -> void:
	if not running or game.paused or not program_preview.visible or preview_program_id != id or not sim.cast_program(id, _selected_target(), _selected_payment() if Codes.program(id).any_cost > 0 else {}): return
	_consume_pending()
	_hide_program_preview()
	_update_hud()
func _use_code_item(id: String) -> void:
	if not running or game.paused or selected_item != id: return
	var controls: Dictionary = item_controls[id]
	var destination := _item_destination(id)
	var source: String = Codes.RULES.types.keys()[controls.source.selected] if controls.has("source") else ""
	if sim.use_item(id,destination,source):
		_consume_pending()
		_select_item("")
	_update_hud()

func _item_destination(id: String) -> String:
	var picker = item_controls[id].destination
	if Codes.item(id).effect in ["shield","revive"]:
		return str(picker.get_selected_id()) if picker.item_count > 0 else ""
	return str(Codes.RULES.types.keys()[picker.selected])
func feedback_frozen() -> bool:
	return game.paused or hover_paused()


func _selected_target() -> int:
	return preview_target.get_selected_id() if preview_target.visible and preview_target.item_count > 0 else -1

func _selected_payment() -> Dictionary:
	var result := {}
	for color in payment_inputs:
		if payment_inputs[color].value > 0: result[color] = int(payment_inputs[color].value)
	return result

func _update_absorption_cycle() -> void:
	if not bank_labels.has("purple"): return
	var ratio := -1.0
	for cycle in sim.pending_code_cycles:
		if cycle.code_type != "purple": continue
		var value := clampf((float(cycle.ready_at)-sim.elapsed)/sim.CODE_CYCLE_DURATION,0,1)
		ratio = maxf(ratio,value)
	if ratio >= 0 and code_fx.reduced_motion: ratio = 1.0
	bank_labels.purple.cycle_ratio = ratio
	bank_labels.purple.queue_redraw()


func _guide_owns_pointer(at: Vector2) -> bool:
	var guide = game.get("tutorial_guide")
	return is_instance_valid(guide) and guide.is_visible_in_tree() and guide.card.get_global_rect().has_point(at)

func owns_pointer(at: Vector2) -> bool:
	if is_visible_in_tree() and is_instance_valid(activity) and activity.owns_pointer(at): return true
	if is_visible_in_tree() and is_instance_valid(buff_button) and (buff_button.get_global_rect().has_point(at) or (buff_details.visible and buff_details.get_global_rect().has_point(at))): return true
	if _guide_owns_pointer(at): return true
	if not is_visible_in_tree() or not running: return false
	if bond_panel.is_visible_in_tree() and bond_panel.get_global_rect().has_point(at): return true
	if _pointer_on_program_area(at): return true
	for controls in item_controls.values():
		for key in ["icon","card"]:
			var control: Control = controls[key]
			if control.is_visible_in_tree() and control.get_global_rect().has_point(at): return true
	return false

func _dock_group(parent: HBoxContainer, title: String, tint: Color) -> VBoxContainer:
	var group := VBoxContainer.new()
	group.mouse_filter = MOUSE_FILTER_IGNORE
	group.add_theme_constant_override("separation",3)
	parent.add_child(group)
	var label := _label(group,title,10)
	label.modulate = tint
	return group

func _playback_button(parent: Control, title: String, tint: Color) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(64,28)
	button.add_theme_font_size_override("font_size",15)
	button.add_theme_color_override("font_color",Color("10232d"))
	button.add_theme_color_override("font_hover_color",Color("10232d"))
	for state in ["normal","hover","pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = tint if state == "normal" else tint.lightened(0.16) if state == "hover" else tint.darkened(0.16)
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state,style)
	parent.add_child(button)
	return button

func preview_recipients() -> Array[Dictionary]:
	if not program_preview.visible or preview_program_id.is_empty(): return []
	var definition = Codes.program(preview_program_id)
	if definition.effect == "recoil": return sim.program_targets(preview_program_id)
	var selected: Dictionary = sim.unit(_selected_target())
	if selected.is_empty() or selected.hp <= 0: return []
	return [selected]

func _speed_button(caption: String, direction: int) -> Button:
	var button := _playback_button(speed_control,caption,Color("e9c183"))
	button.custom_minimum_size = Vector2(18,24)
	button.add_theme_font_size_override("font_size",13)
	button.tooltip_text = "减慢速度" if direction < 0 else "加快速度"
	for state in ["normal","hover","pressed","disabled"]:
		var skin := button.get_theme_stylebox("normal" if state == "disabled" else state).duplicate() as StyleBoxFlat
		skin.corner_radius_top_right = 0 if direction < 0 else 5
		skin.corner_radius_bottom_right = 0 if direction < 0 else 5
		skin.corner_radius_top_left = 5 if direction < 0 else 0
		skin.corner_radius_bottom_left = 5 if direction < 0 else 0
		if state == "disabled": skin.bg_color = Color("b4a282")
		button.add_theme_stylebox_override(state,skin)
	button.pressed.connect(func(): _change_speed(direction))
	return button

func _change_speed(direction: int) -> void:
	var index: int = game.PLAYBACK_SPEEDS.find(game.speed)
	game.speed = game.PLAYBACK_SPEEDS[clampi(index+direction,0,game.PLAYBACK_SPEEDS.size()-1)]
	_refresh_speed_controls()
	game.queue_redraw()

func _refresh_speed_controls() -> void:
	speed_value.text = "%.1f×" % game.speed
	var index: int = game.PLAYBACK_SPEEDS.find(game.speed)
	speed_down.disabled = index <= 0
	speed_up.disabled = index >= game.PLAYBACK_SPEEDS.size()-1
