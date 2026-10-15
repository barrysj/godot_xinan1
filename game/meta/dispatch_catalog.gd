extends RefCounted
## Permanent commissions. Staff are presentation choices, never stat modifiers.
const PREPARATION_POINTS = 4
const PREPARATION_SLOTS = 3
const PREPARATIONS = [
	{"id":"supply", "name":"代码补给", "cost":1, "requires":"departure"},
	{"id":"converter", "name":"代码转换", "cost":1, "requires":"departure"},
	{"id":"shield", "name":"应急护盾", "cost":2, "requires":"shield_kit"},
	{"id":"revive", "name":"复苏装置", "cost":3, "requires":"revive_kit"},
]
const MAP_DATA_PATH = "res://game/meta/dispatch_map.json"
static var DATA: Dictionary = _read_data()
static var COMMISSIONS: Array = DATA.get("commissions", [])

static func _read_data() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MAP_DATA_PATH))
	if not parsed is Dictionary or parsed.get("schema") != 1 or not parsed.get("places") is Array or not parsed.get("commissions") is Array or not parsed.get("maps") is Dictionary:
		push_error("Dispatch map data is invalid: "+MAP_DATA_PATH)
		return {}
	return parsed

static func places() -> Array:
	var result: Array = []
	for entry in DATA.get("places", []):
		var place: Dictionary = entry.duplicate(true)
		place.point = Vector2(float(entry.point[0]), float(entry.point[1]))
		result.append(place)
	return result

static func has_preparation(unlocks: Array, item: Dictionary) -> bool:
	if unlocks.has(item.requires): return true
	for id in unlocks:
		var effect := find(id)
		if effect.get("kind") == "preparation" and effect.get("value") == item.id: return true
	return false


static func find(id: String) -> Dictionary:
	for item in COMMISSIONS:
		if item.id == id: return item
	return {}

static func at_location(location: String) -> Array:
	return COMMISSIONS.filter(func(item): return item.location == location and item.get("enabled", true))

static func preparation_reason(unlocks: Array, selected: Array) -> String:
	var points := 0
	if not unlocks.has("departure"): return "尚未开放出发准备"
	if selected.size() > PREPARATION_SLOTS: return "携带格子不足"
	for id in selected:
		var found := false
		for item in PREPARATIONS:
			if item.id != id: continue
			found = true
			if not has_preparation(unlocks, item): return "物品尚未进入准备池"
			points += int(item.cost)
		if not found: return "未知准备物品"
	if points > PREPARATION_POINTS: return "准备点数不足"
	return ""
