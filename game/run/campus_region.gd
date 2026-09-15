extends RefCounted
## Logical placeholder geography; shared place IDs are not a real campus map.
const PLACES = {
	"gate":"校门〔占位〕", "walk":"步道〔占位〕", "court":"球场〔占位〕",
	"hall":"走廊〔占位〕", "library":"图书馆", "end_b":"终点乙〔待资料〕",
	"end_c":"终点丙〔待资料〕"}
const MAPS = {
	"library":[["gate"],["walk","court"],["hall"],["library"]],
	"region_b":[["gate"],["hall","walk"],["court"],["end_b"]],
	"region_c":[["gate"],["court","hall"],["walk"],["end_c"]]}
const NAMES = {"library":"图书馆区域", "region_b":"区域乙〔占位〕", "region_c":"区域丙〔占位〕"}

static func map_for(region: String) -> Array:
	return MAPS.get(region, []).duplicate(true)

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
