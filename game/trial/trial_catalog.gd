extends RefCounted
## Resource registry; preserve legacy role order for existing save indices.
const MANIFEST = preload("res://resources/trial/manifest.tres")
const AutoBattle = preload("res://game/combat/auto_battle.gd")
static var CONTENT_ERRORS: Array[String] = preload("res://game/trial/trial_content_validator.gd").validate(MANIFEST)
static var ROLES: Array = MANIFEST.characters.map(func(c): return c.id) if CONTENT_ERRORS.is_empty() else []
static var NAMES: Array = MANIFEST.characters.map(func(c): return c.display_name) if CONTENT_ERRORS.is_empty() else []
static var DESCRIPTIONS: Array = MANIFEST.characters.map(func(c): return c.description) if CONTENT_ERRORS.is_empty() else []
static var TAGS: Array = MANIFEST.characters.map(func(c): return c.tags.map(func(id): return synergy(id).display_name)) if CONTENT_ERRORS.is_empty() else []
static var TRAITS: Dictionary = _traits()
static var REWARDS: Dictionary = _rewards()
static var BATTLES: Array = MANIFEST.encounters.map(func(e): return {"id":e.id, "name":e.display_name, "hint":e.description, "pulse":e.pulse_interval, "shield":e.pulse_shield, "rewards":Array(e.reward_ids)}) if CONTENT_ERRORS.is_empty() else []
static var _definitions: Array = []

static func _traits() -> Dictionary:
	var result := {}
	if not CONTENT_ERRORS.is_empty(): return result
	for s in MANIFEST.synergies: result[s.display_name] = s.description
	return result

static func _rewards() -> Dictionary:
	var result := {}
	if not CONTENT_ERRORS.is_empty(): return result
	var types = {"羁绊":"trait", "装备":"equipment", "训练":"training", "专属":"exclusive"}
	for r in MANIFEST.rewards:
		result[r.id] = {"name":r.display_name, "kind":r.category, "text":r.description, "reward_type":types.get(r.category,"trait"), "character_id":r.character_id, "definition":r}
	return result

static func synergy(id: String):
	for s in MANIFEST.synergies:
		if s.id == id: return s
	return null

static func reward(id: String):
	for r in MANIFEST.rewards:
		if r.id == id: return r
	return null

static func definition(index: int):
	if _definitions.is_empty():
		for c in MANIFEST.characters:
			var d = c.unit.duplicate(true)
			d.id = c.id
			d.display_name = c.display_name
			d.description = c.description
			for stat in c.stats: d.set(stat, c.stats[stat])
			if c.skill_override != null: d.skill = c.skill_override
			_definitions.append(d)
	return _definitions[index]

static func active_tag_ids(formation: Array) -> Array[String]:
	var counts := {}
	var result: Array[String] = []
	for index in formation:
		if index < 0 or index >= MANIFEST.characters.size(): continue
		for tag in MANIFEST.characters[index].tags: counts[tag] = counts.get(tag,0) + 1
	for s in MANIFEST.synergies:
		if counts.get(s.id,0) >= s.required_count: result.append(s.id)
	return result

static func active_tags(formation: Array) -> Array[String]:
	var result: Array[String] = []
	for id in active_tag_ids(formation): result.append(synergy(id).display_name)
	return result

static func make_unit(d, role: int, side: int, slot: int) -> Dictionary:
	return {"id":0, "name":d.display_name, "content_id":d.id, "role":role, "side":side, "slot":slot,
		"max_hp":float(d.health), "hp":float(d.health), "atk":float(d.attack), "interval":d.interval,
		"timer":d.interval, "def":float(d.defense), "shield":0.0, "count":0, "flash":0.0,
		"damage":0.0, "healing":0.0, "attack_range":d.attack_range, "move_speed":d.move_speed,
		"skill":d.skill, "action_profile":d.action_profile, "portrait":d.portrait,
		"battle_animation":d.battle_animation, "badge_color":d.badge_color, "attack_modes":d.resolved_attack_modes()}

static func roster(formation: Array, battle: int, rewards: Array, gear: Dictionary, trainee: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(formation.size()):
		var index: int = formation[slot]
		if index < 0: continue
		var u = make_unit(definition(index),index,0,slot)
		u.tags = MANIFEST.characters[index].tags.duplicate()
		for id in rewards:
			var r = reward(id)
			if r != null and r.category == "训练" and trainee == index:
				u.max_hp *= r.health_multiplier
				u.hp = u.max_hp
				u.atk *= r.attack_multiplier
		u.gear = ""
		for item in gear:
			if gear[item] == index: u.gear = item
		result.append(u)
	var encounter = MANIFEST.encounters[battle]
	for i in range(encounter.units.size()): result.append(make_unit(encounter.units[i],-1,1,encounter.slots[i]))
	for i in range(result.size()):
		result[i].id = i
		AutoBattle.initialize(result[i])
	return result

static func validate(content = MANIFEST) -> Array[String]:
	return preload("res://game/trial/trial_content_validator.gd").validate(content)
