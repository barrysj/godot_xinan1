extends Control
## Focusable choices attached to map coordinates, never a second destination list.
signal picked(index: int)
signal previewed(index: int)
const NavSkin = preload("res://scenes/expedition/campus_navigation_skin.gd")
const MapNode = preload("res://scenes/expedition/campus_map_node.gd")
var board: Control
var points: Array[Vector2] = []
var titles: Array[String] = []
var buttons: Array[Button] = []
var thumbnails: Array[Texture2D] = []
var numbers: Array[String] = []
var occluders: Array[Control] = []
var connections: Array[Dictionary] = []
var compact := false
var graphical := true
var draw_all_connections := false
var selected := -1
var hovered := -1
var _drag_index := -1
var _dragged := false
var _drag_distance := 0.0
var _last_pointer := Vector2.ZERO

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for index in range(points.size()):
		var item: Button
		if graphical:
			item = MapNode.new()
			item.text = titles[index]
			item.thumbnail = thumbnails[index]
			item.number = numbers[index]
			item.state = board.map_state
			add_child(item)
			if compact: item.scale = Vector2(.78, .78)
		else:
			item = NavSkin.button(self, titles[index])
			item.toggle_mode = true
			item.size = Vector2(190, 54)
		item.pressed.connect(_pick.bind(index))
		item.mouse_entered.connect(func(): _preview(index))
		item.mouse_exited.connect(func(): _preview(-1))
		item.focus_entered.connect(func(): _preview(index))
		item.focus_exited.connect(func(): _preview(-1))
		item.gui_input.connect(_target_input.bind(index))
		buttons.append(item)
	board.changed.connect(sync)
	board.resized.connect(sync)
	resized.connect(sync)
	# Position updates occur only while the shared map camera is moving.
	set_process(false)
	sync()

func _pick(index: int) -> void:
	if _dragged:
		select(selected)
		return
	picked.emit(index)

func _target_input(event: InputEvent, index: int) -> void:
	var item := buttons[index]
	var inverse: Transform2D = board.get_global_transform_with_canvas().affine_inverse()
	if event is InputEventMouseButton:
		var at: Vector2 = inverse * (item.get_global_transform_with_canvas() * event.position)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var wheel: InputEventMouseButton = event.duplicate()
			wheel.position = at
			board._gui_input(wheel)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_index = index
				_dragged = false
				_drag_distance = 0
				_last_pointer = at
			else:
				_drag_index = -1
				board.dragging = false
	elif event is InputEventMouseMotion:
		var at: Vector2 = inverse * (item.get_global_transform_with_canvas() * event.position)
		if _drag_index == index and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var delta := at - _last_pointer
			_drag_distance += delta.length()
			_last_pointer = at
			if _drag_distance > 5:
				_dragged = true
				board.dragging = true
				board.pan(delta)
		else: _preview(index)
	else:
		# A completed mouse drag must not suppress a subsequent keyboard/gamepad action.
		_dragged = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_drag_index = -1
		_dragged = true

func _process(_delta: float) -> void:
	_position_buttons()
	if not board.view_is_moving(): set_process(false)

func sync() -> void:
	_position_buttons()
	for item in buttons:
		if graphical: item.set_navigation_state(board.map_state)
		else: NavSkin.style_button(item, board.map_state)
	if board.view_is_moving(): set_process(true)

func select(index: int) -> void:
	selected = index
	for i in range(buttons.size()): buttons[i].set_pressed_no_signal(i == index)
	sync()

func _preview(index: int) -> void:
	var changed := hovered != index
	hovered = index
	previewed.emit(index)
	if changed: queue_redraw()

func _position_buttons() -> void:
	for i in range(buttons.size()):
		var at: Vector2 = board.project(points[i])
		var extent: Vector2 = buttons[i].size * buttons[i].scale
		var center := Vector2(90,50) * buttons[i].scale if graphical else extent/2
		var position_at := (at - center).clamp(Vector2(24, 140), size-extent-Vector2(24, 24))
		for obstacle in occluders:
			if not obstacle.is_visible_in_tree(): continue
			var rect := obstacle.get_global_rect()
			if not Rect2(position_at, extent).intersects(rect): continue
			position_at.x = maxf(24, rect.position.x - extent.x - 18)
		for earlier in range(i):
			if compact: break
			var other := Rect2(buttons[earlier].position, buttons[earlier].size*buttons[earlier].scale).grow(6)
			if not Rect2(position_at, extent).intersects(other): continue
			position_at.y = clampf(other.end.y+8, 140, size.y-extent.y-24)
			if Rect2(position_at, extent).intersects(other):
				position_at.x = maxf(24, other.position.x-extent.x-12)
		buttons[i].position = position_at
	queue_redraw()

func _draw() -> void:
	if board == null: return
	var active := hovered if hovered >= 0 else selected
	var junctions: Dictionary = {}
	for link in connections:
		if not draw_all_connections and active >= 0 and link.index != active: continue
		var from: Vector2 = board.project(link.from)
		var to: Vector2 = board.project(link.to)
		var colour := Color(NavSkin.palette("brand").white, .65 if active >= 0 else .3)
		draw_line(from, to, Color(NavSkin.palette("brand").black, .9), 4, true)
		draw_line(from, to, colour, 1.5, true)
		junctions[link.from] = true
		junctions[link.to] = true
	for point in junctions:
		if points.has(point): continue
		var at: Vector2 = board.project(point)
		draw_circle(at, 7, Color(NavSkin.palette("brand").black))
		draw_circle(at, 4, Color(NavSkin.palette("brand").white), false, 1.5, true)
	for i in range(buttons.size()):
		var at: Vector2 = board.project(points[i])
		var edge: Vector2 = buttons[i].position+(Vector2(90,50)*buttons[i].scale if graphical else buttons[i].size/2)
		var color := NavSkin.accent(board.map_state)
		color.a = .95 if i == selected or i == hovered else .5
		draw_line(at, edge, Color("0c1826", .85), 5, true)
		draw_line(at, edge, color, 2, true)
		draw_circle(at, 7, Color("0c1826"))
		draw_circle(at, 4, color)
