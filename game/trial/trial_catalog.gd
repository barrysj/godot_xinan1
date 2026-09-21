extends RefCounted
## Small, explicit balance surface for the three-battle trial; no main-campaign IDs.
const ROLES = ["guard", "archer", "healer", "analyst", "inventor", "striker"]
const NAMES = ["守护者", "远射手", "应援者", "分析员", "发明家", "冲刺手"]
const TAGS = [["运动社", "守护"], ["运动社", "突击"], ["广播站", "守护"], ["广播站", "解析"], ["创客社", "解析"], ["创客社", "突击"]]
const TRAITS = {
	"运动社": "成员开场获得40点护盾，持续6秒。",
	"广播站": "首次验证漏洞，治疗生命比例最低的友军45点。",
	"创客社": "破解完成后，成员攻击间隔缩短25%，持续8秒。",
	"守护": "成员首次降至半血，各获得45点护盾。",
	"突击": "成员首次伤害技能命中，附加25点基础伤害。",
	"解析": "成员首次技能命中，各额外贡献12点破解。"
}
const DESCRIPTIONS = ["保护自身与附近队友。", "技能优先射击射程内后排。", "治疗生命比例最低的队友。", "技能暴露4秒漏洞；另一位队友普攻验证，破解+16。", "范围技能额外贡献4点破解。", "技能追击射程内生命比例最低的敌人。"]
const BATTLES = [
	{"name": "入口校验", "hint": "两名守卫。观察漏洞标记与队友验证。", "pulse": 6.0, "shield": 70.0},
	{"name": "访问拦截", "hint": "巡检者威胁后排。保护分析员，或先消除威胁。", "pulse": 6.0, "shield": 70.0},
	{"name": "回滚守卫", "hint": "Boss周期性群体攻击。决定立即破盾还是持续保护。", "pulse": 5.0, "shield": 90.0}
]
const REWARDS = {
	"cover": {"name": "并肩防护", "kind": "羁绊", "text": "守护成员半血触发时，同时保护两格内生命比例最低的另一名友军。"},
	"lens": {"name": "调试镜片", "kind": "装备", "text": "佩戴者每场首次技能命中暴露漏洞。战前可转移，每人一件。"},
	"training": {"name": "集中训练", "kind": "训练", "text": "选择一人，本局生命与攻击提高15%；绑定人物，候补保留。"},
	"verify": {"name": "协同验证", "kind": "分析员专属", "text": "分析员的漏洞允许两位不同队友各验证一次。"},
	"pierce": {"name": "贯穿射击", "kind": "远射手专属", "text": "伤害技能沿射线额外命中一名敌人，造成60%伤害。"},
	"backup": {"name": "应急备份", "kind": "装备", "text": "佩戴者每场首次降至半血，获得最大生命25%的护盾。战前可转移。"}
}
const Skill = preload("res://game/content/skill_def.gd")
const Effect = preload("res://game/content/effect_def.gd")
const AutoBattle = preload("res://game/combat/auto_battle.gd")

static func definition(index: int):
	var id: String = ROLES[index] if index != 3 else "inventor"
	return load("res://resources/content/characters/" + id + ".tres")

static func active_tags(formation: Array) -> Array[String]:
	var counts := {}
	var result: Array[String] = []
	for index in formation:
		if index < 0: continue
		for tag in TAGS[index]: counts[tag] = counts.get(tag, 0) + 1
	for tag in TRAITS:
		if counts.get(tag, 0) >= 2: result.append(tag)
	return result

static func make_unit(definition_resource, role: int, side: int, slot: int) -> Dictionary:
	var d = definition_resource
	return {"id": 0, "name": d.display_name, "role": role, "side": side, "slot": slot,
		"max_hp": float(d.health), "hp": float(d.health), "atk": float(d.attack),
		"interval": d.interval, "timer": d.interval, "def": float(d.defense), "shield": 0.0,
		"count": 0, "flash": 0.0, "damage": 0.0, "healing": 0.0,
		"attack_range": d.attack_range, "move_speed": d.move_speed,
		"skill": d.skill, "action_profile": d.action_profile, "portrait": d.portrait}

static func enemy(name: String, slot: int, hp: float, attack: float, rule: String = "normal") -> Dictionary:
	var u = make_unit(definition(0), -1, 1, slot)
	u.name = name
	u.portrait = load("res://resources/content/enemies/board.tres").portrait
	u.max_hp = hp
	u.hp = hp
	u.atk = attack
	u.interval = 2.0
	u.timer = 2.0
	u.def = 8.0
	u.attack_range = 4.5 if rule != "normal" else 1.45
	var skill = Skill.new()
	var effect = Effect.new()
	effect.kind = "damage"
	effect.target = rule
	effect.attack_scale = 1.2 if rule == "all_enemies" else 1.8
	skill.effects.append(effect)
	u.skill = skill
	return u

static func roster(formation: Array, battle: int, rewards: Array, gear: Dictionary, trainee: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(6):
		var index: int = formation[slot]
		if index < 0: continue
		var u = make_unit(definition(index), index, 0, slot)
		u.name = NAMES[index]
		if index == 3:
			u.skill = Skill.new()
			var effect = Effect.new()
			effect.attack_scale = 1.0
			u.skill.effects.append(effect)
			u.attack_range = 3.5
			u.max_hp = 220.0
			u.hp = 220.0
			u.atk = 22.0
			u.interval = 1.6
			u.timer = 1.6
		if rewards.has("training") and trainee == index:
			u.max_hp *= 1.15
			u.hp = u.max_hp
			u.atk *= 1.15
		u.gear = ""
		for item in gear:
			if gear[item] == index: u.gear = item
		result.append(u)
	match battle:
		0: result.append_array([enemy("入口守卫", 0, 680, 23), enemy("校验守卫", 2, 680, 23)])
		1: result.append_array([enemy("拦截守卫", 1, 750, 25), enemy("后排巡检者", 3, 520, 28, "back"), enemy("巡检护卫", 2, 440, 23)])
		2: result.append_array([enemy("回滚守卫", 1, 1700, 32, "all_enemies"), enemy("支援代理", 3, 550, 25, "back")])
	for i in range(result.size()):
		result[i].id = i
		AutoBattle.initialize(result[i])
	return result
