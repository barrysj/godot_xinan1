extends RefCounted
## Validate only combat content consumed by the campus roster and reward flow.
const Content = preload("res://game/content/combat_content.gd")
const Campus = preload("res://game/content/content_db.gd")
const CodeRules = preload("res://resources/combat/code_rules.tres")
const PROC_TRIGGERS := ["battle_start", "skill_impact", "before_damage_skill", "half_health", "hack_complete", "verify", "skill_emit"]
const PROC_EFFECTS := ["shield", "heal", "hack", "mark", "attack_speed", "damage_bonus", "pierce"]
const PROC_TARGETS := ["owner", "lowest_ally", "lowest_other_near", "skill_target"]
const PROC_LIMITS := ["owner", "team", "action", "none"]
const ACTION_TRIGGERS := ["skill_emit", "skill_impact", "before_damage_skill"]

static func validate(content) -> Array[String]:
	var errors: Array[String] = []
	if not content is Content:
		return ["战斗扩展内容为空或资源类型错误"]
	var ids := {}
	var tags := {}
	var characters := {}
	if content.characters.is_empty(): errors.append("至少需要一名扩展人物")
	for group in [content.characters, content.synergies, content.rewards]:
		var names := {}
		for entry in group:
			if entry == null:
				errors.append("空资源引用")
				continue
			if not _identifier(entry.id) or ids.has(entry.id): errors.append("空或重复ID: " + entry.id)
			ids[entry.id] = true
			if entry.display_name.strip_edges().is_empty() or names.has(entry.display_name): errors.append(entry.id + ": 名称为空或同类重名")
			names[entry.display_name] = true
	for synergy in content.synergies:
		if synergy == null: continue
		tags[synergy.id] = true
		if synergy.required_count < 2 or synergy.required_count > 4: errors.append(synergy.id + ": 门槛须为2至4人")
	for character in content.characters:
		if character == null: continue
		characters[character.id] = true
		if Campus.role_index(character.id) < 0: errors.append(character.id + ": 主线人物不存在")
		if not CodeRules.types.has(character.code_type): errors.append(character.id + ": 未注册的代码产出类型")
		var seen := {}
		for tag in character.tags:
			if not tags.has(tag) or seen.has(tag): errors.append(character.id + ": 未注册或重复标签 " + tag)
			seen[tag] = true
	for reward in content.rewards:
		if reward == null: continue
		if not reward.category in ["羁绊", "装备", "训练", "专属"]: errors.append(reward.id + ": 未知奖励类型")
		if reward.category == "训练" and reward.id != "training" or reward.id == "training" and reward.category != "训练": errors.append(reward.id + ": 当前训练效果仅支持 training")
		if reward.category == "装备" and not reward.id in ["lens", "backup"]: errors.append(reward.id + ": 装备强化须接入对象选择")
		if reward.category == "专属" and not characters.has(reward.character_id): errors.append(reward.id + ": 专属人物不存在")
		if reward.category != "专属" and (not reward.character_id.is_empty() or reward.mark_uses_bonus != 0): errors.append(reward.id + ": 人物限定与验证次数扩展仅用于专属奖励")
		if reward.category != "训练" and (reward.health_multiplier != 1.0 or reward.attack_multiplier != 1.0): errors.append(reward.id + ": 人物属性倍率仅用于训练奖励")
		if not _number(reward.health_multiplier, 0.000001) or not _number(reward.attack_multiplier, 0.000001) or reward.mark_uses_bonus < 0: errors.append(reward.id + ": 成长数值非法")
	for group in [content.characters, content.synergies, content.rewards]:
		for entry in group:
			if entry == null: continue
			var proc_ids := {}
			for proc in entry.effects:
				if proc == null:
					errors.append(entry.id + ": 空效果")
					continue
				if not _identifier(proc.id) or proc_ids.has(proc.id): errors.append(entry.id + ": 效果ID非法")
				proc_ids[proc.id] = true
				if not proc.trigger in PROC_TRIGGERS or not proc.effect in PROC_EFFECTS: errors.append(entry.id + ": 未知触发或效果")
				if not proc.target in PROC_TARGETS or not proc.limit in PROC_LIMITS: errors.append(entry.id + ": 目标或次数规则非法")
				if proc.target == "skill_target" and not proc.trigger in ACTION_TRIGGERS: errors.append(entry.id + ": 此触发点没有技能目标")
				if proc.limit == "action" and not proc.trigger in ACTION_TRIGGERS: errors.append(entry.id + ": 此触发点没有动作编号")
				if not proc.required_tag.is_empty() and not tags.has(proc.required_tag): errors.append(entry.id + ": 条件标签不存在")
				for value in [proc.value, proc.max_health_ratio, proc.duration, proc.radius]:
					if not _number(value, 0): errors.append(entry.id + ": 效果数值非法")
				if proc.effect == "attack_speed" and (proc.value <= 0 or proc.duration <= 0): errors.append(entry.id + ": 攻速倍率与持续时间须为正")
				if proc.effect == "hack" and (proc.code_amount <= 0 or not proc.code_type.is_empty() and not CodeRules.types.has(proc.code_type)): errors.append(entry.id + ": 代码产出配置非法")
				if proc.effect == "damage_bonus" and proc.trigger != "before_damage_skill": errors.append(entry.id + ": 伤害加成触发点非法")
				if proc.effect == "pierce" and (proc.trigger != "skill_emit" or proc.value <= 0): errors.append(entry.id + ": 穿透须在技能发射时触发且倍率为正")
	if not _number(content.vulnerability_duration, 0.000001): errors.append("漏洞时限须为正")
	return errors

static func _identifier(value: String) -> bool:
	return not value.is_empty() and value == value.strip_edges()

static func _number(value, minimum: float) -> bool:
	return (value is int or value is float) and is_finite(value) and value >= minimum
