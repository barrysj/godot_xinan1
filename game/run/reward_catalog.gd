extends RefCounted
const DB = preload("res://game/content/content_db.gd")

static func find(id: String) -> Dictionary:
	for item in DB.MANIFEST.rewards:
		if item.id == id: return item.snapshot()
	return {}

static func allowed(entry: Dictionary, roster: Array, inventory: Dictionary, training: Dictionary = {}) -> bool:
	match entry.get("operation"):
		"gear": return DB.gear(entry.target) != null and not inventory.has(entry.target)
		"recruit": return DB.role_index(entry.target) >= 0 and not roster.has(DB.role_index(entry.target))
		"train": return roster.has(DB.role_index(entry.target)) and int(training.get(DB.role_index(entry.target),0)) + entry.amount <= 100
		"points": return true
	return false

static func eligible(_badge_owned: bool, roster: Array, inventory: Dictionary = {}, pool_id: String = "campus_rewards", training: Dictionary = {}) -> Array:
	var result = []
	for pool in DB.MANIFEST.reward_pools:
		if pool.id != pool_id: continue
		for reward in pool.rewards:
			var entry = reward.snapshot()
			if allowed(entry,roster,inventory,training): result.append(entry)
	return result

static func valid_snapshot(entry) -> bool:
	if not entry is Dictionary or not entry.get("id") is String or find(entry.id).is_empty(): return false
	if not entry.get("title") is String or not entry.get("description") is String or not entry.get("target") is String: return false
	var amount = entry.get("amount")
	if not (amount is int or amount is float) or not is_finite(amount) or int(amount) != amount or amount < 1 or amount > 100: return false
	match entry.get("operation"):
		"gear": return DB.gear(entry.target) != null
		"recruit", "train": return DB.role_index(entry.target) >= 0
		"points": return true
	return false
