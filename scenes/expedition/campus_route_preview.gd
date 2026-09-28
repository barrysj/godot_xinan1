extends PanelContainer
signal closed
const Map = preload("res://scenes/expedition/campus_route_map.gd")
const Walk = preload("res://game/run/campus_route_walk.gd")
var walk = Walk.new()
var inspected = ""
var previous_selection = -1
var place_box: VBoxContainer
var place_detail: Label
var picture: TextureRect
var primary: Button
var secondary: Button
var place_buttons: Array[Button] = []
var board: Control
var detail: Label
var route_buttons: Array[Button] = []
var state_buttons: Array[Button] = []
var check_runner: RefCounted
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).daily

func _ready() -> void:
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	var surface = StyleBoxFlat.new()
	surface.bg_color = Color(palette.background)
	surface.set_content_margin_all(28)
	add_theme_stylebox_override("panel", surface)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	_label(column, "核心校园 · 路线预览", 30)
	_label(column, "悬停选路 · 点击地标查看详情 · 开始预览后按顺序前往三站，不改变战役进度", 20)
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	body.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(body)
	board = Map.new()
	board.size_flags_horizontal = SIZE_EXPAND_FILL
	board.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(board)
	board.changed.connect(_refresh)
	board.place_picked.connect(_inspect)
	var sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 360
	sidebar.add_theme_constant_override("separation", 12)
	body.add_child(sidebar)
	_label(sidebar, "选择路线", 26)
	for index in range(Map.Geometry.ROUTES.size()):
		var route = Map.Geometry.ROUTES[index]
		var button = _button(sidebar, route.title)
		button.toggle_mode = true
		button.pressed.connect(func(): board.select_route(index))
		button.mouse_entered.connect(func(): board.preview(index))
		button.mouse_exited.connect(func(): board.preview(-1))
		route_buttons.append(button)
	detail = _label(sidebar, "", 21)
	detail.custom_minimum_size.y = 96
	place_box = VBoxContainer.new()
	place_box.add_theme_constant_override("separation", 10)
	sidebar.add_child(place_box)
	var places_row = HBoxContainer.new()
	places_row.add_theme_constant_override("separation", 6)
	place_box.add_child(places_row)
	for index in range(3):
		var button = _button(places_row, "地点")
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(func():
			if board.selected_route >= 0: _inspect(Map.Geometry.ROUTES[board.selected_route].places[index]))
		place_buttons.append(button)
	var preview_row = HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 12)
	place_box.add_child(preview_row)
	picture = TextureRect.new()
	picture.custom_minimum_size = Vector2(120,100)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_row.add_child(picture)
	place_detail = _label(preview_row, "", 19)
	place_detail.size_flags_horizontal = SIZE_EXPAND_FILL
	primary = _button(sidebar, "开始预览")
	primary.pressed.connect(_advance)
	secondary = _button(sidebar, "清除选择")
	secondary.pressed.connect(_reset)
	_label(sidebar, "地图状态", 24)
	var states = HBoxContainer.new()
	states.add_theme_constant_override("separation", 10)
	sidebar.add_child(states)
	for state in ["day", "night", "anomaly"]:
		var button = _button(states, {"day":"日间", "night":"夜间", "anomaly":"异常"}[state])
		button.toggle_mode = true
		button.pressed.connect(func(): board.set_state(state); _refresh())
		state_buttons.append(button)
	_label(sidebar, "亮起范围包含沿线建筑、道路与绿地。柔边表示探索范围，并非精确步行边界。", 18)
	var spacer = Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	sidebar.add_child(spacer)
	_button(sidebar, "全图").pressed.connect(_open_expanded)
	_button(sidebar, "返回").pressed.connect(_close)
	_refresh()
	route_buttons[0].grab_focus()
	if "--route-preview-check" in OS.get_cmdline_user_args():
		check_runner = load("res://scenes/expedition/campus_route_preview_check.gd").new()
		check_runner.run(self)

func _label(parent: Node, value: String, pixels: int) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", Color(palette.text_primary))
	parent.add_child(label)
	return label

func _button(parent: Node, value: String) -> Button:
	var button = Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(100, 48)
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(palette.surface_blue if state in ["hover", "pressed"] else palette.surface)
		if state == "focus": style.bg_color = Color(0,0,0,0)
		style.border_color = Color(palette.accent_primary if state != "normal" else palette.text_secondary)
		style.set_border_width_all(3 if state == "focus" else 2)
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color(palette.text_primary))
	button.add_theme_color_override("font_disabled_color", Color(palette.text_secondary))
	parent.add_child(button)
	return button

func _refresh() -> void:
	if primary == null: return
	if previous_selection != board.selected_route:
		previous_selection = board.selected_route
		inspected = "" if previous_selection < 0 else Map.Geometry.ROUTES[previous_selection].places[0]
	for index in range(route_buttons.size()):
		route_buttons[index].disabled = walk.route >= 0
		route_buttons[index].modulate.a = 0.55 if walk.route >= 0 and index != walk.route else 1.0
		route_buttons[index].set_pressed_no_signal(board.selected_route == index)
	for index in range(state_buttons.size()):
		state_buttons[index].set_pressed_no_signal(board.map_state == ["day", "night", "anomaly"][index])
	var active = board.active_route()
	if active < 0:
		detail.text = "尚未选择\n移动到地图中的地点或连接线，查看整条路线范围。"
	else:
		detail.text = ("悬停预览" if board.hovered_route >= 0 else "已选中") + " · " + Map.Geometry.ROUTES[active].title + "\n" + Map.Geometry.ROUTES[active].summary + "\n整片探索区域已亮起。"
	primary.disabled = board.selected_route < 0
	primary.text = "开始预览"
	secondary.text = "清除选择"
	secondary.disabled = board.selected_route < 0
	if walk.route >= 0:
		var place_name = Map.Geometry.PLACES[walk.current_place()].title
		var next_id = "" if walk.complete or walk.step == 2 else Map.Geometry.ROUTES[walk.route].places[walk.step + 1]
		detail.text = ("已到达 · " if walk.complete else "当前位置 · ") + place_name + "（%d / 3）" % [walk.step + 1] + "\n" + Map.Geometry.ROUTES[walk.route].summary
		detail.text += "\n" + ("路线预览完成" if next_id.is_empty() else "下一站 · " + Map.Geometry.PLACES[next_id].title)
		primary.text = "返回选路" if walk.complete else ("完成预览" if walk.step == 2 else "下一站")
		secondary.text = "结束预览"
		secondary.visible = not walk.complete
	else: secondary.visible = true
	place_box.visible = board.selected_route >= 0
	if board.selected_route >= 0:
		var ids = Map.Geometry.ROUTES[board.selected_route].places
		for index in range(3):
			place_buttons[index].text = Map.Geometry.PLACES[ids[index]].title
			place_buttons[index].set_pressed_no_signal(inspected == ids[index])
			place_buttons[index].tooltip_text = "查看地点；不会推进路线"
		if not inspected.is_empty():
			var place = Map.Geometry.PLACES[inspected]
			var index = ids.find(inspected)
			var state = "未出发"
			if walk.route >= 0: state = "已到达" if walk.complete or index < walk.step else ("当前位置" if index == walk.step else "尚未到达")
			place_detail.text = place.title + " · " + state + "\n第 %d 站 / 共 3 站\n" % [index + 1]
			place_detail.text += "路线终点" if index == 2 else "下一站：" + Map.Geometry.PLACES[ids[index + 1]].title
			var atlas = AtlasTexture.new()
			atlas.atlas = Map.TEXTURES[board.map_state]
			var bounds = Rect2(place.polygon[0], Vector2.ZERO)
			for point in place.polygon: bounds = bounds.expand(point)
			bounds = bounds.grow(18)
			var extent = Vector2(maxf(bounds.size.x, bounds.size.y * 4.0 / 3.0), maxf(bounds.size.y, bounds.size.x * 3.0 / 4.0))
			atlas.region = Rect2(bounds.get_center() - extent / 2, extent)
			picture.texture = atlas
	board.inspected_place = inspected
	board.current_place = walk.current_place()
	board.next_place = "" if walk.route < 0 or walk.complete or walk.step == 2 else Map.Geometry.ROUTES[walk.route].places[walk.step + 1]
	board.queue_redraw()

func _inspect(id: String) -> void:
	if board.selected_route < 0 or not Map.Geometry.ROUTES[board.selected_route].places.has(id): return
	inspected = id
	_refresh()

func _advance() -> void:
	if walk.complete:
		_reset()
		return
	if walk.route < 0:
		if not walk.start(board.selected_route): return
		board.locked_route = walk.route
		board.preview(-1)
	else:
		if not walk.advance(): return
	inspected = walk.current_place()
	_refresh()
	primary.grab_focus()

func _reset() -> void:
	if walk.route >= 0:
		walk.reset()
		board.locked_route = -1
		inspected = Map.Geometry.ROUTES[board.selected_route].places[0]
	else:
		board.select_route(-1)
	_refresh()
	if primary.disabled: route_buttons[0].grab_focus()
	else: primary.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	if closed.get_connections().is_empty():
		get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
	else: closed.emit()

func _open_expanded() -> void:
	var expanded = preload("res://scenes/expedition/expanded_campus_preview.tscn").instantiate()
	get_parent().add_child(expanded)
	hide()
	expanded.closed.connect(func():
		expanded.queue_free()
		show()
		board.queue_redraw()
		route_buttons[0].grab_focus())
