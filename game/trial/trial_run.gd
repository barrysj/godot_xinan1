extends RefCounted
const Catalog = preload("res://game/trial/trial_catalog.gd")
var formation: Array = [0, -1, -1, 2, 1, 3]
var battle := 0
var phase := "prepare"
var rewards: Array = []
var gear: Dictionary = {}
var trainee := -1
var unlocked := false
var report := ""
var path := "user://synergy_trial_v1.json"

func snapshot() -> Dictionary:
	return {"version": 1, "formation": formation.duplicate(), "battle": battle, "phase": phase,
		"rewards": rewards.duplicate(), "gear": gear.duplicate(), "trainee": trainee, "unlocked": unlocked, "report": report}

func restore(data) -> bool:
	if not data is Dictionary or data.get("version") != 1: return false
	var f = data.get("formation")
	if not f is Array or f.size() != 6: return false
	var used := []
	for id in f:
		if not _integer(id, -1, 5): return false
		if id >= 0:
			if used.has(id): return false
			used.append(id)
	if used.size() > 4: return false
	if not _integer(data.get("battle"), 0, 2) or not data.get("phase") in ["prepare", "reward", "complete"]: return false
	if not data.get("rewards") is Array or not data.get("gear") is Dictionary: return false
	if not data.get("unlocked") is bool or not data.get("report") is String: return false
	if not _integer(data.get("trainee"), -1, 5): return false
	var seen := []
	for reward in data.rewards:
		if not reward is String or not Catalog.REWARDS.has(reward) or seen.has(reward): return false
		seen.append(reward)
	var equipped := []
	for item in data.gear:
		if not item in ["lens", "backup"] or not data.rewards.has(item): return false
		var owner = data.gear[item]
		if not _integer(owner, -1, 5): return false
		if owner >= 0 and equipped.has(owner): return false
		if owner >= 0: equipped.append(owner)
	if data.rewards.has("training") != (data.trainee >= 0): return false
	if data.phase == "reward" and data.battle >= 2: return false
	if data.phase == "complete" and (data.battle != 2 or not data.unlocked): return false
	formation = f.map(func(value): return int(value))
	battle = int(data.battle)
	phase = data.phase
	rewards = data.rewards.duplicate()
	gear = data.gear.duplicate()
	trainee = int(data.trainee)
	unlocked = data.unlocked
	report = data.report
	return true

func _integer(value, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(value) and value == int(value) and value >= low and value <= high

func read_save() -> bool:
	if not FileAccess.file_exists(path): return true
	var file = FileAccess.open(path, FileAccess.READ)
	return file != null and restore(JSON.parse_string(file.get_as_text()))

func save() -> bool:
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(snapshot()))
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK: return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func assign(role: int, slot: int) -> bool:
	if phase != "prepare" or role < 0 or role > 5 or slot < 0 or slot > 5: return false
	var previous = formation.find(role)
	if previous < 0 and formation[slot] < 0 and formation.count(-1) <= 2: return false
	if previous >= 0: formation[previous] = formation[slot]
	formation[slot] = role
	return true

func equip(item: String, owner: int) -> bool:
	if phase != "prepare" or not item in ["lens", "backup"] or not rewards.has(item) or owner < -1 or owner > 5: return false
	for other in gear:
		if owner >= 0 and gear[other] == owner: gear[other] = -1
	gear[item] = owner
	return true

func options() -> Array:
	return ["cover", "lens", "training"] if battle == 0 else ["verify", "pierce", "backup"]

func select_reward(id: String, owner: int = -1) -> bool:
	if phase != "reward" or not options().has(id) or rewards.has(id): return false
	if id == "training" and (owner < 0 or owner > 5): return false
	rewards.append(id)
	if id in ["lens", "backup"]: gear[id] = -1
	if id == "training": trainee = owner
	battle += 1
	phase = "prepare"
	return true

func finish(won: bool, summary: String) -> void:
	report = summary
	phase = "prepare" if not won else ("reward" if battle < 2 else "complete")
	if phase == "complete": unlocked = true

func restart(supply: String = "") -> void:
	battle = 0
	phase = "prepare"
	formation = [0, -1, -1, 2, 1, 3]
	rewards = ["lens"] if unlocked and supply == "lens" else []
	gear = {"lens": 1} if not rewards.is_empty() else {}
	trainee = -1
	report = ""
