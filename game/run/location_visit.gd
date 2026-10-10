extends RefCounted
const Regions = preload("res://game/run/campus_region.gd")
var data: Dictionary = {}

func begin(place: String, level: int, recorded: Array, seed_value: int, hotspot_template: String = "") -> void:
	data = {"place":place, "hotspots":Regions.hotspots(place if hotspot_template.is_empty() else hotspot_template,level,recorded,seed_value),
		"event_states":{}, "viewed":[], "guard_won":false, "reward_taken":false}

func view(id: String) -> bool:
	for spot in data.hotspots:
		if spot.id == id and spot.kind != "battle":
			if not data.viewed.has(id): data.viewed.append(id)
			return true
	return false

func can_leave() -> bool:
	return data.get("guard_won", false) and data.get("reward_taken", false)

func restore(source: Variant, allowed_stops: Array = []) -> bool:
	if not source is Dictionary: return false
	if source.get("place") not in (Regions.PLACES.keys() if allowed_stops.is_empty() else allowed_stops): return false
	if not source.get("hotspots") is Array or source.hotspots.size() < 2 or source.hotspots.size() > 4: return false
	if not source.get("viewed") is Array: return false
	for key in ["guard_won","reward_taken"]:
		if not source.get(key) is bool: return false
	if source.reward_taken and not source.guard_won: return false
	var ids = []
	var guards = 0
	for spot in source.hotspots:
		if not spot is Dictionary or not spot.get("id") is String or ids.has(spot.id): return false
		if not spot.get("kind") in ["battle","memory","person","system"]: return false
		if spot.kind == "battle": guards += 1
		ids.append(spot.id)
	if guards != 1: return false
	var viewed = []
	for id in source.viewed:
		if not ids.has(id) or viewed.has(id) or id == "guard": return false
		viewed.append(id)
	var states: Variant = source.get("event_states",{})
	if not states is Dictionary or states.size() > 3: return false
	for id in states:
		var matching: Array = source.hotspots.filter(func(spot): return spot.id == id and spot.kind != "battle")
		if matching.size() != 1 or not preload("res://game/run/hotspot_event.gd").valid_state(states[id],matching[0]): return false
	data = source.duplicate(true)
	data.event_states = states.duplicate(true)
	return true
