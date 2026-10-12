extends Control
## A preview never mutates the journey; only the existing enter action travels.
signal action(id: String)
const Shell = preload("res://scenes/expedition/campus_navigation_shell.gd")
const NavSkin = preload("res://scenes/expedition/campus_navigation_skin.gd")
const RouteMap = preload("res://scenes/expedition/campaign_route_map.gd")
const Presentation = preload("res://game/run/campus_presentation.gd")
const RouteNodes = preload("res://scenes/expedition/campus_route_nodes.gd")
var journey
var restored := false
var board: Control
var shell: Control
var destination_buttons: Array[Button] = []
var travel_button: Button
var base_button: Button
var picture: TextureRect
var detail_title: Label
var detail_text: Label
var detail: VBoxContainer
var zoom_label: Label
var zoom_buttons: Array[Button] = []
var targets: Control
var selected_node := -1
var preview_index := -1
var last_preview := -1

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	board = RouteMap.new()
	board.name = "RouteMap"
	board.journey = journey
	board.map_state = "day" if restored else "anomaly"
	board.spatial_targets = true
	add_child(board)
	board.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	targets = RouteNodes.new()
	targets.board = board
	targets.region = journey.data.region
	targets.flow = journey.data.flow
	targets.current_layer = journey.data.step
	targets.visited = journey.data.visited
	add_child(targets)
	# The board draws travelled forks; the shared nodes supply location callouts only.
	targets.connections.clear()
	for i in range(targets.nodes.size()):
		if targets.nodes[i].layer == journey.data.step: destination_buttons.append(targets.buttons[i])
	targets.picked.connect(_choose_node)
	shell = Shell.new()
	shell.content_height = 330
	shell.state = board.map_state
	add_child(shell)
	shell.heading.text = journey.data.flow.title
	var current: String = "基地" if journey.data.visited.is_empty() else journey.title(journey.data.visited.back())
	shell.subtitle.text = "当前位置 · " + current + "  /  点击地图节点选择下一站"
	shell.rail_title.text = "下一站 · %d / %d" % [journey.data.step+1, journey.data.map.size()]
	targets.occluders.append_array([shell.rail, shell.title_panel])
	for obstacle in targets.occluders: obstacle.item_rect_changed.connect(targets.sync)
	detail = VBoxContainer.new()
	detail.add_theme_constant_override("separation", 10)
	shell.body.add_child(detail)
	var frame := NavSkin.panel(detail, board.map_state, 5)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size.y = 150
	frame.add_child(picture)
	detail_title = NavSkin.label(detail, "", 24)
	detail_text = NavSkin.label(detail, "", 19, true)
	NavSkin.label(shell.body, "点击地点查看详情；仅当前站点可前往。", 16, true)
	travel_button = NavSkin.button(shell.footer, "前往", true)
	travel_button.pressed.connect(func(): action.emit(travel_button.get_meta("action_id")))
	base_button = NavSkin.button(shell.footer, "返回基地")
	base_button.set_meta("action_id", "base")
	base_button.pressed.connect(func(): action.emit("base"))
	for title in ["缩小", "放大", "复位"]:
		zoom_buttons.append(NavSkin.button(shell.tools, title))
	zoom_buttons[0].pressed.connect(func(): board.set_zoom(board.zoom / board.ZOOM_STEP))
	zoom_buttons[1].pressed.connect(func(): board.set_zoom(board.zoom * board.ZOOM_STEP))
	zoom_buttons[2].pressed.connect(board.reset_view)
	zoom_label = NavSkin.label(shell.tools, "", 16, true)
	zoom_label.custom_minimum_size.x = 54
	board.picked.connect(_select)
	board.changed.connect(_refresh_zoom)
	_select(0, false)
	_refresh_zoom()
	_focus_first.call_deferred()

func _focus_first() -> void:
	if is_inside_tree() and is_visible_in_tree(): destination_buttons[0].grab_focus()

func _choose_node(index: int) -> void:
	var node: Dictionary = targets.nodes[index]
	selected_node = index
	if node.layer == journey.data.step: board.choose(node.choice)
	else:
		targets.select(index)
		_show_detail(index)

func _select(index: int, animate := true) -> void:
	# A compound stop has two geographic nodes sharing one valid enter action.
	if selected_node < 0 or targets.nodes[selected_node].layer != journey.data.step or targets.nodes[selected_node].choice != index:
		for i in range(targets.nodes.size()):
			if targets.nodes[i].layer == journey.data.step and targets.nodes[i].choice == index:
				selected_node = i
				break
	targets.select(selected_node)
	_show_detail(selected_node, animate)

func _show_detail(index: int, animate := true) -> void:
	var node: Dictionary = targets.nodes[index]
	var state := "daily" if restored else "anomaly"
	picture.texture = load(Presentation.background(journey.data.region, node.stop, state, journey.data.flow))
	detail_title.text = node.title
	var available: bool = node.layer == journey.data.step
	travel_button.disabled = not available
	travel_button.set_meta("action_id", "enter:"+str(node.choice) if available else "")
	travel_button.tooltip_text = "前往" + node.title if available else "当前地点仅供查看"
	if available:
		detail_text.text = "当前可选 · 第 %d 站\n突破守卫，领取奖励后继续探索。" % [node.layer+1]
	elif node.layer > journey.data.step:
		detail_text.text = "后续地点 · 第 %d 站\n完成当前站点后，沿路线前往。" % [node.layer+1]
	else:
		detail_text.text = "已走过 · 第 %d 站" % [node.layer+1] if journey.data.visited.has(node.stop) else "未选择的分支 · 第 %d 站" % [node.layer+1]
	if node.stop == "end_c": detail_text.text += "\n本次站点包含成电会堂与商业街。"
	shell.set_state(board.map_state)
	if animate and last_preview != index: NavSkin.reveal(detail)
	last_preview = index
	_refresh_zoom()

func _refresh_zoom() -> void:
	zoom_label.text = "%d%%" % roundi(board.zoom * 100)
	zoom_buttons[0].disabled = board.zoom <= board.MIN_ZOOM + .001
	zoom_buttons[1].disabled = board.zoom >= board.MAX_ZOOM - .001
	NavSkin.apply(shell.tools, board.map_state)
	var focus_buttons: Array[Button] = destination_buttons.duplicate()
	for item in targets.buttons:
		if not focus_buttons.has(item): focus_buttons.append(item)
	if not travel_button.disabled: focus_buttons.append(travel_button)
	focus_buttons.append(base_button)
	for item in zoom_buttons:
		if not item.disabled: focus_buttons.append(item)
	NavSkin.focus_loop(focus_buttons)
