extends RefCounted
## Typed image-pixel geometry loaded from the single user-editable layout file.
const SOURCE = "res://game/run/expanded_campus_layout.json"

var SIZE: Vector2
var PLACES: Dictionary
var ROUTES: Array[Dictionary]
var LIGHT_BOUNDARY: Array[Vector2]
var LIGHT_FEATHER: float
var OUTSIDE_BRIGHTNESS: Dictionary

func _init() -> void:
	var source = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not source is Dictionary:
		push_error("Invalid campus layout JSON: " + SOURCE)
		return
	if not _valid_source(source):
		push_error("Invalid campus layout coordinates or references: " + SOURCE)
		return
	SIZE = _point(source.get("size", [1800, 1500]))
	var boundary: Dictionary = source.light_boundary
	LIGHT_BOUNDARY = _points(boundary.points)
	LIGHT_FEATHER = float(boundary.feather)
	OUTSIDE_BRIGHTNESS = boundary.outside_brightness.duplicate()
	PLACES = {}
	for id in source.get("places", {}):
		var entry: Dictionary = source.places[id]
		PLACES[id] = {"title": str(entry.get("title", id)), "point": _point(entry.get("point", [0, 0]))}
	ROUTES = []
	for entry in source.get("routes", []):
		var route: Dictionary = entry.duplicate(true)
		route.path = _points(entry.get("path", []))
		route.area = _points(entry.get("area", []))
		ROUTES.append(route)

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _points(values: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for value in values: result.append(_point(value))
	return result

func _valid_source(source: Dictionary) -> bool:
	if not _valid_pair(source.get("size"), Vector2.INF): return false
	var bounds = _point(source["size"])
	if bounds.x <= 0 or bounds.y <= 0: return false
	if not source.get("places") is Dictionary or not source.get("routes") is Array: return false
	var boundary = source.get("light_boundary")
	if not boundary is Dictionary or not boundary.get("points") is Array: return false
	if boundary.points.size() < 3 or boundary.points.size() > 32: return false
	for point in boundary.points:
		if not _valid_pair(point, bounds): return false
	if not (boundary.get("feather") is int or boundary.get("feather") is float): return false
	if not is_finite(float(boundary.feather)) or float(boundary.feather) < 0 or float(boundary.feather) > 80: return false
	if not boundary.get("outside_brightness") is Dictionary: return false
	for state in ["day", "night", "anomaly"]:
		var brightness = boundary.outside_brightness.get(state)
		if not (brightness is int or brightness is float): return false
		if not is_finite(float(brightness)) or float(brightness) < 0 or float(brightness) > 1: return false
	for id in source.places:
		var place = source.places[id]
		if not place is Dictionary or str(place.get("title", "")).is_empty() or not _valid_pair(place.get("point"), bounds): return false
	var route_ids = {}
	for route in source.routes:
		if not route is Dictionary: return false
		var id = str(route.get("id", ""))
		if id.is_empty() or route_ids.has(id) or str(route.get("title", "")).is_empty(): return false
		route_ids[id] = true
		if not route.get("places") is Array or route.places.is_empty(): return false
		for place_id in route.places:
			if not source.places.has(place_id): return false
		for field in ["path", "area"]:
			if not route.get(field) is Array: return false
			var points: Array = route[field]
			if points.size() < (2 if field == "path" else 3) or points.size() > 32: return false
			for point in points:
				if not _valid_pair(point, bounds): return false
		if not Color.html_is_valid(str(route.get("color", ""))): return false
		if str(route.get("campaign_region", "")) not in ["library", "region_b", "region_c"]: return false
	return not source.routes.is_empty()

func _valid_pair(value: Variant, bounds: Vector2) -> bool:
	if not value is Array or value.size() != 2: return false
	for axis in [0, 1]:
		if not (value[axis] is int or value[axis] is float): return false
		if not is_finite(float(value[axis])) or float(value[axis]) < 0: return false
		if bounds != Vector2.INF and float(value[axis]) > bounds[axis]: return false
	return true
