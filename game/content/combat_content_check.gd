extends Node
const Validator = preload("res://game/content/combat_content_validator.gd")
const Manifest = preload("res://resources/combat/manifest.tres")
const Proc = preload("res://game/content/battle_proc.gd")
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

func rejected_proc(label: String, mutation: Callable, expected: String) -> void:
	# Validation fixtures are independent of which optional reactions are shipped.
	var content = Manifest.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var proc = Proc.new()
	proc.id = "validation_fixture"
	proc.value = 20
	content.synergies[0].effects.append(proc)
	mutation.call(proc, content)
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
	rejected("Unknown reward chain", func(c): c.rewards[0].reward_chain = "missing", "流派标签")
	rejected("Zero reward weight", func(c): c.rewards[0].reward_weight = 0, "权重")
	rejected("Invalid offer gate", func(c): c.rewards[0].minimum_offer = 0, "轮次")
	rejected("Tag count without tag", func(c): c.rewards[1].required_tag_count = 2, "搭档条件")
	rejected("Unknown reward prerequisite", func(c): c.rewards[0].required_tag = "missing", "搭档条件")
	rejected("Unknown program", func(c): c.rewards[6].program_id = "missing", "程序不存在")
	rejected("Unsupported modifier program", func(c): c.rewards[6].program_id = "repair", "仅支持反冲")
	rejected("Empty program modifier", func(c): c.rewards[6].program_duration_bonus = 0, "至少一个增益")
	rejected("Program modifier on training", func(c): c.rewards[2].program_damage_bonus = 1, "仅用于程序")
	rejected("Nonfinite program duration", func(c): c.rewards[6].program_duration_bonus = INF, "数值非法")
	rejected("Negative program damage", func(c): c.rewards[7].program_damage_bonus = -1, "数值非法")
	rejected("Null reaction", func(c): c.synergies[0].effects.append(null), "空效果")
	rejected_proc("Duplicate reaction ID", func(proc,c): c.synergies[0].effects.append(proc), "效果ID")
	rejected_proc("Unknown reaction effect", func(proc,_c): proc.effect = "unknown", "未知")
	rejected_proc("Unknown reaction target", func(proc,_c): proc.target = "unknown", "规则非法")
	rejected_proc("Targetless trigger with skill target", func(proc,_c):
		proc.trigger = "half_health"
		proc.target = "skill_target", "没有技能目标")
	rejected_proc("Actionless trigger with action scope", func(proc,_c): proc.limit = "action", "没有动作编号")
	rejected_proc("Unknown prerequisite tag", func(proc,_c): proc.required_tag = "missing", "条件标签")
	rejected_proc("Nonfinite effect value", func(proc,_c): proc.value = INF, "效果数值")
	rejected_proc("Missing haste duration", func(proc,_c):
		proc.effect = "attack_speed"
		proc.value = 1.2, "持续时间")
	rejected_proc("Damage bonus wrong phase", func(proc,_c): proc.effect = "damage_bonus", "加成触发")
	rejected_proc("Invalid code amount", func(proc,_c):
		proc.effect = "hack"
		proc.code_amount = 0, "代码产出")
	rejected_proc("Invalid code type", func(proc,_c):
		proc.effect = "hack"
		proc.code_type = "black", "代码产出")
	rejected("Pierce wrong phase", func(c): c.rewards[4].effects[0].trigger = "skill_impact", "穿透须")
	rejected("Invalid vulnerability lifetime", func(c): c.vulnerability_duration = NAN, "漏洞时限")
	check(Validator.validate(Manifest).is_empty(), "Mutation fixtures keep shipped resources unchanged")
	print("COMBAT_CONTENT_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
