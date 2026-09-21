extends RefCounted
## Authoring gate for the implemented trial vocabulary, not an effect scripting language.
const Content = preload("res://game/content/trial_content.gd")
const PROC_TRIGGERS := ["battle_start", "skill_impact", "before_damage_skill", "half_health", "hack_complete", "verify", "skill_emit"]
const PROC_EFFECTS := ["shield", "heal", "hack", "mark", "attack_speed", "damage_bonus", "pierce"]
const PROC_TARGETS := ["owner", "lowest_ally", "lowest_other_near", "skill_target"]
const PROC_LIMITS := ["owner", "team", "action", "none"]
const ACTION_TRIGGERS := ["skill_emit", "skill_impact", "before_damage_skill"]
const SKILL_TARGETS := ["normal", "back", "low_enemy", "low_ally", "adjacent", "row", "self", "all_allies", "all_enemies"]
const SKILL_KINDS := ["damage", "heal", "shield", "max_hp", "attack", "interval"]
const STAT_KEYS := ["health", "attack", "defense", "interval", "attack_range", "move_speed"]

static func validate(content) -> Array[String]:
	var errors: Array[String] = []
	if not content is Content:
		errors.append("试炼内容为空或资源类型错误")
		return errors
	var ids := {}
	var tags := {}
	var characters := {}
	var rewards := {}
	if content.characters.size() < 4: errors.append("至少需要四名候选人物")
	if content.encounters.is_empty(): errors.append("至少需要一场遭遇")
	for group in [content.characters, content.synergies, content.rewards, content.encounters]:
		var names := {}
		for entry in group:
			if entry == null:
				errors.append("空资源引用")
				continue
			if not _identifier(entry.id) or ids.has(entry.id): errors.append("空或重复ID: " + entry.id)
			ids[entry.id] = true
			if entry.display_name.strip_edges().is_empty() or names.has(entry.display_name): errors.append(entry.id + ": 名称为空或同类重名")
			names[entry.display_name] = true
	for s in content.synergies:
		if s == null: continue
		tags[s.id] = true
		if s.required_count < 2 or s.required_count > 4: errors.append(s.id + ": 门槛须为2至4人")
	for c in content.characters:
		if c == null: continue
		characters[c.id] = true
		_validate_unit(c.unit, c.id, errors)
		if c.skill_override != null: _validate_skill(c.skill_override, c.id + "/技能覆盖", errors)
		var seen := {}
		for tag in c.tags:
			if not tags.has(tag) or seen.has(tag): errors.append(c.id + ": 未注册或重复标签 " + tag)
			seen[tag] = true
		for stat in c.stats:
			var value = c.stats[stat]
			if not stat in STAT_KEYS or not _number(value, 0 if stat == "defense" else 0.000001):
				errors.append(c.id + ": 非法属性覆盖 " + str(stat))
			elif stat in ["health", "attack", "defense"] and value != int(value):
				errors.append(c.id + ": 整数属性不能使用小数 " + str(stat))
	for r in content.rewards:
		if r == null: continue
		rewards[r.id] = true
		if not r.category in ["羁绊", "装备", "训练", "专属"]: errors.append(r.id + ": 未知奖励类型")
		if (r.category == "专属" and r.character_id.is_empty()) or (not r.character_id.is_empty() and not characters.has(r.character_id)):
			errors.append(r.id + ": 专属人物不存在")
		if (r.category == "训练") != (r.id == "training"): errors.append(r.id + ": 当前存档仅支持 training 这一项训练")
		if r.category != "专属" and (not r.character_id.is_empty() or r.mark_uses_bonus != 0): errors.append(r.id + ": 人物限定与验证次数扩展仅用于专属奖励")
		if r.category != "训练" and (r.health_multiplier != 1.0 or r.attack_multiplier != 1.0): errors.append(r.id + ": 人物属性倍率仅用于训练奖励")
		if not _number(r.health_multiplier, 0.000001) or not _number(r.attack_multiplier, 0.000001) or r.mark_uses_bonus < 0: errors.append(r.id + ": 成长数值非法")
	var has_departure_lens := false
	for r in content.rewards:
		if r != null and r.id == "lens" and r.category == "装备": has_departure_lens = true
	if not has_departure_lens: errors.append("出发解锁固定奖励 lens 必须存在且为装备")
	var earlier_pools: Array = []
	# The current departure choice is lens; treat it as a possible prior grant.
	if rewards.has("lens"): earlier_pools.append(["lens"])
	for index in range(content.encounters.size()):
		var e = content.encounters[index]
		if e == null: continue
		if e.units.is_empty() or e.units.size() != e.slots.size() or e.units.size() > 6: errors.append(e.id + ": 敌阵数量非法")
		if not _number(e.pulse_interval, 0.000001) or not _number(e.pulse_shield, 0): errors.append(e.id + ": 维护参数非法")
		var occupied := {}
		for slot in e.slots:
			if slot < 0 or slot > 5 or occupied.has(slot): errors.append(e.id + ": 槽位非法或重复")
			occupied[slot] = true
		var reward_seen := {}
		for id in e.reward_ids:
			if not rewards.has(id) or reward_seen.has(id): errors.append(e.id + ": 未注册或重复奖励 " + id)
			reward_seen[id] = true
		if index == content.encounters.size() - 1:
			if not e.reward_ids.is_empty(): errors.append(e.id + ": 终局不进入领奖，奖励池须为空")
		else:
			if e.reward_ids.is_empty(): errors.append(e.id + ": 非终局奖励池为空")
			elif _can_own_entire_pool(e.reward_ids, earlier_pools): errors.append(e.id + ": 存在全部奖励已拥有的死路")
			earlier_pools.append(Array(e.reward_ids))
		for u in e.units: _validate_unit(u, e.id + "/敌阵", errors)
	for group in [content.characters, content.synergies, content.rewards]:
		for entry in group:
			if entry == null: continue
			var proc_ids := {}
			for p in entry.effects:
				if p == null:
					errors.append(entry.id + ": 空效果")
					continue
				if not _identifier(p.id) or proc_ids.has(p.id): errors.append(entry.id + ": 效果ID非法")
				proc_ids[p.id] = true
				if not p.trigger in PROC_TRIGGERS or not p.effect in PROC_EFFECTS: errors.append(entry.id + ": 未知触发或效果")
				if not p.target in PROC_TARGETS or not p.limit in PROC_LIMITS: errors.append(entry.id + ": 目标或次数规则非法")
				if p.target == "skill_target" and not p.trigger in ACTION_TRIGGERS: errors.append(entry.id + ": 此触发点没有技能目标")
				if p.limit == "action" and not p.trigger in ACTION_TRIGGERS: errors.append(entry.id + ": 此触发点没有动作编号")
				if not p.required_tag.is_empty() and not tags.has(p.required_tag): errors.append(entry.id + ": 条件标签不存在")
				for value in [p.value, p.max_health_ratio, p.duration, p.radius]:
					if not _number(value, 0): errors.append(entry.id + ": 效果数值非法")
				if p.effect == "attack_speed" and (p.value <= 0 or p.duration <= 0): errors.append(entry.id + ": 攻速倍率与持续时间须为正")
				if p.effect == "hack" and (p.value < 1 or p.value != floorf(p.value)): errors.append(entry.id + ": 破解贡献须为正整数")
				if p.effect == "damage_bonus" and p.trigger != "before_damage_skill": errors.append(entry.id + ": 伤害加成触发点非法")
				if p.effect == "pierce" and (p.trigger != "skill_emit" or p.value <= 0): errors.append(entry.id + ": 穿透须在技能发射时触发且倍率为正")
	if content.hack_goal <= 0 or content.skill_progress <= 0 or content.verification_progress <= 0 or not _number(content.vulnerability_duration, 0.000001): errors.append("破解配置须为正")
	return errors

static func _identifier(value: String) -> bool:
	return not value.is_empty() and value == value.strip_edges()

static func _number(value, minimum: float) -> bool:
	return (value is int or value is float) and is_finite(value) and value >= minimum

static func _validate_unit(unit, context: String, errors: Array[String]) -> void:
	if unit == null:
		errors.append(context + ": 缺少人物资源")
		return
	if not _identifier(unit.id) or unit.display_name.strip_edges().is_empty(): errors.append(context + ": 人物ID或名称为空")
	for stat in STAT_KEYS:
		if not _number(unit.get(stat), 0 if stat == "defense" else 0.000001): errors.append(context + ": 人物属性非法 " + stat)
	if unit.attack_modes < 0 or unit.attack_modes > 3: errors.append(context + ": 攻击类型标志非法")
	if unit.action_profile != null:
		var profile = unit.action_profile
		if not profile.delivery in ["auto", "melee", "projectile"]: errors.append(context + ": 动作投递方式非法")
		for value in [profile.windup, profile.recovery, profile.projectile_speed]:
			if not _number(value, 0.000001): errors.append(context + ": 动作时序或弹速非法")
	_validate_skill(unit.skill, context, errors)

static func _validate_skill(skill, context: String, errors: Array[String]) -> void:
	if skill == null:
		errors.append(context + ": 缺少技能")
		return
	if not _identifier(skill.id) or skill.display_name.strip_edges().is_empty(): errors.append(context + ": 技能ID或名称为空")
	if skill.attacks_to_trigger <= 0: errors.append(context + ": 技能触发次数须为正")
	if not skill.glyph in ["shield", "arrow", "heart", "bolt", "flask"]: errors.append(context + ": 技能图标枚举非法")
	for effect in skill.effects:
		if effect == null:
			errors.append(context + ": 空技能效果")
			continue
		if not effect.kind in SKILL_KINDS or not effect.target in SKILL_TARGETS: errors.append(context + ": 技能效果类型或目标非法")
		if not _number(effect.value, 0) or not _number(effect.attack_scale, 0): errors.append(context + ": 技能效果数值非法")
		if effect.kind == "interval" and effect.value <= 0: errors.append(context + ": 攻击间隔须为正")

## A matching assigns each currently offered reward to a distinct earlier stage
## that could have granted it. Full coverage means a legal history can own all
## offers, leaving the player unable to advance. Repeated broad pools remain legal.
static func _can_own_entire_pool(pool: Array[String], earlier: Array) -> bool:
	if pool.size() > earlier.size(): return false
	var assignments := {}
	for reward in pool:
		if not _assign_prior_stage(reward, earlier, assignments, {}): return false
	return true

static func _assign_prior_stage(reward: String, earlier: Array, assignments: Dictionary, seen: Dictionary) -> bool:
	for index in range(earlier.size()):
		if seen.has(index) or not earlier[index].has(reward): continue
		seen[index] = true
		if not assignments.has(index) or _assign_prior_stage(assignments[index], earlier, assignments, seen):
			assignments[index] = reward
			return true
	return false
