extends RefCounted
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
const LocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")
## Live layout anchors override old provisional coordinates in saved flow snapshots.
const LEGACY_MAP_ANCHORS = {
	"basic_laboratory_building":["pinxue", Vector2(0,-175), "basic_laboratory_building"],
	"chengdian_auditorium_commercial_street":["main", Vector2(140,-100), "hall"],
	"xuezi_cafeteria":["north", Vector2(-130,95), "cafe_1"],
	"yinhua_halal_cafeterias":["north", Vector2(145,20), "cafe_2"],
	"west_lake_center":["library", Vector2(-170,150), "west_lake"],
	"sports_field":["stadium", Vector2(0,0), "playground"]
}

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
	var config: Dictionary = flow if not flow.is_empty() else Catalog.snapshot(region)
	var place_id: String = config.get("stops",{}).get(place,{}).get("place_id","")
	if not entry.is_empty() and LEGACY_MAP_ANCHORS.has(place_id):
		var old: Array = LEGACY_MAP_ANCHORS[place_id]
		# Correct only the exact old placeholder; authored landmark/offset changes remain valid.
		if entry[2] == old[0] and entry[3] == old[1] and geometry.PLACES.has(old[2]):
			return geometry.PLACES[old[2]].point
	if entry.is_empty() or not geometry.PLACES.has(entry[2]): return Vector2.ZERO
	return (geometry.PLACES[entry[2]].point+entry[3]).clamp(Vector2.ZERO,geometry.SIZE)

static func map_nodes(region: String, geometry, flow: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for layer in range(flow.layers.size()):
		for choice in range(flow.layers[layer].size()):
			var stop: String = flow.layers[layer][choice]
			var entry := binding(region, stop, flow)
			var stop_config: Dictionary = flow.stops[stop]
			var components: Array = stop_config.get("map_landmarks",["hall", "shopping"] if stop_config.get("place_id") == "chengdian_auditorium_commercial_street" else [])
			if components.is_empty():
				result.append({"stop":stop, "layer":layer, "choice":choice, "title":title(region, stop, flow), "landmark":entry[2], "point":point(region, stop, geometry, flow)})
			else:
				for component in components:
					result.append({"stop":stop, "layer":layer, "choice":choice, "title":geometry.PLACES[component].title, "landmark":component, "point":geometry.PLACES[component].point})
	return result

static func component_description(stop: String, geometry, flow: Dictionary) -> String:
	var components: Array = flow.get("stops",{}).get(stop,{}).get("map_landmarks",[])
	if components.size() < 2: return ""
	var names: Array[String] = []
	for component in components:
		if geometry.PLACES.has(component): names.append(geometry.PLACES[component].title)
	return "本次站点包含"+"与".join(names)+"。"
