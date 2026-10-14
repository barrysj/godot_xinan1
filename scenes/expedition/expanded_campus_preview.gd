extends Control
signal closed
signal region_picked(region: String)
const Map = preload("res://scenes/expedition/expanded_campus_map.gd")
const Shell = preload("res://scenes/expedition/campus_navigation_shell.gd")
const NavSkin = preload("res://scenes/expedition/campus_navigation_skin.gd")
const Regions = preload("res://game/run/campus_region.gd")
const Presentation = preload("res://game/run/campus_presentation.gd")
const RouteNodes = preload("res://scenes/expedition/campus_route_nodes.gd")
const MapTargets = preload("res://scenes/expedition/campus_map_targets.gd")
var board: Control
var campaign_selectable = false
var completed_regions: Array = []
var route_buttons: Array[Button] = []
var state_buttons: Array[Button] = []
var zoom_in_button: Button
var zoom_out_button: Button
var zoom_reset_button: Button
var zoom_label: Label
var select_button: Button
var back_button: Button
var close_button: Button
var action_panel: PanelContainer
var targets: Control
var route_nodes: Control
var selected_node := -1
var built_region := -1
var check_runner: RefCounted
var shell: Control
var detail: VBoxContainer
var picture: TextureRect
var picture_caption: Label
var detail_title: Label
var detail_text: Label
var status: Label
var empty_hint: Label
var last_detail_key := ""
var shown_route := -1

func _ready() -> void:
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	board = Map.new()
	board.hidden_label_ids.append("library")
	board.spatial_navigation_only = false
	board.route_area_focus = true
	board.draw_route_paths = false
	add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.hover_overrides_selection = false
	board.changed.connect(_refresh)
	targets = MapTargets.new()
	targets.board = board
	targets.graphical = false
	for index in range(board.layout.ROUTES.size()):
		var region := campaign_region_for_route(index)
		targets.points.append(board.layout.ROUTES[index].path[0])
		targets.titles.append(Regions.flow_for(region).title)
	add_child(targets)
	route_buttons = targets.buttons
	targets.picked.connect(_choose_route)
	targets.previewed.connect(func(index: int): board.preview(index))
	shell = Shell.new()
	add_child(shell)
	shell.heading.text = "选择探索区域"
	shell.subtitle.text = "选择区域，再点击圆形地点查看详情"
	shell.rail_title.text = "节点预览"
	targets.occluders.append_array([shell.rail, shell.title_panel, shell.utility_panel])
	for obstacle in targets.occluders: obstacle.item_rect_changed.connect(targets.sync)
	empty_hint = NavSkin.label(shell.body, "先选择地图上的区域，展开该路线的全部地点。", 20, true)
	detail = VBoxContainer.new()
	detail.add_theme_constant_override("separation", 12)
	shell.body.add_child(detail)
	var frame := NavSkin.panel(detail, "day", 5)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size.y = 150
	frame.add_child(picture)
	picture_caption = NavSkin.label(detail, "", 16, true)
	detail_title = NavSkin.label(detail, "", 24)
	status = NavSkin.label(detail, "", 18)
	detail_text = NavSkin.label(detail, "", 19, true)
	var states := HBoxContainer.new()
	states.add_theme_constant_override("separation", 8)
	shell.utility.add_child(states)
	for state in ["day", "night", "anomaly"]:
		var state_button := NavSkin.button(states, {"day":"日间", "night":"夜间", "anomaly":"异常"}[state])
		state_button.toggle_mode = true
		state_button.tooltip_text = "仅切换地图外观，不改变探索状态"
		state_button.pressed.connect(func(): board.set_state(state))
		state_buttons.append(state_button)
	zoom_out_button = NavSkin.button(shell.tools, "缩小")
	zoom_in_button = NavSkin.button(shell.tools, "放大")
	zoom_reset_button = NavSkin.button(shell.tools, "复位")
	zoom_out_button.pressed.connect(func(): board.set_zoom(board.zoom / board.ZOOM_STEP))
	zoom_in_button.pressed.connect(func(): board.set_zoom(board.zoom * board.ZOOM_STEP))
	zoom_reset_button.pressed.connect(board.reset_view)
	zoom_label = NavSkin.label(shell.tools, "", 16, true)
	zoom_label.custom_minimum_size.x = 54
	action_panel = NavSkin.panel(shell.footer, "day", 0)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	action_panel.add_child(actions)
	select_button = NavSkin.button(actions, "开始探索" if campaign_selectable else "查看地点", true)
	select_button.pressed.connect(_confirm_route)
	back_button = NavSkin.button(actions, "返回")
	back_button.pressed.connect(_back)
	close_button = NavSkin.button(shell.footer, "返回基地" if campaign_selectable else "关闭")
	close_button.pressed.connect(_close)
	_refresh()
	_focus_first.call_deferred()
	if "--expanded-map-check" in OS.get_cmdline_user_args():
		check_runner = load("res://scenes/expedition/expanded_campus_preview_check.gd").new()
		check_runner.run(self)

func _choose_route(index: int) -> void:
	board.select_route(index)

func _build_nodes(index: int) -> void:
	if is_instance_valid(route_nodes):
		route_nodes.visible = false
		route_nodes.queue_free()
		route_nodes = null
	built_region = index
	selected_node = -1
	board.spatial_navigation_only = index >= 0
	board.route_area_focus = index < 0
	if index < 0: return
	route_nodes = RouteNodes.new()
	route_nodes.board = board
	route_nodes.region = campaign_region_for_route(index)
	route_nodes.flow = Regions.flow_for(route_nodes.region)
	add_child(route_nodes)
	move_child(route_nodes, shell.get_index())
	route_nodes.occluders.append_array(targets.occluders)
	route_nodes.picked.connect(_choose_node)
	route_nodes.sync()
	route_nodes.buttons[0].grab_focus.call_deferred()

func _choose_node(index: int) -> void:
	selected_node = index
	route_nodes.select(index)
	_refresh()

func _refresh() -> void:
	if zoom_label == null: return
	if built_region != board.selected_route: _build_nodes(board.selected_route)
	zoom_label.text = "%d%%" % roundi(board.zoom * 100.0)
	zoom_out_button.disabled = board.zoom <= board.MIN_ZOOM + .001
	zoom_in_button.disabled = board.zoom >= board.MAX_ZOOM - .001
	targets.select(board.selected_route)
	for index in range(state_buttons.size()):
		state_buttons[index].set_pressed_no_signal(board.map_state == ["day", "night", "anomaly"][index])
	action_panel.visible = true
	select_button.disabled = board.selected_route < 0
	select_button.visible = campaign_selectable
	back_button.text = "切换区域"
	back_button.visible = board.selected_route >= 0
	targets.visible = board.selected_route < 0
	shown_route = board.selected_route
	empty_hint.visible = selected_node < 0
	detail.visible = selected_node >= 0
	shell.heading.text = "选择探索区域" if shown_route < 0 else Regions.flow_for(campaign_region_for_route(shown_route)).title
	shell.subtitle.text = "选择区域，再点击圆形地点查看详情" if shown_route < 0 else "点击圆形地点查看详情 · 从第一站开始探索"
	shell.rail_title.text = "探索区域" if shown_route < 0 else "地点详情"
	if shown_route >= 0:
		empty_hint.text = "路线已展开。点击任意圆形地点查看详情；开始探索后从第一站出发。"
	else: empty_hint.text = "先选择地图上的区域，展开该路线的全部地点。"
	var detail_key := "%s:%s:%s" % [shown_route, selected_node, board.map_state]
	if detail.visible and detail_key != last_detail_key:
		_update_detail()
		NavSkin.reveal(detail)
	last_detail_key = detail_key
	shell.set_state(board.map_state)
	var candidates: Array[Button] = route_buttons.duplicate() if shown_route < 0 else route_nodes.buttons.duplicate()
	candidates.append_array([select_button, back_button, close_button])
	candidates.append_array(state_buttons)
	candidates.append_array([zoom_out_button, zoom_in_button, zoom_reset_button])
	var focus_buttons: Array[Button] = []
	for item in candidates:
		if item.is_visible_in_tree() and not item.disabled: focus_buttons.append(item)
	NavSkin.focus_loop(focus_buttons)

func _update_detail() -> void:
	var node: Dictionary = route_nodes.nodes[selected_node]
	var region := campaign_region_for_route(shown_route)
	var flow := Regions.flow_for(region)
	var state := "daily" if board.map_state == "day" else "anomaly"
	picture.texture = load(Presentation.background(region, node.stop, state, flow))
	picture_caption.text = "地点预览 · " + ("日间" if state == "daily" else "异常")
	detail_title.text = node.title
	status.text = "第 %d / %d 站" % [node.layer+1, flow.layers.size()]
	detail_text.text = "探索从第一站开始，沿路线逐站推进。"
	var components := Presentation.component_description(node.stop,board.layout,flow)
	if not components.is_empty(): detail_text.text += "\n"+components
	if completed_regions.has(region): detail_text.text += "\n终端已接入，可再次探索。"

func _confirm_route() -> void:
	if campaign_selectable:
		var region := campaign_region_for_route(board.selected_route)
		if not region.is_empty(): region_picked.emit(region)

func _focus_first() -> void:
	if is_inside_tree() and is_visible_in_tree(): route_buttons[0].grab_focus()

func _back() -> void:
	board.selection_enabled = true
	board.reset_view()
	board.select_route(-1)
	_refresh()
	_focus_first.call_deferred()

func campaign_region_for_route(index: int) -> String:
	return str(board.layout.ROUTES[index].campaign_region) if index >= 0 and index < board.layout.ROUTES.size() else ""

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if board.selected_route >= 0: _back()
		else: _close()

func _close() -> void:
	closed.emit()
