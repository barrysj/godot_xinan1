extends RefCounted
const Regions = preload("res://game/run/campus_region.gd")
const Visit = preload("res://game/run/location_visit.gd")
const FlowRules = preload("res://game/run/campus_flow_rules.gd")
const PlaceScenes = preload("res://game/run/place_scenes.gd")
var data: Dictionary = {}
var visit = Visit.new()

func begin(region: String, level: int, definition: Resource = null) -> bool:
	if definition != null and (not definition is CampusRegionFlow or definition.id != region or not definition.validate().is_empty()): return false
	var flow: Dictionary = Regions.flow_for(region) if definition == null else definition.snapshot()
	if flow.is_empty(): return false
	data = {"schema":2,"id":Crypto.new().generate_random_bytes(16).hex_encode(),
		"region":region,"level":level,"flow":flow,"map":flow.layers.duplicate(true),"step":0,
		"visited":[],"temporary":[],"finished":false,"screen":"route"}
	visit = Visit.new()
	return true

func enter(index: int, recorded: Array) -> bool:
	if data.finished or not visit.data.is_empty(): return false
	var layer: Array = data.map[data.step]
	if index < 0 or index >= layer.size(): return false
	var place: String = layer[index]
	visit.begin(place,data.level,recorded,(data.id+place).hash(),str(stop(place).hotspot_template))
	visit.data.scene_id = PlaceScenes.entries(stop(place))[0].id
	data.screen = "visit"
	return true

func leave() -> bool:
	if not visit.can_leave(): return false
	data.erase("event_spot")
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

func stop(id: String = "") -> Dictionary:
	if id.is_empty(): id = str(visit.data.get("place",""))
	return data.get("flow",{}).get("stops",{}).get(id,{})

func title(id: String) -> String:
	return str(stop(id).get("title",id))

func is_library() -> bool:
	return bool(stop().get("library_interior",false))

func current_scene() -> Dictionary:
	return PlaceScenes.find(stop(),str(visit.data.get("scene_id",PlaceScenes.entries(stop())[0].id)))

func switch_scene(id: String) -> bool:
	if data.get("screen") != "visit" or visit.data.is_empty() or PlaceScenes.find(stop(),id).is_empty(): return false
	visit.data.scene_id = id
	return true

func passage() -> Dictionary:
	if visit.data.is_empty(): return {}
	var scenes: Array = PlaceScenes.entries(stop())
	var current := str(current_scene().get("id",""))
	for i in range(scenes.size()):
		if scenes[i].id != current: continue
		if i+1 < scenes.size():
			return {"action":"scene:"+scenes[i+1].id,"title":scenes[i+1].title,"enabled":data.get("screen") == "visit","hint":"前往"+scenes[i+1].title}
		var enabled: bool = data.get("screen") == "visit" and visit.can_leave()
		var final_stop: bool = int(data.step) == data.map.size()-1
		return {"action":"leave","title":"区域出口" if final_stop else "路线图","enabled":enabled,
			"hint":("离开地点，完成区域探索" if final_stop else "离开地点，返回路线图") if enabled else "出口封锁 · 战胜守卫并领取奖励"}
	return {}

func restore(source: Variant) -> bool:
	if not source is Dictionary or source.get("schema") != 2: return false
	if not source.get("id") is String or source.id.is_empty(): return false
	if source.get("region") not in Regions.IDS: return false
	if not FlowRules.validate_snapshot(source.get("flow"),source.region).is_empty(): return false
	if source.get("map") != source.flow.layers: return false
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
	if not source.get("screen") in ["route","visit","event","battle","report","reward","reward_owner","operation","complete"]: return false
	if source.screen == "report" and not source.get("won") is bool: return false
	if source.screen == "report":
		if not source.get("report",[]) is Array: return false
		for row in source.get("report",[]):
			if not row is Dictionary or not row.get("name") is String: return false
			for key in ["damage","healing"]:
				if not (row.get(key) is int or row.get(key) is float): return false
		if not (source.get("elapsed",0) is int or source.get("elapsed",0) is float): return false
	if not source.get("rewards_exhausted",false) is bool: return false
	if source.get("rewards_exhausted",false) and (not source.has("offers") or not source.offers is Array or not source.offers.is_empty()): return false
	if source.has("offers"):
		if not source.offers is Array or (source.offers.is_empty() and not source.get("rewards_exhausted",false)) or source.offers.size() > 3: return false
		for offer in source.offers:
			if not preload("res://game/run/reward_catalog.gd").valid_snapshot(offer): return false
	if source.screen == "reward" and not source.has("offers"): return false
	if source.screen == "reward_owner":
		if not source.has("pending_offer") or not preload("res://game/run/reward_catalog.gd").valid_snapshot(source.pending_offer) or source.pending_offer.operation != "combat" or not preload("res://game/run/reward_catalog.gd").combat_needs_owner(source.pending_offer.target): return false
		if not source.get("offers", []).any(func(offer): return offer.id == source.pending_offer.id): return false
	if not source.get("visit") is Dictionary: return false
	var restored = Visit.new()
	if not source.visit.is_empty():
		if source.finished or not restored.restore(source.visit,source.map[int(source.step)]): return false
		if not source.map[int(source.step)].has(source.visit.place): return false
		var place: Dictionary = source.flow.stops[source.visit.place]
		var scene_id: Variant = source.visit.get("scene_id",PlaceScenes.entries(place)[0].id)
		if not scene_id is String or PlaceScenes.find(place,scene_id).is_empty(): return false
		restored.data.scene_id = scene_id
	if (source.screen in ["visit","event","battle","report","reward","reward_owner","operation"]) != (not source.visit.is_empty()): return false
	if (source.screen == "complete") != source.finished: return false
	if source.screen in ["reward","reward_owner","operation"] and not restored.data.guard_won: return false
	if source.get("rewards_exhausted",false) and (restored.data.is_empty() or not restored.data.guard_won or source.screen not in ["reward","visit","event"]): return false
	if source.screen == "event":
		if not source.get("event_spot") is String or not restored.data.event_states.has(source.event_spot): return false
		if restored.data.event_states[source.event_spot].closed: return false
	data = source.duplicate(true)
	data.erase("visit")
	data.schema = 2
	data.flow.schema = 1
	data.flow.revision = int(data.flow.revision)
	for place in data.flow.stops.values():
		for scene in place.get("scenes",[]): scene.floor = int(scene.floor)
	data.step = int(data.step)
	data.level = int(data.level)
	visit = restored
	return true
