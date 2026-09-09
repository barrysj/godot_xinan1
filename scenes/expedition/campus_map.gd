extends Control
## Read-only map navigation; the owner handles selection and dispatch transactions.
signal location_selected(index: int)
const Catalog = preload("res://game/meta/meta_catalog.gd")
const Comic = preload("res://scenes/ui/comic_ui.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const WORLD_SIZE = Vector2(1200, 680)
var progress: RefCounted
var selected := -1
var hovered := -1
var zoom := 1.0
var pan := Vector2.ZERO
var dragging := false
var moved := false
var press_position := Vector2.ZERO
var press_pan := Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(func(): hovered = -1; queue_redraw())
	visibility_changed.connect(func():
		dragging = false
		hovered = -1
		queue_redraw())
	resized.connect(func(): _clamp_pan(); queue_redraw())

func _fit() -> float:
	return minf(size.x / WORLD_SIZE.x, size.y / WORLD_SIZE.y)

func _offset() -> Vector2:
	return (size - WORLD_SIZE * _fit() * zoom) / 2 + pan

func point(index: int) -> Vector2:
	return Catalog.LOCATIONS[index].get("map_position", Vector2(250 + (index % 3) * 320, 200 + int(index / 3) * 220))

func location_at(local: Vector2) -> int:
	if not Rect2(Vector2.ZERO, size).has_point(local) or _fit() <= 0: return -1
	var world := (local - _offset()) / (_fit() * zoom)
	for i in range(Catalog.LOCATIONS.size() - 1, -1, -1):
		if Rect2(point(i) - Vector2(94, 62), Vector2(188, 150)).has_point(world): return i
	return -1

func _clamp_pan() -> void:
	var limit := (WORLD_SIZE * _fit() * zoom - size).max(Vector2.ZERO) / 2
	pan = pan.clamp(-limit, limit)

func zoom_at(local: Vector2, factor: float) -> void:
	if _fit() <= 0: return
	var world := (local - _offset()) / (_fit() * zoom)
	zoom = clampf(zoom * factor, 1.0, 2.5)
	pan = local - (size - WORLD_SIZE * _fit() * zoom) / 2 - world * _fit() * zoom
	_clamp_pan()
	hovered = location_at(local)
	queue_redraw()

func reset_view() -> void:
	zoom = 1
	pan = Vector2.ZERO
	hovered = -1
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position, 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				grab_focus()
				dragging = true
				moved = false
				press_position = event.position
				press_pan = pan
			else:
				var clicked := dragging and not moved
				dragging = false
				var index := location_at(event.position)
				if clicked and index >= 0:
					selected = index
					location_selected.emit(index)
	elif event is InputEventMouseMotion:
		if dragging:
			moved = moved or event.position.distance_to(press_position) > 6
			if moved:
				pan = press_pan + event.position - press_position
				_clamp_pan()
		hovered = -1 if dragging and moved else location_at(event.position)
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_LEFT, KEY_RIGHT]:
			selected = posmod(selected + (1 if event.keycode == KEY_RIGHT else -1), Catalog.LOCATIONS.size())
			hovered = selected
			pan = (WORLD_SIZE / 2 - point(selected)) * _fit() * zoom
			_clamp_pan()
		elif event.keycode in [KEY_ENTER, KEY_SPACE] and selected >= 0:
			location_selected.emit(selected)
	queue_redraw()
	accept_event()

func _label(at: Vector2, text: String, color: Color, font_size: int = 20) -> void:
	draw_string(FONT, at - Vector2(FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	# Reuse the existing dispatch map's placeholder buildings and courtyard palette.
	draw_rect(Rect2(Vector2.ZERO, size), Color("718951"))
	draw_set_transform(_offset(), 0, Vector2.ONE * _fit() * zoom)
	draw_rect(Rect2(Vector2(65, 65), WORLD_SIZE - Vector2(130, 130)), Color("6f7360"))
	for y in range(70, 610, 30):
		for x in range(70, 1130, 36):
			draw_rect(Rect2(x, y, 34, 28), Color("b8b497"))
	draw_line(Vector2(600, 85), Vector2(600, 595), Color("d8c79d"), 18)
	for i in range(Catalog.LOCATIONS.size()):
		var location: Dictionary = Catalog.LOCATIONS[i]
		var p := point(i)
		var unlocked: bool = progress != null and progress.level(location.requires) > 0
		draw_line(Vector2(600, p.y), p, Color("d8c79d"), 16)
		Comic.card(self, Rect2(p - Vector2(80, 48), Vector2(160, 96)), Comic.WHITE if unlocked else Color("969d8c"), Comic.INK)
		draw_rect(Rect2(p - Vector2(88, 56), Vector2(176, 17)), Color("a86c57"))
		for x in [-48, 0, 48]:
			draw_rect(Rect2(p + Vector2(x - 12, -19), Vector2(24, 30)), Color("709caa"))
		if i == hovered or i == selected:
			draw_rect(Rect2(p - Vector2(94, 62), Vector2(188, 126)), Color("f7cc78"), false, 4)
		var status := "可派遣" if unlocked else "尚未解锁"
		if progress != null:
			for job in progress.dispatches:
				if job.location == location.id:
					status = "成果可领取" if int(job.ready_at) <= int(Time.get_unix_time_from_system()) else "探索中"
		_label(p + Vector2(0, 88), status, Comic.INK, 18)
	draw_set_transform(Vector2.ZERO)
	if hovered >= 0:
		var name: String = Catalog.LOCATIONS[hovered].name
		var extent := FONT.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20) + Vector2(32, 18)
		var at := _offset() + (point(hovered) + Vector2(0, -78)) * _fit() * zoom - Vector2(extent.x / 2, extent.y)
		at = at.clamp(Vector2(8, 8), (size - extent - Vector2(8, 8)).max(Vector2(8, 8)))
		Comic.card(self, Rect2(at, extent), Comic.INK)
		_label(at + Vector2(extent.x / 2, 28), name, Comic.WHITE)
