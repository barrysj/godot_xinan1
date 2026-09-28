extends Control
signal changed
signal place_picked(place: String)
const Geometry = preload("res://game/run/campus_route_geometry.gd")
const TEXTURES = {
	"day": preload("res://assets/art/campus_map/full-day.png"),
	"night": preload("res://assets/art/campus_map/full-night.png"),
	"anomaly": preload("res://assets/art/campus_map/full-anomaly.png")}
var map_state = "anomaly"
var selected_route = -1
var hovered_route = -1
var locked_route = -1
var current_place = ""
var next_place = ""
var inspected_place = ""
var surface: TextureRect
var overlay: Control
var focus_material: ShaderMaterial
var font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json"))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	mouse_exited.connect(func(): preview(-1))
	focus_material = ShaderMaterial.new()
	focus_material.shader = preload("res://scenes/expedition/campus_route_focus.gdshader")
	surface = TextureRect.new()
	surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	surface.mouse_filter = MOUSE_FILTER_IGNORE
	surface.material = focus_material
	add_child(surface)
	overlay = Control.new()
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.draw.connect(_draw_overlay)

func map_rect() -> Rect2:
	var factor = minf(size.x / Geometry.CROP.size.x, size.y / Geometry.CROP.size.y)
	var extent = Geometry.CROP.size * factor
	return Rect2((size - extent) / 2.0, extent)

func project(point: Vector2) -> Vector2:
	var rect = map_rect()
	return rect.position + (point - Geometry.CROP.position) * rect.size / Geometry.CROP.size

func polygon(points: Array) -> PackedVector2Array:
	var result = PackedVector2Array()
	for point in points: result.append(project(point))
	return result

func active_route() -> int:
	if locked_route >= 0: return locked_route
	return hovered_route if hovered_route >= 0 else selected_route

func preview(index: int) -> void:
	if locked_route >= 0: index = -1
	if hovered_route == index: return
	hovered_route = index
	queue_redraw()
	changed.emit()

func select_route(index: int) -> void:
	if locked_route >= 0: return
	if index < -1 or index >= Geometry.ROUTES.size(): return
	selected_route = index
	hovered_route = -1
	queue_redraw()
	changed.emit()

func set_state(value: String) -> void:
	if not TEXTURES.has(value): return
	map_state = value
	queue_redraw()

func route_at(at: Vector2) -> int:
	if not map_rect().has_point(at): return -1
	for index in range(Geometry.ROUTES.size()):
		for place in Geometry.ROUTES[index].places:
			if Geometry2D.is_point_in_polygon(at, polygon(Geometry.PLACES[place].polygon)): return index
	# Precise landmarks win in shared space; otherwise use the same envelope as the shader.
	var candidates: Array[int] = []
	for index in range(Geometry.AREAS.size()):
		if Geometry2D.is_point_in_polygon(at, polygon(Geometry.AREAS[index])): candidates.append(index)
	if candidates.size() == 1: return candidates[0]
	var best = -1
	var distance = INF if not candidates.is_empty() else 18.0
	for index in range(Geometry.ROUTES.size()):
		if not candidates.is_empty() and not candidates.has(index): continue
		var path = polygon(Geometry.ROUTES[index].path)
		for i in range(path.size() - 1):
			var d = at.distance_to(Geometry2D.get_closest_point_to_segment(at, path[i], path[i + 1]))
			if d < distance:
				distance = d
				best = index
	return best

func place_at(at: Vector2) -> String:
	for id in Geometry.PLACES:
		var place = Geometry.PLACES[id]
		var label_size = Vector2(font.get_string_size("3 · " + place.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 26, 34)
		if Rect2(project(place.anchor) - label_size / 2, label_size).has_point(at): return id
		if Geometry2D.is_point_in_polygon(at, polygon(place.polygon)): return id
	return ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		preview(route_at(event.position))
		var place = place_at(event.position)
		var can_inspect = not place.is_empty() and (locked_route < 0 or Geometry.ROUTES[locked_route].places.has(place))
		tooltip_text = Geometry.PLACES[place].title + (" · 点击查看地点" if can_inspect else " · 不在当前路线") if not place.is_empty() else ""
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if hovered_route >= 0 or can_inspect else CURSOR_ARROW
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var index = route_at(event.position)
		if index >= 0: select_route(index)
		var place = place_at(event.position)
		if not place.is_empty() and (locked_route < 0 or Geometry.ROUTES[locked_route].places.has(place)):
			place_picked.emit(place)
		accept_event()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(palette.night.background))
	if surface == null: return
	surface.texture = TEXTURES[map_state]
	surface.position = map_rect().position
	surface.size = map_rect().size
	var active = active_route()
	focus_material.set_shader_parameter("focused", active >= 0)
	focus_material.set_shader_parameter("inside_gain", 1.08 if map_state == "day" else 1.28)
	if active >= 0:
		var vertices = PackedVector2Array(Geometry.AREAS[active])
		focus_material.set_shader_parameter("point_count", vertices.size())
		vertices.resize(32)
		focus_material.set_shader_parameter("points", vertices)
		focus_material.set_shader_parameter("route_color", Color(palette.brand.yellow_neon if active == 0 else palette.brand.cyan_bright))
	overlay.queue_redraw()

func _draw_overlay() -> void:
	var active = active_route()
	for index in range(Geometry.ROUTES.size()):
		var color = Color(palette.brand.yellow_neon if index == 0 else palette.brand.cyan_bright)
		var path = polygon(Geometry.ROUTES[index].path)
		if active < 0 or index == active:
			overlay.draw_polyline(path, Color(0.02,0.04,0.08,0.65), 5, true)
			overlay.draw_polyline(path, Color(color, 0.8 if index == active else 0.35), 2, true)
		for number in range(3):
			var place = Geometry.PLACES[Geometry.ROUTES[index].places[number]]
			var at = project(place.anchor)
			var text = "%d · %s" % [number + 1, place.title]
			var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 26
			var box = Rect2(at - Vector2(width / 2, 17), Vector2(width, 34))
			var is_current = Geometry.ROUTES[index].places[number] == current_place
			var is_next = Geometry.ROUTES[index].places[number] == next_place
			if not is_current and Geometry.ROUTES[index].places[number] == inspected_place:
				overlay.draw_rect(box.grow(4), Color(color,0.7), false, 1)
			var style = _label_style(color if index == active else Color(palette.daily.text_secondary))
			if is_current:
				style.bg_color = color
				style.border_color = Color.WHITE
				style.set_border_width_all(3)
			elif is_next:
				style.border_color = Color.WHITE
				style.set_border_width_all(3)
			overlay.draw_style_box(style, box)
			overlay.draw_string(font, box.position + Vector2(13, 24), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(palette.daily.text_primary) if is_current else (Color.WHITE if index == active or active < 0 else Color("87949F")))
			if is_current:
				var badge = Rect2(Vector2(at.x - 52, box.position.y - 57), Vector2(104, 34))
				overlay.draw_line(Vector2(at.x, badge.end.y), Vector2(at.x, box.position.y - 4), Color.WHITE, 5)
				overlay.draw_line(Vector2(at.x, badge.end.y), Vector2(at.x, box.position.y - 4), color, 2)
				var pointer = PackedVector2Array([Vector2(at.x, box.position.y - 2), Vector2(at.x - 9, box.position.y - 14), Vector2(at.x + 9, box.position.y - 14)])
				overlay.draw_colored_polygon(pointer, color)
				var badge_style = _label_style(Color.WHITE)
				badge_style.set_border_width_all(2)
				overlay.draw_style_box(badge_style, badge)
				overlay.draw_string(font, badge.position + Vector2(13, 24), "你在这里", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
			elif is_next:
				var next_badge = Rect2(Vector2(at.x - 40, box.end.y + 17), Vector2(80, 30))
				overlay.draw_line(Vector2(at.x, box.end.y + 2), Vector2(at.x, next_badge.position.y), Color.WHITE, 2)
				var next_style = _label_style(color)
				overlay.draw_style_box(next_style, next_badge)
				overlay.draw_string(font, next_badge.position + Vector2(13, 21), "下一站", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

func _label_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(palette.night.surface)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
