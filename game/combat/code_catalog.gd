extends RefCounted
const STOCK_CAP := 3
const MAX_LOADOUT := 4
const RULES = preload("res://resources/combat/code_rules.tres")
const PEOPLE = preload("res://resources/combat/manifest.tres")
const RulesDefinition = preload("res://game/content/code_rules.gd")
const ProgramDefinition = preload("res://game/content/code_program_def.gd")
const ItemDefinition = preload("res://game/content/code_item_def.gd")

static func program(id: String, rules = RULES):
	for entry in rules.programs:
		if entry is ProgramDefinition and entry.id == id: return entry
	return null

static func item(id: String):
	for entry in RULES.items:
		if entry is ItemDefinition and entry.id == id: return entry
	return null

static func stock() -> Dictionary:
	var result := {}
	for entry in RULES.items:
		if entry is ItemDefinition: result[entry.id] = entry.starting_count
	return result

static func migrate_stock(value: Variant) -> Dictionary:
	if not value is Dictionary: return {}
	var result: Dictionary = value.duplicate()
	# Old two-item saves gain empty slots, never free new consumables.
	if result.size() == 2 and result.has("supply") and result.has("converter"):
		result.shield = 0
		result.revive = 0
	return result if valid_stock(result) else {}

static func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for id in cost:
		var kind: Dictionary = RULES.types[id]
		parts.append("%s%s×%d" % [kind.symbol, kind.name, cost[id]])
	return " ＋ ".join(parts)

static func valid_loadout(value, rules = RULES) -> bool:
	if not value is Array or value.is_empty() or value.size() > MAX_LOADOUT: return false
	var seen := {}
	for id in value:
		if not id is String or seen.has(id) or program(id,rules) == null: return false
		seen[id] = true
	return true

static func valid_stock(value) -> bool:
	if not value is Dictionary or value.size() != RULES.items.size(): return false
	for entry in RULES.items:
		if not entry is ItemDefinition: return false
		var count = value.get(entry.id)
		if not (count is int or count is float) or not is_finite(count) or count != int(count) or count < 0 or count > STOCK_CAP: return false
	return true

static func validate(rules = RULES) -> Array[String]:
	var errors: Array[String] = []
	if not rules is RulesDefinition:
		return ["代码规则资源类型错误"]
	for character in PEOPLE.characters:
		if character != null and not rules.types.has(character.code_type): errors.append(character.id + ": 未注册的代码产出类型")
	for group in [PEOPLE.characters, PEOPLE.synergies, PEOPLE.rewards]:
		for entry in group:
			if entry == null: continue
			for effect in entry.effects:
				if effect == null or effect.effect != "hack": continue
				if effect.code_amount <= 0 or (not effect.code_type.is_empty() and not rules.types.has(effect.code_type)): errors.append(entry.id + ": 代码产出配置非法")
	if rules.types.size() < 3 or rules.types.size() > 5: errors.append("代码类型须为3至5种")
	if rules.cache_cap <= 0 or rules.attacks_per_block <= 0 or not is_finite(rules.shared_cooldown) or rules.shared_cooldown <= 0 or not is_finite(rules.shield_per_block) or rules.shield_per_block <= 0: errors.append("缓存、产出次数与冷却须为正")
	for id in rules.types:
		var entry = rules.types[id]
		if not id is String or id.is_empty() or not entry is Dictionary: errors.append("代码类型定义非法"); continue
		if not entry.get("name") is String or not entry.get("symbol") is String or not entry.get("color") is Color: errors.append("代码类型缺少名称、符号或颜色")
	var ids := {}
	for entry in rules.programs:
		if not entry is ProgramDefinition: errors.append("空或错误类型的破解技能"); continue
		if entry.id.is_empty() or ids.has(entry.id) or entry.display_name.is_empty(): errors.append("技能ID或名称非法")
		ids[entry.id] = true
		if not entry.effect in ["pursuit", "recoil", "repair"] or not is_finite(entry.heal_ratio) or entry.heal_ratio <= 0 or entry.heal_ratio > 1: errors.append("技能效果非法")
		if not is_finite(entry.cooldown) or entry.cooldown <= 0 or not is_finite(entry.duration) or entry.duration <= 0 or not is_finite(entry.damage) or entry.damage < 0 or not is_finite(entry.shield) or entry.shield < 0 or not is_finite(entry.radius) or entry.radius <= 0 or not is_finite(entry.heal_amount) or entry.heal_amount < 0 or entry.any_cost < 0 or entry.any_cost > rules.cache_cap * rules.types.size() or entry.per_battle_limit < 0: errors.append("程序数值非法")
		if entry.cost.is_empty() and entry.any_cost <= 0: errors.append("破解技能必须消耗代码")
		for kind in entry.cost:
			var amount = entry.cost[kind]
			if not rules.types.has(kind) or not (amount is int or amount is float) or not is_finite(amount) or amount != int(amount) or amount < 1 or amount > rules.cache_cap: errors.append("技能配方非法")
	if not valid_loadout(rules.default_loadout, rules): errors.append("默认须携带1至4种不同技能")
	ids.clear()
	if rules.items.is_empty(): errors.append("道具列表不能为空")
	for entry in rules.items:
		if not entry is ItemDefinition: errors.append("空或错误类型的道具"); continue
		if entry.id.is_empty() or ids.has(entry.id) or entry.display_name.is_empty(): errors.append("道具ID或名称非法")
		ids[entry.id] = true
		var maximum: int = 144 if entry.effect == "shield" else 100 if entry.effect == "revive" else rules.cache_cap
		if not entry.effect in ["generate", "convert", "shield", "revive"] or entry.amount <= 0 or entry.amount > maximum or entry.starting_count < 0 or entry.starting_count > STOCK_CAP: errors.append("道具配置非法")
	return errors

static func migrate_loadout(value) -> Array:
	if not value is Array or value.is_empty() or value.size() > MAX_LOADOUT: return []
	var migrated: Array = value.duplicate()
	for i in range(migrated.size()):
		if migrated[i] == "takeover": migrated[i] = "redirect"
	if migrated.size() == 2 and migrated[0] == migrated[1]: migrated[1] = "repair" if migrated[0] != "repair" else "disconnect"
	return migrated if valid_loadout(migrated) else []
