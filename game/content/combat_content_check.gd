extends Node
const Validator = preload("res://game/content/combat_content_validator.gd")
const Manifest = preload("res://resources/combat/manifest.tres")
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
	check(baseline.is_empty(), "Shipped combat extension resources validate: " + str(baseline))
	if not baseline.is_empty():
		get_tree().quit(1)
		return
	for invalid in [null, {}, Resource.new(), "wrong type"]:
		check(not Validator.validate(invalid).is_empty(), "Wrong root is rejected")
	for group in ["characters", "synergies", "rewards"]:
		rejected("Null registry entry: " + group, func(c): c.get(group).append(null), "空资源")
	rejected("Empty ID", func(c): c.characters[0].id = "", "ID")
	rejected("Cross-registry duplicate ID", func(c): c.synergies[0].id = c.characters[0].id, "重复ID")
	rejected("Blank name", func(c): c.characters[0].display_name = "  ", "名称")
	rejected("Unknown main roster character", func(c): c.characters[0].id = "missing_role", "主线人物")
	rejected("Unknown code color", func(c): c.characters[0].code_type = "unknown", "代码产出")
	rejected("Unknown character tag", func(c): c.characters[0].tags.append("missing"), "未注册")
	rejected("Repeated character tag", func(c): c.characters[0].tags.append(c.characters[0].tags[0]), "重复标签")
	rejected("Invalid synergy threshold", func(c): c.synergies[0].required_count = 5, "门槛")
	rejected("Wrong reward category", func(c): c.rewards[0].category = "currency", "奖励类型")
	rejected("Exclusive without character", func(c): c.rewards[3].character_id = "", "专属人物")
	rejected("Unknown exclusive character", func(c): c.rewards[3].character_id = "missing", "专属人物")
	rejected("Unsupported training ID", func(c): c.rewards[0].category = "训练", "仅支持 training")
	rejected("Unsupported equipment ID", func(c): c.rewards[0].category = "装备", "对象选择")
	rejected("Equipment character lock", func(c): c.rewards[1].character_id = "guard", "仅用于专属")
	rejected("Equipment growth multiplier", func(c): c.rewards[1].health_multiplier = 1.5, "仅用于训练")
	rejected("Nonfinite training multiplier", func(c): c.rewards[2].health_multiplier = INF, "成长数值")
	rejected("Negative mark count", func(c): c.rewards[3].mark_uses_bonus = -1, "成长数值")
	rejected("Null reaction", func(c): c.synergies[0].effects.append(null), "空效果")
	rejected("Duplicate reaction ID", func(c): c.synergies[0].effects.append(c.synergies[0].effects[0]), "效果ID")
	rejected("Unknown reaction effect", func(c): c.synergies[0].effects[0].effect = "unknown", "未知")
	rejected("Unknown reaction target", func(c): c.synergies[0].effects[0].target = "unknown", "规则非法")
	rejected("Targetless trigger with skill target", func(c):
		c.synergies[0].effects[0].trigger = "half_health"
		c.synergies[0].effects[0].target = "skill_target", "没有技能目标")
	rejected("Actionless trigger with action scope", func(c):
		c.synergies[0].effects[0].trigger = "battle_start"
		c.synergies[0].effects[0].limit = "action", "没有动作编号")
	rejected("Unknown prerequisite tag", func(c): c.synergies[0].effects[0].required_tag = "missing", "条件标签")
	rejected("Nonfinite effect value", func(c): c.synergies[0].effects[0].value = INF, "效果数值")
	rejected("Missing haste duration", func(c): c.synergies[2].effects[0].duration = 0, "持续时间")
	rejected("Damage bonus wrong phase", func(c): c.synergies[4].effects[0].trigger = "battle_start", "加成触发")
	rejected("Invalid code amount", func(c): c.synergies[5].effects[0].code_amount = 0, "代码产出")
	rejected("Invalid code type", func(c): c.synergies[5].effects[0].code_type = "black", "代码产出")
	rejected("Pierce wrong phase", func(c): c.rewards[4].effects[0].trigger = "skill_impact", "穿透须")
	rejected("Invalid vulnerability lifetime", func(c): c.vulnerability_duration = NAN, "漏洞时限")
	check(Validator.validate(Manifest).is_empty(), "Mutation fixtures keep shipped resources unchanged")
	print("COMBAT_CONTENT_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
