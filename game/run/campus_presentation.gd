extends RefCounted
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
const LocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")

static func binding(region: String, place: String, flow: Dictionary = {}) -> Array:
	var config: Dictionary = flow if not flow.is_empty() else Catalog.snapshot(region)
	var entry: Dictionary = config.get("stops",{}).get(place,{})
	if entry.is_empty(): return []
	return [entry.background,entry.title,entry.landmark,Vector2(entry.offset[0],entry.offset[1])]

static func title(region: String, place: String, flow: Dictionary = {}) -> String:
	var entry := binding(region,place,flow)
	return str(entry[1]) if not entry.is_empty() else place

static func background(region: String, place: String, state: String = "anomaly", flow: Dictionary = {}) -> String:
	var entry := binding(region,place,flow)
	return LocationSkin.path(str(entry[0]),state) if not entry.is_empty() else ""

static func point(region: String, place: String, geometry, flow: Dictionary = {}) -> Vector2:
	var entry := binding(region,place,flow)
	if entry.is_empty() or not geometry.PLACES.has(entry[2]): return Vector2.ZERO
	return (geometry.PLACES[entry[2]].point+entry[3]).clamp(Vector2.ZERO,geometry.SIZE)
