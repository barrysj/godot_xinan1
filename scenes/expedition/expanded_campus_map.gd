extends Control
signal changed
signal place_picked(place: String)
const Geometry = preload("res://game/run/expanded_campus_geometry.gd")
const PlatformAssetPaths = preload("res://game/visual/platform_asset_paths.gd")
var layout = Geometry.new()
const TEXTURES = {
	"day": "res://assets/art/campus_map/expanded_neutral/day.png",
	"night": "res://assets/art/campus_map/expanded_neutral/night.png",
	"anomaly": "res://assets/art/campus_map/expanded_neutral/anomaly.png"
}
# The atlas surrounds the unchanged 1800x1500 interactive core.
const ATLAS_ORIGIN = Vector2(-700, 0)
const ATLAS_SIZE = Vector2(3200, 1500)
# Colour-matched fallback beyond the rendered 32:15 canvas.
# The second colour matches the route-focus shader's dimmed exterior.
const BACKDROPS = {
	"day": [Color("a7ae9f"), Color("444541")],
	"night": [Color("09131b"), Color("060808")],
	"anomaly": [Color("091118"), Color("0a0c0c")]
}
const MIN_ZOOM = 1.0
# Same campus outline; dark states need separate perceptual contrast and a softer transition.
const LIGHT_TREATMENT = {
	"day": {"saturation": 1.0, "ambient": Vector3.ZERO, "feather": 1.0},
	"night": {"saturation": 0.8, "ambient": Vector3(0.012, 0.021, 0.028), "feather": 2.5},
	"anomaly": {"saturation": 0.62, "ambient": Vector3(0.009, 0.017, 0.023), "feather": 2.5}
}
const MAX_ZOOM = 3.0
const ZOOM_STEP = 1.25
const VIEW_RESPONSE = 18.0
const DRAG_RESPONSE = 32.0
var map_state = "day"
static var texture_cache: Dictionary = {}
static var pending_textures: Dictionary = {}
var selected_route = -1
var hovered_route = -1
var hover_overrides_selection = true
var selection_enabled = true
var selected_place = ""
var hidden_label_ids: Array[String] = []
var spatial_navigation_only := false
var route_area_focus := true
var draw_route_paths := true
var surface: TextureRect
var overlay: Control
var focus_material: ShaderMaterial
var font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var zoom = 1.0
var map_offset = Vector2.ZERO
var displayed_zoom = 1.0
var displayed_offset = Vector2.ZERO
var last_drag = Vector2.ZERO
var drag_distance = 0.0
var dragging = false
var loading_label: Label
static var failed_textures: Dictionary = {}

static func warm_texture(state: String) -> void:
	if texture_cache.has(state) or pending_textures.has(state) or failed_textures.has(state): return
	var path := PlatformAssetPaths.resolve(TEXTURES[state])
	if ResourceLoader.load_threaded_request(path, "Texture2D") == OK:
		pending_textures[state] = path
	else:
		failed_textures[state] = true

func _update_texture() -> void:
	loading_label.visible = not texture_cache.has(map_state)
	loading_label.text = "地图暂不可用" if failed_textures.has(map_state) else "地图加载中…"
	if texture_cache.has(map_state):
		if surface.texture != texture_cache[map_state]:
			surface.texture = texture_cache[map_state]
			queue_redraw()
		return
	warm_texture(map_state)
	if not pending_textures.has(map_state): return
	var path: String = pending_textures[map_state]
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		texture_cache[map_state] = ResourceLoader.load_threaded_get(path)
		pending_textures.erase(map_state)
		surface.texture = texture_cache[map_state]
		queue_redraw()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		failed_textures[map_state] = true
		pending_textures.erase(map_state)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(func(): _clamp_offset(); displayed_offset = _bounded_offset(displayed_offset, displayed_zoom); queue_redraw())
	mouse_exited.connect(func(): preview(-1))
	focus_material = ShaderMaterial.new()
	focus_material.shader = preload("res://scenes/expedition/campus_route_focus.gdshader")
	focus_material.set_shader_parameter("crop_origin", ATLAS_ORIGIN)
	focus_material.set_shader_parameter("crop_size", ATLAS_SIZE)
	focus_material.set_shader_parameter("texture_size", ATLAS_SIZE)
	focus_material.set_shader_parameter("texture_origin", ATLAS_ORIGIN)
	var boundary = PackedVector2Array(layout.LIGHT_BOUNDARY)
	focus_material.set_shader_parameter("light_boundary_count", boundary.size())
	boundary.resize(32)
	focus_material.set_shader_parameter("light_boundary", boundary)
	focus_material.set_shader_parameter("light_boundary_feather", layout.LIGHT_FEATHER)
	surface = TextureRect.new()
	surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	surface.mouse_filter = MOUSE_FILTER_IGNORE
	surface.material = focus_material
	add_child(surface)
	overlay = Control.new()
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.draw.connect(_draw_overlay)
	loading_label = Label.new()
	loading_label.text = "地图加载中…"
	loading_label.mouse_filter = MOUSE_FILTER_IGNORE
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_override("font", font)
	loading_label.add_theme_font_size_override("font_size", 24)
	add_child(loading_label)
	loading_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

func fit_rect() -> Rect2:
	var factor = minf(size.x / layout.SIZE.x, size.y / layout.SIZE.y)
	var extent = layout.SIZE * factor
	return Rect2((size - extent) / 2.0, extent)

func map_rect() -> Rect2:
	var extent = fit_rect().size * displayed_zoom
	return Rect2((size - extent) / 2.0 + displayed_offset, extent)

func view_is_moving() -> bool:
	return displayed_zoom != zoom or displayed_offset != map_offset

func _process(delta: float) -> void:
	_update_texture()
	if not view_is_moving(): return
	_advance_view(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Release may land over an overlay panel rather than this Control.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		dragging = false

func _advance_view(delta: float) -> void:
	# Exponential response is independent of frame rate; shared weight preserves the zoom pivot.
	var weight = 1.0 - exp(-(DRAG_RESPONSE if dragging else VIEW_RESPONSE) * delta)
	displayed_zoom = lerpf(displayed_zoom, zoom, weight)
	displayed_offset = displayed_offset.lerp(map_offset, weight)
	displayed_offset = _bounded_offset(displayed_offset, displayed_zoom)
	if absf(displayed_zoom - zoom) < 0.0001 and displayed_offset.distance_to(map_offset) < 0.05:
		displayed_zoom = zoom
		displayed_offset = map_offset

func _clamp_offset() -> void:
	map_offset = _bounded_offset(map_offset, zoom)

func _bounded_offset(offset: Vector2, scale_value: float) -> Vector2:
	var extent = fit_rect().size * scale_value
	var origin = (size - extent) / 2.0 + offset
	for axis in [0, 1]:
		if extent[axis] <= size[axis]:
			origin[axis] = (size[axis] - extent[axis]) / 2.0
		else:
			origin[axis] = clampf(origin[axis], size[axis] - extent[axis], 0.0)
	return origin - (size - extent) / 2.0

func unproject(point: Vector2) -> Vector2:
	var rect = map_rect()
	return (point - rect.position) * layout.SIZE / rect.size

func set_zoom(value: float, anchor: Vector2 = Vector2.INF) -> void:
	var target = clampf(value, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(target, zoom): return
	var pivot = size / 2.0 if anchor == Vector2.INF else anchor
	var source_point = unproject(pivot)
	zoom = target
	var extent = fit_rect().size * zoom
	map_offset = pivot - source_point * extent / layout.SIZE - (size - extent) / 2.0
	_clamp_offset()
	queue_redraw()
	changed.emit()

func pan(delta: Vector2) -> void:
	if is_equal_approx(zoom, MIN_ZOOM): return
	map_offset += delta
	_clamp_offset()
	queue_redraw()
	changed.emit()

func reset_view() -> void:
	zoom = MIN_ZOOM
	map_offset = Vector2.ZERO
	queue_redraw()
	changed.emit()

func focus_route(index: int) -> void:
	if index < 0 or index >= layout.ROUTES.size(): return
	var bounds = Rect2(layout.ROUTES[index].area[0], Vector2.ZERO)
	for point in layout.ROUTES[index].area: bounds = bounds.expand(point)
	var fit = fit_rect().size
	var available = size * 0.78
	zoom = clampf(minf(available.x * layout.SIZE.x / (fit.x * bounds.size.x), available.y * layout.SIZE.y / (fit.y * bounds.size.y)), MIN_ZOOM, MAX_ZOOM)
	var extent = fit * zoom
	map_offset = size / 2.0 - bounds.get_center() * extent / layout.SIZE - (size - extent) / 2.0
	_clamp_offset()
	queue_redraw()
	changed.emit()

func project(point: Vector2) -> Vector2:
	var rect = map_rect()
	return rect.position + point * rect.size / layout.SIZE

func active_route() -> int:
	if not hover_overrides_selection and selected_route >= 0: return selected_route
	return hovered_route if hovered_route >= 0 else selected_route

func preview(index: int) -> void:
	if hovered_route == index: return
	hovered_route = index
	queue_redraw()
	changed.emit()

func select_route(index: int) -> void:
	if index < -1 or index >= layout.ROUTES.size(): return
	selected_route = index
	hovered_route = -1
	selected_place = ""
	queue_redraw()
	changed.emit()

func set_state(value: String) -> void:
	if not TEXTURES.has(value): return
	map_state = value
	queue_redraw()
	changed.emit()

func route_at(at: Vector2) -> int:
	if not Rect2(Vector2.ZERO, size).has_point(at) or not map_rect().has_point(at): return -1
	var source_point = unproject(at)
	for index in range(layout.ROUTES.size()):
		if Geometry2D.is_point_in_polygon(source_point, PackedVector2Array(layout.ROUTES[index].area)): return index
	return -1

func place_at(at: Vector2) -> String:
	if not Rect2(Vector2.ZERO, size).has_point(at) or not map_rect().has_point(at): return ""
	var distance = 28.0
	var nearest = ""
	for id in layout.PLACES:
		var d = at.distance_to(project(layout.PLACES[id].point))
		if d < distance:
			distance = d
			nearest = id
	return nearest

func place_title(place: String) -> String:
	return str(layout.PLACES.get(place, {}).get("title", place))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if dragging:
			var delta = event.position - last_drag
			last_drag = event.position
			drag_distance += delta.length()
			if drag_distance > 5.0: pan(delta)
			accept_event()
			return
		if not spatial_navigation_only: preview(route_at(event.position))
		var place = "" if spatial_navigation_only else place_at(event.position)
		tooltip_text = place_title(place) + " · 点击查看" if not place.is_empty() else ""
		mouse_default_cursor_shape = CURSOR_ARROW if spatial_navigation_only else (CURSOR_POINTING_HAND if not place.is_empty() or hovered_route >= 0 else CURSOR_ARROW)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			set_zoom(zoom * (ZOOM_STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP), event.position)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_drag = event.position
				drag_distance = 0.0
			else:
				dragging = false
				if drag_distance <= 5.0:
					var place = "" if spatial_navigation_only else place_at(event.position)
					if not place.is_empty():
						selected_place = place
						place_picked.emit(place)
					else:
						var index = -1 if spatial_navigation_only else route_at(event.position)
						if selection_enabled and index >= 0: select_route(index)
					queue_redraw()
			accept_event()

func _draw() -> void:
	var active = active_route()
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROPS[map_state][1 if active >= 0 else 0])
	if surface == null: return
	surface.position = map_rect().position + ATLAS_ORIGIN * map_rect().size / layout.SIZE
	surface.size = ATLAS_SIZE * map_rect().size / layout.SIZE
	focus_material.set_shader_parameter("focused", active >= 0 and route_area_focus)
	focus_material.set_shader_parameter("light_outside_brightness", float(layout.OUTSIDE_BRIGHTNESS[map_state]))
	var light: Dictionary = LIGHT_TREATMENT[map_state]
	focus_material.set_shader_parameter("light_outside_saturation", light.saturation)
	focus_material.set_shader_parameter("light_inside_ambient", light.ambient)
	focus_material.set_shader_parameter("light_boundary_feather", layout.LIGHT_FEATHER * float(light.feather))
	focus_material.set_shader_parameter("inside_gain", 1.08 if map_state == "day" else 1.28)
	if active >= 0:
		var vertices = PackedVector2Array(layout.ROUTES[active].area)
		focus_material.set_shader_parameter("point_count", vertices.size())
		vertices.resize(32)
		focus_material.set_shader_parameter("points", vertices)
		focus_material.set_shader_parameter("route_color", Color(layout.ROUTES[active].color))
	overlay.queue_redraw()

func _draw_overlay() -> void:
	if spatial_navigation_only: return
	var active = active_route()
	for index in range(layout.ROUTES.size()):
		if not draw_route_paths: break
		if active >= 0 and index != active: continue
		var color = Color(layout.ROUTES[index].color)
		var path = PackedVector2Array()
		for point in layout.ROUTES[index].path: path.append(project(point))
		overlay.draw_polyline(path, Color("0c1826"), 7, true)
		overlay.draw_polyline(path, Color(color, .95 if index == active else .55), 3, true)
	for id in layout.PLACES:
		var place = layout.PLACES[id]
		var at = project(place.point)
		var chosen = id == selected_place
		var size_px = 7.0 if chosen else 5.0
		overlay.draw_circle(at, size_px + 3, Color("0d1b2b"))
		overlay.draw_circle(at, size_px, Color("fff4ce") if chosen else Color("78e2ef"))
		if hidden_label_ids.has(id): continue
		var label = place.title
		var width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 16
		var box = Rect2(at + Vector2(8, -30), Vector2(width, 28))
		overlay.draw_rect(box, Color("102236", .92))
		overlay.draw_rect(box, Color("fff4ce") if chosen else Color("5eb8ce"), false, 1)
		overlay.draw_string(font, box.position + Vector2(8, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
