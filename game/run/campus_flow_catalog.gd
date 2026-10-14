extends RefCounted
const PATHS = {"library":"res://resources/campaign/regions/library.tres", "region_b":"res://resources/campaign/regions/region_b.tres", "region_c":"res://resources/campaign/regions/region_c.tres"}

const SPECIAL = {"prologue":"res://resources/campaign/prologue.tres", "finale":"res://resources/campaign/finale.tres"}

static func definition(region: String, usage: String = "region"):
	if not PATHS.has(region): return null
	if usage in SPECIAL: return load(SPECIAL[usage]) if region == "library" else null
	return load(PATHS[region]) if usage == "region" else null

static func snapshot(region: String, usage: String = "region") -> Dictionary:
	var flow = definition(region,usage)
	if not flow is CampusRegionFlow or flow.id != region or flow.usage != usage: return {}
	var errors: Array[String] = flow.validate()
	if not errors.is_empty():
		push_error("校园区域配置："+"；".join(errors))
		return {}
	return flow.snapshot()

## Repair only the shipped revision-1 four-stop layout, keeping opaque visit IDs.
## Custom authored journeys and current snapshots retain their frozen definitions.
static func refresh_legacy_journey(journey, usage: String = "region") -> bool:
	var old: Dictionary = journey.data.get("flow",{})
	var region: String = journey.data.get("region","")
	var old_titles := {"library":"图书馆区域","region_b":"第二终端区域","region_c":"第三终端区域"}
	var old_layers := {"library":[["gate"],["walk","court"],["hall"],["library"]],
		"region_b":[["gate"],["hall","walk"],["court"],["end_b"]],
		"region_c":[["gate"],["court","hall"],["walk"],["end_c"]]}
	if not old_layers.has(region) or old.get("revision") != 1 or old.has("map_contract"): return false
	if old.get("title") != old_titles[region] or old.get("layers") != old_layers[region]: return false
	var gate: Dictionary = old.get("stops",{}).get("gate",{})
	var old_offset: Array = gate.get("offset",[])
	if gate.get("place_id") != "south_gate" or gate.get("landmark") != "stadium" or old_offset.size() != 2: return false
	if Vector2(old_offset[0],old_offset[1]) != Vector2(150,155): return false
	if usage in ["prologue","finale"]:
		if region != "library" or journey.data.step != 0 or not journey.data.visited.is_empty(): return false
		var special := snapshot(region,usage)
		if special.is_empty(): return false
		journey.data.flow = special
		journey.data.map = special.layers.duplicate(true)
		if usage == "finale" and not journey.visit.data.is_empty():
			journey.visit.data.place = "library"
			journey.visit.data.scene_id = preload("res://game/run/place_scenes.gd").entries(special.stops.library)[0].id
		journey.data.map_binding_updated = true
		return true
	var current := snapshot(region)
	if current.is_empty() or current.layers.size() != old.layers.size(): return false
	# Every prior choice remains in its original station; no completed stage repeats.
	for index in old.layers.size():
		for id in old.layers[index]:
			if not current.layers[index].has(id): return false
	for id in current.stops:
		if not old.stops.has(id): continue
		for key in ["power","encounter_id","hotspot_template","scenes","library_interior"]:
			if old.stops[id].has(key): current.stops[id][key] = old.stops[id][key]
	if not preload("res://game/run/campus_flow_rules.gd").validate_snapshot(current,region).is_empty(): return false
	journey.data.flow = current
	journey.data.map = current.layers.duplicate(true)
	journey.data.map_binding_updated = true
	return true
