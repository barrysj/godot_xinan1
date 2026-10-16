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
var items: VBoxContainer
var item_details: Control
var selected_item := ""
var summary: Label
var selectors: Array[OptionButton] = []
var selection_box: HBoxContainer
var loadout_key := ""
var pointer := Vector2(-10000,-10000)
var hud_dirty := true
var hud_time := -1.0
var hud_pause := false
var hud_hover_pause := false
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
	var back := ColorRect.new()
	back.color = Color("172332",0.96)
	back.position = Vector2(28,80)
	back.size = Vector2(1208,40)
	back.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(back)
	var bank := HBoxContainer.new()
	bank.position = Vector2(38,84)
	bank.add_theme_constant_override("separation",8)
	canvas.add_child(bank)
	for kind in Codes.RULES.types:
		var sockets := Sockets.new()
		sockets.compact = true
		sockets.kind = kind
		sockets.custom_minimum_size = Vector2(216 if kind == "purple" else 128,32)
		bank.add_child(sockets)
		bank_labels[kind] = sockets
	summary = _label(canvas,"",12)
	summary.position = Vector2(676,91)
	summary.size = Vector2(548,18)
	summary.clip_text = true
	summary.add_theme_font_size_override("font_size",11)
	warning_row = HBoxContainer.new()
	canvas.add_child(warning_row)
	warning_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	warning_row.position = Vector2(42,652)
	warning_row.size = Vector2(320,22)
	warning_row.mouse_filter = MOUSE_FILTER_IGNORE
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
	programs.position = Vector2(400,624)
	programs.add_theme_constant_override("separation",12)
	canvas.add_child(programs)
	_build_program_preview()
	selection_box = HBoxContainer.new()
	selection_box.position = Vector2(400,637)
	selection_box.add_theme_constant_override("separation",12)
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
	item_details.z_index = 40
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
		var effect := preload("res://scenes/ui/glossary_text.gd").make(entry.description,12)
		card.add_child(effect)
		effect.custom_minimum_size.x = 170
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var controls := {"card":card.get_parent(),"icon":icon}
		if entry.effect == "convert":
			controls.source_preview = Chip.new()
			card.add_child(controls.source_preview)
			controls.source = _picker(card)
		if entry.effect in ["shield","revive"]:
			controls.destination = OptionButton.new()
			controls.destination.custom_minimum_size.y = 36
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
		use_button.custom_minimum_size.y = 34
		use_button.pressed.connect(func(): _use_code_item(entry.id))
		card.add_child(use_button)
		controls.button = use_button
		item_controls[entry.id] = controls
	var motion := CheckButton.new()
	motion.text = "简化特效"
	motion.add_theme_font_size_override("font_size",12)
	motion.position = Vector2(1090,125)
	motion.set_pressed_no_signal(GGT_GameConfig.config.get_value("game","reduced_motion",false))
	motion.toggled.connect(func(value):
		code_fx.reduced_motion = value
		GGT_GameConfig.config.set_value("game","reduced_motion",value)
		GGT_GameConfig.persist())
	canvas.add_child(motion)
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
	program_preview.custom_minimum_size.x = 218
	program_preview.z_index = 40
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
	preview_effect = preload("res://scenes/ui/glossary_text.gd").make("",12)
	content.add_child(preview_effect)
	preview_effect.custom_minimum_size.x = 196
	preview_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_target = OptionButton.new()
	preview_target.clip_text = true
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
	if simulation_ref != sim:
		simulation_ref = sim
		for controls in program_controls.values(): controls.button.reset_readiness()
	var battle_started: bool = not running and game.phase == "battle"
	running = game.phase == "battle"
	if not running: _hide_program_preview(); warning_row.hide()
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
			card.get_parent().custom_minimum_size = Vector2(224,80)
			var button = Icon.new()
			button.program_card = true
			button.action_id = id
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(214,44)
			button.pressed.connect(func(): _show_program_preview(id,true))
			card.add_child(button)
			button.custom_minimum_size = Vector2(214,44)
			var name_label := _label(button,data.display_name,18)
			name_label.position = Vector2(12,10)
			var cost := HBoxContainer.new()
			cost.add_theme_constant_override("separation",8)
			card.add_child(cost)
			var recipe := {}
			if data.any_cost > 0: _label(cost, "任意%d块" % data.any_cost, 12)
			for kind in data.cost:
				var chip := Chip.new()
				chip.configure(kind, data.cost[kind], false)
				cost.add_child(chip)
				recipe[kind] = chip
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cost.add_child(spacer)
			var state_label := _label(cost,"缺码",12)
			state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			program_controls[id] = {"card":card.get_parent(),"button":button,"recipe":recipe,"state":state_label}
			button.tooltip_text = "确认查看 · Esc关闭"
		var buttons: Array = program_controls.values().map(func(c): return c.button)
		for item in item_controls.values(): buttons.append(item.icon)
		for index in buttons.size():
			buttons[index].focus_next = buttons[(index+1)%buttons.size()].get_path()
			buttons[index].focus_previous = buttons[posmod(index-1,buttons.size())].get_path()
		if running and get_viewport().gui_get_focus_owner() == null: buttons[0].grab_focus()
		hud_dirty = true
	if battle_started and not program_controls.is_empty():
		program_controls.values()[0].button.grab_focus()
	_update_absorption_cycle()
	_sync_program_preview()
	# Discrete simulation events refresh immediately; only countdowns need a 10 Hz clock.
	if hud_dirty or absf(sim.elapsed-hud_time) >= 0.1 or hud_pause != game.paused or hud_hover_pause != hover_paused():
		_update_hud()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not running or game.paused: return
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
	if not selected_item.is_empty(): _select_item("")
	preview_program_id = id
	preview_pinned = pin
	program_preview.visible = true
	hud_dirty = true
	var data = Codes.program(id)
	preview_title.text = data.display_name
	preview_effect.set_copy(data.description)
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
	var x: float = programs.position.x + card.position.x
	var preview_height := maxf(program_preview.size.y,program_preview.get_combined_minimum_size().y)
	program_preview.position = Vector2(clampf(x,30,1230-program_preview.size.x),maxf(128,programs.position.y-preview_height+1))

func _select_item(id: String) -> void:
	if not id.is_empty() and (not running or game.paused): return
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
	if is_instance_valid(preview_effect) and preview_effect.pinned: return true
	if not is_visible_in_tree() or game.phase != "battle" or game.get("screen") not in [null,"battle"]: return false
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
		controls.button.disabled = game.paused
		controls.button.set_readiness(error.is_empty(), code_fx.reduced_motion)
		var resources: Dictionary = sim.payment_for(id)
		var missing: bool = false
		var paid_total := 0
		for kind in resources:
			paid_total += resources[kind]
			if sim.blocks.get(kind,0) < resources[kind]: missing = true
		if Codes.program(id).any_cost > paid_total: missing = true
		controls.state.text = "确认释放" if preview_pinned and preview_program_id == id and error.is_empty() else "可释放" if error.is_empty() else "缺码" if missing else "冷却中" if error.contains("冷却") else "次数用尽" if error.contains("次数") else "待目标"
		controls.state.modulate = Color("76e5cb") if error.is_empty() else Color("ffbf66") if missing else Color("b6c6d3")
		controls.button.tooltip_text = "点击确认释放" if error.is_empty() else error
		for kind in controls.recipe:
			controls.recipe[kind].configure(kind, Codes.program(id).cost[kind], sim.blocks.get(kind,0) >= Codes.program(id).cost[kind])
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
			target_key = key
		for index in targets.size():
			var u: Dictionary = targets[index]
			preview_target.set_item_text(index,"%s · %d生命 / %d盾" % [u.name,int(u.hp),int(u.shield)])
		preview_payment.visible = data.any_cost > 0
		var payment: Dictionary = _selected_payment() if data.any_cost > 0 else {}
		var preview_error: String = sim.program_error(preview_program_id, _selected_target(), payment)
		preview_state.text = "选择目标后确认释放" if preview_error.is_empty() and preview_target.visible else "确认后消耗所示代码" if preview_error.is_empty() else preview_error
		preview_release.disabled = not preview_error.is_empty() or game.paused
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
		controls.state.text = "就绪" if error.is_empty() else error
		controls.icon.available = sim.items.get(id,0) > 0
		controls.icon.remaining = sim.items.get(id,0)
		controls.icon.tooltip_text = Codes.item(id).display_name+" · 点击查看"
		controls.icon.queue_redraw()
	summary.text = (("操作暂停  ·  " if preview_pinned or not selected_item.is_empty() else "悬停暂停  ·  ") if hover_paused() and not game.paused else "")+"羁绊："+("、".join(sim.tags) if not sim.tags.is_empty() else "未激活")+"  ·  "+sim.system_status()

func code_origin(event: Dictionary) -> Vector2:
	return game.origin+(game._project(event.from)-Vector2(0,35))*game.scale_factor
func consume(event: Dictionary) -> void:
	hud_dirty = true
	if event.get("kind","") == "code_generated" and event.get("actual",0) > 0 and bank_labels.has(event.get("code_type","")):
		bank_labels[event.code_type].celebrate()
	if is_instance_valid(code_fx): code_fx.consume(event)
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


func owns_pointer(at: Vector2) -> bool:
	if not is_visible_in_tree() or not running: return false
	if _pointer_on_program_area(at): return true
	for controls in item_controls.values():
		for key in ["icon","card"]:
			var control: Control = controls[key]
			if control.is_visible_in_tree() and control.get_global_rect().has_point(at): return true
	return false
