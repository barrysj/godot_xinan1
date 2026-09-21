extends Node
const Validator = preload("res://game/trial/trial_content_validator.gd")
const Manifest = preload("res://resources/trial/manifest.tres")
const Profile = preload("res://game/content/battle_action_profile.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func rejected(label: String, mutation: Callable, expected: String) -> void:
	var content = Manifest.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	mutation.call(content)
	var errors: Array[String] = Validator.validate(content)
	check(errors.any(func(error): return expected in error), label + ": " + str(errors))

func _ready() -> void:
	var baseline: Array[String] = Validator.validate(Manifest)
	check(baseline.is_empty(), "Shipped .tres manifest loads and validates: " + str(baseline))
	if not baseline.is_empty():
		get_tree().quit(1)
		return
	for invalid in [null, {}, Resource.new(), "not a resource", 42]:
		check(not Validator.validate(invalid).is_empty(), "Wrong root value rejected without dereference: " + str(invalid))
	for group in ["characters", "synergies", "rewards", "encounters"]:
		rejected("Null registry entry: " + group, func(c): c.get(group).append(null), "空资源")
	rejected("Empty ID", func(c): c.characters[0].id = "", "ID")
	rejected("Whitespace ID", func(c): c.characters[0].id = " guard ", "ID")
	rejected("Cross-registry duplicate ID", func(c): c.synergies[0].id = c.characters[0].id, "重复ID")
	rejected("Blank display name", func(c): c.characters[0].display_name = "  ", "名称")
	rejected("Duplicate synergy name cannot overwrite registry", func(c): c.synergies[0].display_name = c.synergies[1].display_name, "重名")
	rejected("Insufficient characters", func(c): c.characters.resize(3), "四名")
	rejected("No encounters", func(c): c.encounters.clear(), "遭遇")
	rejected("Invalid synergy threshold", func(c): c.synergies[0].required_count = 5, "门槛")
	rejected("Unknown tag", func(c): c.characters[0].tags.append("missing"), "未注册")
	rejected("Duplicate character tag", func(c): c.characters[0].tags.append(c.characters[0].tags[0]), "重复标签")
	rejected("Missing unit", func(c): c.characters[0].unit = null, "人物资源")
	rejected("Missing base skill", func(c): c.characters[0].unit.skill = null, "缺少技能")
	rejected("Invalid override skill", func(c): c.characters[3].skill_override.attacks_to_trigger = 0, "触发次数")
	rejected("Invalid skill glyph enum", func(c): c.characters[0].unit.skill.glyph = "unknown", "图标枚举")
	rejected("Null skill effect", func(c): c.characters[0].unit.skill.effects.append(null), "空技能效果")
	rejected("Unknown skill effect kind", func(c): c.characters[0].unit.skill.effects[0].kind = "teleport", "效果类型")
	rejected("Unknown skill target", func(c): c.characters[0].unit.skill.effects[0].target = "neighbor_enemy", "目标非法")
	rejected("Nonfinite skill damage", func(c): c.characters[0].unit.skill.effects[0].attack_scale = NAN, "效果数值")
	rejected("Negative skill damage", func(c): c.characters[0].unit.skill.effects[0].value = -1, "效果数值")
	rejected("Invalid attack modes", func(c): c.characters[0].unit.attack_modes = 8, "攻击类型")
	rejected("Invalid projectile delivery enum", func(c):
		c.characters[0].unit.action_profile = Profile.new()
		c.characters[0].unit.action_profile.delivery = "beam", "投递方式")
	rejected("Zero projectile speed", func(c):
		c.characters[0].unit.action_profile = Profile.new()
		c.characters[0].unit.action_profile.projectile_speed = 0, "弹速")
	rejected("Nonfinite movement speed", func(c): c.characters[0].unit.move_speed = INF, "属性非法")
	rejected("Unknown stat key", func(c): c.characters[0].stats[17] = 2, "属性覆盖")
	rejected("Wrong stat type", func(c): c.characters[0].stats["health"] = "high", "属性覆盖")
	rejected("Fractional integer stat", func(c): c.characters[0].stats["health"] = 0.5, "不能使用小数")
	rejected("Nonfinite stat override", func(c): c.characters[0].stats["attack_range"] = NAN, "属性覆盖")
	var valid = Manifest.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	valid.characters[0].stats["defense"] = 0
	check(Validator.validate(valid).is_empty(), "Zero defense is a valid override")
	var guest = valid.characters[0].duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	guest.id = "guest"
	guest.display_name = "测试同学"
	valid.characters.append(guest)
	var additional = valid.synergies[0].duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	additional.id = "network"
	additional.display_name = "网络社"
	valid.synergies.append(additional)
	valid.characters[0].tags.append("network")
	valid.characters[1].tags.append("network")
	check(Validator.validate(valid).is_empty(), "New character and new supported synergy resources require no validator switch")
	rejected("Invalid reward category enum", func(c): c.rewards[0].category = "currency", "奖励类型")
	rejected("Exclusive with unknown character", func(c): c.rewards[3].character_id = "missing", "专属人物")
	rejected("Exclusive missing character", func(c): c.rewards[3].character_id = "", "专属人物")
	rejected("Unsupported additional training", func(c): c.rewards[0].category = "训练", "仅支持 training")
	rejected("Training ID must remain training category", func(c): c.rewards[2].category = "装备", "仅支持 training")
	rejected("Unsupported equipment character lock", func(c): c.rewards[1].character_id = "guard", "仅用于专属")
	rejected("Unsupported equipment growth multiplier", func(c): c.rewards[1].health_multiplier = 1.5, "仅用于训练")
	rejected("Departure lens cannot be removed", func(c): c.rewards.remove_at(1), "lens 必须存在")
	rejected("Departure lens must remain equipment", func(c): c.rewards[1].category = "羁绊", "lens 必须存在")
	valid = Manifest.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	valid.rewards.remove_at(2)
	valid.encounters[0].reward_ids.erase("training")
	check(Validator.validate(valid).is_empty(), "Training is optional when no stage references it")
	rejected("Nonfinite growth multiplier", func(c): c.rewards[2].health_multiplier = INF, "成长数值")
	rejected("Negative mark count", func(c): c.rewards[3].mark_uses_bonus = -1, "成长数值")
	rejected("Enemy slot count mismatch", func(c): c.encounters[0].slots.clear(), "敌阵数量")
	rejected("Duplicate enemy slot", func(c): c.encounters[0].slots[1] = c.encounters[0].slots[0], "槽位")
	rejected("Enemy slot out of board", func(c): c.encounters[0].slots[0] = 6, "槽位")
	rejected("Missing enemy", func(c): c.encounters[0].units[0] = null, "人物资源")
	rejected("Negative enemy defense", func(c): c.encounters[0].units[0].defense = -1, "属性非法")
	rejected("Zero maintenance period", func(c): c.encounters[0].pulse_interval = 0, "维护参数")
	rejected("Nonfinite maintenance shield", func(c): c.encounters[0].pulse_shield = INF, "维护参数")
	rejected("Unknown stage reward", func(c): c.encounters[0].reward_ids.append("missing"), "未注册")
	rejected("Duplicate stage reward", func(c): c.encounters[0].reward_ids.append("cover"), "重复奖励")
	rejected("Missing nonfinal rewards", func(c): c.encounters[0].reward_ids.clear(), "非终局")
	rejected("Unreachable final rewards", func(c): c.encounters[2].reward_ids.append("backup"), "终局")
	rejected("Starting supply can own every offer", func(c): c.encounters[0].reward_ids.assign(["lens"]), "死路")
	rejected("Prior rewards can own every offer", func(c): c.encounters[1].reward_ids.assign(["cover", "lens"]), "死路")
	valid = Manifest.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	valid.encounters[1].reward_ids.assign(["cover", "lens", "training"])
	check(Validator.validate(valid).is_empty(), "Broad repeated reward pool remains valid when not all offers can be owned")
	rejected("Null proc", func(c): c.synergies[0].effects.append(null), "空效果")
	rejected("Duplicate owner proc ID", func(c): c.synergies[0].effects.append(c.synergies[0].effects[0]), "效果ID")
	for key in ["trigger", "effect", "target", "limit"]:
		rejected("Invalid proc enum " + key, func(c): c.synergies[0].effects[0].set(key, "unknown"), "未知" if key in ["trigger", "effect"] else "规则非法")
	for trigger in ["battle_start", "half_health", "hack_complete", "verify"]:
		rejected("Targetless trigger rejects skill target: " + trigger, func(c):
			c.synergies[0].effects[0].trigger = trigger
			c.synergies[0].effects[0].target = "skill_target", "没有技能目标")
		rejected("Actionless trigger rejects action limit: " + trigger, func(c):
			c.synergies[0].effects[0].trigger = trigger
			c.synergies[0].effects[0].limit = "action", "没有动作编号")
	for trigger in ["skill_emit", "skill_impact", "before_damage_skill"]:
		valid = Manifest.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		valid.synergies[0].effects[0].trigger = trigger
		valid.synergies[0].effects[0].target = "skill_target"
		valid.synergies[0].effects[0].limit = "action"
		check(Validator.validate(valid).is_empty(), "Action context supports target and action limit: " + trigger)
	rejected("Unknown proc prerequisite tag", func(c): c.synergies[0].effects[0].required_tag = "missing", "条件标签")
	for key in ["value", "max_health_ratio", "duration", "radius"]:
		rejected("Nonfinite proc field " + key, func(c): c.synergies[0].effects[0].set(key, INF), "效果数值")
	rejected("Missing haste duration", func(c): c.synergies[2].effects[0].duration = 0, "持续时间")
	rejected("Damage proc at wrong phase", func(c): c.synergies[4].effects[0].trigger = "battle_start", "加成触发点")
	rejected("Fractional hack contribution", func(c): c.synergies[5].effects[0].value = 0.5, "正整数")
	rejected("Pierce at wrong phase", func(c): c.rewards[4].effects[0].trigger = "skill_impact", "穿透须")
	rejected("Invalid hacking goal", func(c): c.hack_goal = 0, "破解配置")
	rejected("Invalid vulnerability lifetime", func(c): c.vulnerability_duration = NAN, "破解配置")
	check(Validator.validate(Manifest).is_empty(), "Mutation fixtures do not modify the shipped resources")
	check(checks >= 70, "All content fixtures completed")
	print("TRIAL_CONTENT_CHECK ", "PASS" if failures == 0 else "FAIL", " checks=", checks, " failures=", failures)
	get_tree().quit(failures)
