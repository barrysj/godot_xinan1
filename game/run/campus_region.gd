extends RefCounted
## Existing hotspot templates; physical places and route stops are separate resources.
const PLACES = {
	"gate":"校门", "walk":"步道", "court":"球场",
	"hall":"走廊", "library":"图书馆", "end_b":"第二终端",
	"end_c":"第三终端"}
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
const IDS = ["library","region_b","region_c"]

static func map_for(region: String) -> Array:
	return Catalog.snapshot(region).get("layers",[]).duplicate(true)

static func flow_for(region: String) -> Dictionary:
	return Catalog.snapshot(region)

static func hotspots(place: String, level: int, recorded: Array, seed_value: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var memories = [place + "_system_1", place + "_system_2"]
	var unseen = memories.filter(func(id): return not recorded.has(id))
	var pool = unseen if not unseen.is_empty() else memories
	var memory = pool[rng.randi_range(0,pool.size()-1)]
	var result = [{"id":"guard", "kind":"battle"},
		{"id":memory, "kind":"memory"}]
	if place == "library" or level >= 1:
		result.append({"id":"person", "kind":"person", "character":"inventor"})
	if place == "library" or level >= 2:
		result.append({"id":"system", "kind":"system"})
	return result
