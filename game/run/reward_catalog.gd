extends RefCounted
const DB = preload("res://game/content/content_db.gd")
const Codes = preload("res://game/combat/code_catalog.gd")

static func find(id: String) -> Dictionary:
	for item in DB.MANIFEST.rewards:
		if item.id == id: return item.snapshot()
	return {}

static func allowed(entry: Dictionary, roster: Array, inventory: Dictionary, training: Dictionary = {}, code_stock: Variant = null) -> bool:
	match entry.get("operation"):
		"combat": return find_combat(str(entry.get("target", ""))) != null
		"gear": return DB.gear(entry.target) != null and not inventory.has(entry.target)
		"recruit": return DB.role_index(entry.target) >= 0 and not roster.has(DB.role_index(entry.target))
		"train": return roster.has(DB.role_index(entry.target)) and int(training.get(DB.role_index(entry.target),0)) + entry.amount <= 100
		"points": return true
		"item": return Codes.item(str(entry.get("target",""))) != null and Codes.valid_stock(code_stock) and int(code_stock.get(entry.target,0))+int(entry.amount) <= Codes.STOCK_CAP
	return false

static func eligible(_badge_owned: bool, roster: Array, inventory: Dictionary = {}, pool_id: String = "campus_rewards", training: Dictionary = {}, combat_rewards: Array = [], programs: Variant = null, code_stock: Variant = null) -> Array:
	var result = []
	for pool in DB.MANIFEST.reward_pools:
		if pool.id != pool_id: continue
		for reward in pool.rewards:
			var entry = reward.snapshot()
			if allowed(entry,roster,inventory,training,code_stock): result.append(entry)
	for reward in preload("res://resources/combat/manifest.tres").rewards:
		if roster.is_empty() or combat_rewards.any(func(saved): return saved.get("target", "") == reward.id): continue
		if not reward.character_id.is_empty() and not roster.has(DB.role_index(reward.character_id)): continue
		if reward.category == "装备" and not roster.any(func(role): return equipment_owner_available(role,inventory,combat_rewards)): continue
		if reward.category == "程序" and programs != null and not programs.has(reward.program_id): continue
		if not reward.required_tag.is_empty() and tag_count(roster,reward.required_tag) < reward.required_tag_count: continue
		result.append({"id":"combat_"+reward.id,"title":reward.display_name,"description":reward.description,"operation":"combat","target":reward.id,"amount":1})
	return result

## New offers use the current build; persisted offers remain frozen in their checkpoint.
static func for_build(build, pool_id: String = "campus_rewards") -> Array:
	var pool := eligible(build.badge_owned,build.roster,build.inventory,pool_id,build.training,build.combat_rewards,build.code_programs,build.code_supplies if build.growth_rules >= 2 else null)
	if build.growth_rules < 2: return pool
	for definition in DB.MANIFEST.rewards:
		if definition.operation != "item" or not build.dispatch_items.has(definition.code_item_id): continue
		var entry: Dictionary = definition.snapshot()
		if allowed(entry,build.roster,build.inventory,build.training,build.code_supplies) and not pool.any(func(existing): return existing.id == entry.id): pool.append(entry)
	var result: Array = []
	for entry in pool:
		if build.expedition_party and entry.operation == "recruit": continue
		if entry.operation == "train":
			if not build.can_train(DB.role_index(entry.target),int(entry.amount)): continue
			entry.description = "本局生命 +10%、攻击 +8%。每人最多两份，集中训练计入；按基础属性相加。"
		elif entry.operation == "gear": entry.description = build.gear_definition(entry.target).description
		elif entry.operation == "combat" and entry.target == "training":
			if not build.roster.any(func(role): return build.can_train(role)): continue
			entry.description += "每人最多两份，普通训练计入；按基础属性相加。"
		result.append(entry)
	return result

static func equipment_owner_available(role: int, inventory: Dictionary, combat_rewards: Array) -> bool:
	if inventory.values().has(role): return false
	var owner_id: String = DB.role_id(role)
	return not combat_rewards.any(func(saved): return saved.get("target", "") in ["lens", "backup"] and saved.get("owner", "") == owner_id)

static func tag_count(roster: Array, tag: String) -> int:
	var result := 0
	var seen: Array = []
	for role in roster:
		if seen.has(role): continue
		seen.append(role)
		for character in preload("res://resources/combat/manifest.tres").characters:
			if character.id == DB.role_id(role) and character.tags.has(tag): result += 1
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
	if entry.has("offer_slot") and entry.offer_slot not in ["chain","general","alternative"]: return false
	var amount = entry.get("amount")
	if not (amount is int or amount is float) or not is_finite(amount) or int(amount) != amount or amount < 1 or amount > 100: return false
	match entry.get("operation"):
		"combat": return entry.target is String and find_combat(entry.target) != null and entry.id == "combat_"+entry.target and entry.amount == 1
		"gear": return DB.gear(entry.target) != null
		"recruit", "train": return DB.role_index(entry.target) >= 0
		"points": return true
		"item": return find(entry.id).operation == "item" and find(entry.id).target == entry.target and entry.amount == 1 and Codes.item(entry.target) != null
	return false

static func fallback_only(entry: Dictionary) -> bool:
	for definition in DB.MANIFEST.rewards:
		if definition.id == entry.id: return definition.fallback_only
	return false

static func entry_chain(entry: Dictionary) -> String:
	return find_combat(entry.target).reward_chain if entry.operation == "combat" else "general"

static func weight(entry: Dictionary) -> int:
	return find_combat(entry.target).reward_weight if entry.operation == "combat" else 2

static func weighted_pick(pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	if pool.is_empty(): return {}
	var total := 0
	for entry in pool: total += weight(entry)
	var roll: int = rng.randi_range(0,total-1)
	for entry in pool:
		roll -= weight(entry)
		if roll < 0: return entry
	return {}

static func active_chains(build) -> Array[String]:
	var active: Array = build.formation.filter(func(role): return role >= 0 and build.roster.has(role))
	var result: Array[String] = []
	for synergy in preload("res://resources/combat/manifest.tres").synergies:
		if tag_count(active,synergy.id) < synergy.required_count: continue
		if synergy.id == "analysis" and not active.has(DB.role_index("analyst")) and not build.combat_rewards.any(func(saved): return saved.get("target", "") == "lens" and active.has(DB.role_index(saved.get("owner", "")))): continue
		result.append(synergy.id)
	return result

static func adaptive_recruits(build) -> Array[String]:
	var result: Array[String] = []
	for chain in active_chains(build):
		for id in (["inventor","analyst"] if chain == "protect" else ["morning","healer"]):
			if not result.has(id): result.append(id)
	return result

static func _add_pick(remaining: Array, candidates: Array, rng: RandomNumberGenerator, offers: Array, slot: String) -> void:
	var picked: Dictionary = weighted_pick(candidates,rng)
	if picked.is_empty(): return
	remaining.erase(picked)
	var frozen: Dictionary = picked.duplicate(true)
	frozen.offer_slot = slot
	offers.append(frozen)

static func draw_for_build(build, rng: RandomNumberGenerator, offer_number: int, allow_recruits: bool = true, pool_id: String = "campus_rewards", excluded_ids: Array = []) -> Array:
	var pool: Array = for_build(build,pool_id).filter(func(entry): return not excluded_ids.has(entry.id) and (allow_recruits or entry.operation != "recruit") and (entry.operation != "combat" or find_combat(entry.target).minimum_offer <= offer_number))
	if pool.filter(func(entry): return not fallback_only(entry)).size() >= 3: pool = pool.filter(func(entry): return not fallback_only(entry))
	var offers: Array = []
	var chains: Array[String] = active_chains(build).filter(func(chain): return pool.any(func(entry): return entry_chain(entry) == chain))
	if not chains.is_empty():
		# Pick a chain first so a longer content list does not bias dual-chain formations.
		var chain: String = chains[rng.randi_range(0,chains.size()-1)]
		_add_pick(pool,pool.filter(func(entry): return entry_chain(entry) == chain),rng,offers,"chain")
	else:
		var general: Array = pool.filter(func(entry): return entry_chain(entry) == "general" and entry.operation != "recruit")
		_add_pick(pool,general if not general.is_empty() else pool,rng,offers,"general" if not general.is_empty() else "alternative")
	var general: Array = pool.filter(func(entry): return entry_chain(entry) == "general" and entry.operation != "recruit")
	_add_pick(pool,general if not general.is_empty() else pool,rng,offers,"general" if not general.is_empty() else "alternative")
	var recruits: Array = pool.filter(func(entry): return entry.operation == "recruit" and adaptive_recruits(build).has(entry.target))
	_add_pick(pool,recruits if offer_number >= 2 and not build.candidate_recruit_shown and not recruits.is_empty() else pool,rng,offers,"alternative")
	return offers
