extends RefCounted
const Regions = preload("res://game/run/campus_region.gd")
var data: Dictionary = {}

func begin(place: String, level: int, recorded: Array, seed_value: int) -> void:
	data = {"place":place, "hotspots":Regions.hotspots(place,level,recorded,seed_value),
		"viewed":[], "guard_won":false, "reward_taken":false}

func view(id: String) -> bool:
	for spot in data.hotspots:
		if spot.id == id and spot.kind != "battle":
			if not data.viewed.has(id): data.viewed.append(id)
			return true
	return false

func can_leave() -> bool:
	return data.get("guard_won", false) and data.get("reward_taken", false)

func restore(source: Variant) -> bool:
	if not source is Dictionary or not Regions.PLACES.has(source.get("place")): return false
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
	data = source.duplicate(true)
	return true
