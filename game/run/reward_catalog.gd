extends RefCounted
const DB = preload("res://game/content/content_db.gd")

static func find(id: String) -> Dictionary:
	for item in DB.MANIFEST.rewards:
		if item.id == id: return item.snapshot()
	return {}

static func allowed(entry: Dictionary, roster: Array, inventory: Dictionary, training: Dictionary = {}) -> bool:
	match entry.get("operation"):
		"combat": return find_combat(str(entry.get("target", ""))) != null
		"gear": return DB.gear(entry.target) != null and not inventory.has(entry.target)
		"recruit": return DB.role_index(entry.target) >= 0 and not roster.has(DB.role_index(entry.target))
		"train": return roster.has(DB.role_index(entry.target)) and int(training.get(DB.role_index(entry.target),0)) + entry.amount <= 100
		"points": return true
	return false

static func eligible(_badge_owned: bool, roster: Array, inventory: Dictionary = {}, pool_id: String = "campus_rewards", training: Dictionary = {}, combat_rewards: Array = []) -> Array:
	var result = []
	for pool in DB.MANIFEST.reward_pools:
		if pool.id != pool_id: continue
		for reward in pool.rewards:
			var entry = reward.snapshot()
			if allowed(entry,roster,inventory,training): result.append(entry)
	for reward in preload("res://resources/combat/manifest.tres").rewards:
		var entry := {"id":"combat_"+reward.id,"title":reward.display_name,"description":reward.description,"operation":"combat","target":reward.id,"amount":1}
		if reward.character_id.is_empty() or DB.role_index(reward.character_id) >= 0 and roster.has(DB.role_index(reward.character_id)):
			if not combat_rewards.any(func(saved): return saved.get("target", "") == reward.id): result.append(entry)
	return result

static func find_combat(id: String) -> Resource:
	for reward in preload("res://resources/combat/manifest.tres").rewards:
		if reward.id == id: return reward
	return null

static func combat_needs_owner(id: String) -> bool:
	return id in ["training", "lens", "backup"]

static func combat_owner_valid(id: String, owner_id: String, roster_ids: Array) -> bool:
	if not combat_needs_owner(id): return owner_id.is_empty()
	return DB.role_index(owner_id) >= 0 and roster_ids.has(owner_id)

static func valid_snapshot(entry) -> bool:
	if not entry is Dictionary or not entry.get("id") is String: return false
	if entry.get("operation") == "combat":
		if not entry.get("target") is String or find_combat(entry.target) == null or entry.id != "combat_"+entry.target: return false
	elif find(entry.id).is_empty(): return false
	if not entry.get("title") is String or not entry.get("description") is String or not entry.get("target") is String: return false
	var amount = entry.get("amount")
	if not (amount is int or amount is float) or not is_finite(amount) or int(amount) != amount or amount < 1 or amount > 100: return false
	match entry.get("operation"):
		"combat": return entry.target is String and find_combat(entry.target) != null and entry.id == "combat_"+entry.target and entry.amount == 1
		"gear": return DB.gear(entry.target) != null
		"recruit", "train": return DB.role_index(entry.target) >= 0
		"points": return true
	return false
