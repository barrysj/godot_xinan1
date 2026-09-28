extends Control
signal closed
signal region_picked(region: String)
const Map = preload("res://scenes/expedition/expanded_campus_map.gd")
var board: Control
var campaign_selectable = false
var route_buttons: Array[Button] = []
var state_buttons: Array[Button] = []
var zoom_in_button: Button
var zoom_out_button: Button
var zoom_reset_button: Button
var zoom_label: Label
var select_button: Button
var explore_button: Button
var back_button: Button
var close_button: Button
var action_panel: PanelContainer
var controls_panel: PanelContainer
var focused_route = -1
var check_runner: RefCounted
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).daily

func _ready() -> void:
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	board = Map.new()
	add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.hover_overrides_selection = false
	board.changed.connect(_refresh)
	board.place_picked.connect(_inspect)
	controls_panel = _panel(self)
	controls_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	controls_panel.offset_left = -298
	controls_panel.offset_right = -18
	controls_panel.offset_top = 18
	var controls = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 7)
	controls_panel.add_child(controls)
	_label(controls, "路线", 22)
	for index in range(board.layout.ROUTES.size()):
		var button = _button(controls, board.layout.ROUTES[index].title)
		button.toggle_mode = true
		button.pressed.connect(func(): _choose_route(index))
		button.mouse_entered.connect(func(): board.preview(index))
		button.mouse_exited.connect(func(): board.preview(-1))
		route_buttons.append(button)
	var states = HBoxContainer.new()
	controls.add_child(states)
	for state in ["day", "night", "anomaly"]:
		var button = _button(states, {"day":"日间", "night":"夜间", "anomaly":"异常"}[state])
		button.toggle_mode = true
		button.pressed.connect(func(): board.set_state(state))
		state_buttons.append(button)
	var zoom_controls = HBoxContainer.new()
	controls.add_child(zoom_controls)
	zoom_out_button = _button(zoom_controls, "缩小")
	zoom_in_button = _button(zoom_controls, "放大")
	zoom_reset_button = _button(zoom_controls, "复位")
	zoom_out_button.pressed.connect(func(): board.set_zoom(board.zoom / board.ZOOM_STEP))
	zoom_in_button.pressed.connect(func(): board.set_zoom(board.zoom * board.ZOOM_STEP))
	zoom_reset_button.pressed.connect(board.reset_view)
	zoom_label = _label(controls, "", 17)
	close_button = _button(controls, "关闭")
	close_button.pressed.connect(_close)
	action_panel = _panel(self)
	action_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	action_panel.offset_left = -146
	action_panel.offset_right = 146
	action_panel.offset_top = -88
	action_panel.offset_bottom = -18
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	action_panel.add_child(actions)
	select_button = _button(actions, "选择")
	select_button.pressed.connect(_focus_selected)
	explore_button = _button(actions, "探索")
	explore_button.pressed.connect(_explore)
	back_button = _button(actions, "返回")
	back_button.pressed.connect(_back)
	_refresh()
	if "--expanded-map-check" in OS.get_cmdline_user_args():
		check_runner = load("res://scenes/expedition/expanded_campus_preview_check.gd").new()
		check_runner.run(self)

func _panel(parent: Node) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("0c1b2bdc")
	style.border_color = Color("75b7c7a8")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _label(parent: Node, value: String, pixels: int) -> Label:
	var label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", Color("e8f4f8"))
	parent.add_child(label)
	return label

func _button(parent: Node, value: String) -> Button:
	var button = Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(72, 40)
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("276078" if state in ["hover", "pressed"] else "1a364dcf")
		style.border_color = Color("81d8e7" if state != "normal" else "678b9c")
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("f0fbff"))
	parent.add_child(button)
	return button

func _choose_route(index: int) -> void:
	if focused_route >= 0: _back()
	board.select_route(index)

func _refresh() -> void:
	if zoom_label == null: return
	zoom_label.text = "视野 %d%%" % roundi(board.zoom * 100.0)
	zoom_out_button.disabled = board.zoom <= board.MIN_ZOOM + 0.001
	zoom_in_button.disabled = board.zoom >= board.MAX_ZOOM - 0.001
	for index in range(route_buttons.size()):
		route_buttons[index].set_pressed_no_signal(board.selected_route == index)
	for index in range(state_buttons.size()):
		state_buttons[index].set_pressed_no_signal(board.map_state == ["day", "night", "anomaly"][index])
	action_panel.visible = board.selected_route >= 0
	select_button.visible = focused_route < 0
	explore_button.visible = focused_route >= 0
	explore_button.disabled = not campaign_selectable
	explore_button.tooltip_text = "请从战役首页打开地图" if not campaign_selectable else ""
	back_button.visible = focused_route >= 0
	controls_panel.visible = focused_route < 0

func _focus_selected() -> void:
	if board.selected_route < 0: return
	focused_route = board.selected_route
	board.selection_enabled = false
	board.focus_route(focused_route)
	_refresh()

func _back() -> void:
	focused_route = -1
	board.selection_enabled = true
	board.reset_view()
	board.select_route(-1)
	_refresh()

func campaign_region_for_route(index: int) -> String:
	return str(board.layout.ROUTES[index].campaign_region) if index >= 0 and index < board.layout.ROUTES.size() else ""

func _explore() -> void:
	if focused_route < 0: return
	var region = campaign_region_for_route(focused_route)
	if campaign_selectable and not region.is_empty(): region_picked.emit(region)

func _inspect(_id: String) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if focused_route >= 0: _back()
		else: _close()

func _close() -> void:
	closed.emit()
