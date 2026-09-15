extends RefCounted
const Regions = preload("res://game/run/campus_region.gd")
const Visit = preload("res://game/run/location_visit.gd")
var data: Dictionary = {}
var visit = Visit.new()

func begin(region: String, level: int) -> bool:
	if not Regions.MAPS.has(region): return false
	data = {"schema":1,"id":Crypto.new().generate_random_bytes(16).hex_encode(),
		"region":region,"level":level,"map":Regions.map_for(region),"step":0,
		"visited":[],"temporary":[],"finished":false,"screen":"route"}
	visit = Visit.new()
	return true

func enter(index: int, recorded: Array) -> bool:
	if data.finished or not visit.data.is_empty(): return false
	var layer: Array = data.map[data.step]
	if index < 0 or index >= layer.size(): return false
	var place: String = layer[index]
	visit.begin(place,data.level,recorded,(data.id+place).hash())
	data.screen = "visit"
	return true

func leave() -> bool:
	if not visit.can_leave(): return false
	data.visited.append(visit.data.place)
	data.step += 1
	data.finished = data.step == data.map.size()
	data.screen = "complete" if data.finished else "route"
	visit = Visit.new()
	return true

func snapshot() -> Dictionary:
	var result = data.duplicate(true)
	result.visit = visit.data.duplicate(true)
	return result

func restore(source: Variant) -> bool:
	if not source is Dictionary or source.get("schema") != 1: return false
	if not source.get("id") is String or source.id.is_empty(): return false
	if not Regions.MAPS.has(source.get("region")): return false
	if source.get("map") != Regions.map_for(source.region): return false
	for key in ["level", "step"]:
		var value = source.get(key)
		if not (value is int or value is float) or int(value) != value: return false
	if source.level < 0 or source.level > 3 or source.step < 0 or source.step > source.map.size(): return false
	if not source.get("finished") is bool or source.finished != (source.step == source.map.size()): return false
	if not source.get("visited") is Array or source.visited.size() != source.step: return false
	for i in range(source.visited.size()):
		if not source.map[i].has(source.visited[i]): return false
	if not source.get("temporary") is Array: return false
	for id in source.temporary:
		if id != "inventor": return false
	if not source.get("screen") in ["route","visit","battle","report","reward","operation","complete"]: return false
	if source.screen == "report" and not source.get("won") is bool: return false
	if source.screen == "report":
		if not source.get("report",[]) is Array: return false
		for row in source.get("report",[]):
			if not row is Dictionary or not row.get("name") is String: return false
			for key in ["damage","healing"]:
				if not (row.get(key) is int or row.get(key) is float): return false
		if not (source.get("elapsed",0) is int or source.get("elapsed",0) is float): return false
	if source.has("offers"):
		if not source.offers is Array or source.offers.is_empty() or source.offers.size() > 3: return false
		for offer in source.offers:
			if not preload("res://game/run/reward_catalog.gd").valid_snapshot(offer): return false
	if source.screen == "reward" and not source.has("offers"): return false
	if not source.get("visit") is Dictionary: return false
	var restored = Visit.new()
	if not source.visit.is_empty():
		if source.finished or not restored.restore(source.visit): return false
		if not source.map[int(source.step)].has(source.visit.place): return false
	if (source.screen in ["visit","battle","report","reward","operation"]) != (not source.visit.is_empty()): return false
	if (source.screen == "complete") != source.finished: return false
	if source.screen in ["reward","operation"] and not restored.data.guard_won: return false
	data = source.duplicate(true)
	data.erase("visit")
	data.schema = 1
	data.step = int(data.step)
	data.level = int(data.level)
	visit = restored
	return true
