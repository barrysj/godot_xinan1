extends RefCounted
## The short expedition owns route progress and all between-battle upgrades.

const STAGES = [
	[{"id": "gate", "name": "旧校门", "kind": "battle", "encounter": 0, "power": 0.62, "description": "纸甲守卫挡住了归校的路。\n先观察敌阵，试试保护后排。"}],
	[{"id": "library", "name": "图书角", "kind": "event", "encounter": 0, "power": 0.0, "description": "翻开旧借阅册，找到同学留下的补给。\n无需战斗，选择一项构筑奖励。"},
	 {"id": "court", "name": "篮球场", "kind": "elite", "encounter": 0, "power": 0.82, "description": "守卫与治疗者结伴巡游。\n额外获得 1 点修复资源。"}],
	[{"id": "hall", "name": "教学走廊", "kind": "battle", "encounter": 0, "power": 0.92, "description": "回声广播不断治疗敌人。\n后排打击可以打破僵局。"},
	 {"id": "lab", "name": "实验室", "kind": "battle", "encounter": 1, "power": 0.8, "description": "黑板释放整排攻击。\n尝试分散站位、提前叠盾。"}],
	[{"id": "supply", "name": "同学补给站", "kind": "event", "encounter": 0, "power": 0.0, "description": "出发前的最后一次整备。\n选择装备、训练或新伙伴。"},
	 {"id": "classroom", "name": "异变教室", "kind": "elite", "encounter": 1, "power": 1.0, "description": "更强的整排攻击与后排投手。\n胜利额外获得 1 点修复资源。"}],
	[{"id": "boss", "name": "终点 · 放学铃", "kind": "boss", "encounter": 1, "power": 1.25, "description": "粉笔巨像守住校园最后的裂隙。\n用这一局的构筑，让放学铃重新响起。"}]
]

var stage = 0
var visited: Array[String] = []
var node: Dictionary = {}
var roster: Array[int] = [0, 1, 2, 3]
var formation: Array = [0, -1, 3, 2, 1, -1]
var shoe_wearer = 0
var badge_wearer = -1
var badge_owned = false
var training: Dictionary = {}
var points = 0
var retries = 0
var reward_taken = false
var settled = false

func choose(index: int) -> bool:
	if stage >= STAGES.size() or index < 0 or index >= STAGES[stage].size() or not node.is_empty():
		return false
	node = STAGES[stage][index].duplicate(true)
	reward_taken = false
	return true

func offers() -> Array[Dictionary]:
	var equipment_offer = {"id": "badge", "title": "厚笔记本", "description": "生命上限 +80 的装备。\n战前自由分配。\n每位同学只能携带一件装备。"}
	if badge_owned:
		equipment_offer = {"id": "guard_training", "title": "体能训练", "description": "守护者本局生命 +50、攻击 +5。\n可以重复获得。"}
	var recruit_offer = {"id": "recruit", "title": "招募 · 发明家", "description": "新同学加入候补。\n自动对一整排造成伤害。\n战前可替换一名上阵同学。"}
	if roster.has(4):
		recruit_offer = {"id": "inventor_training", "title": "改良实验", "description": "发明家本局生命 +50、攻击 +5。\n即使在候补中也会保留强化。"}
	return [equipment_offer, {"id": "archer_training", "title": "专注训练", "description": "远射手本局生命 +50。\n攻击 +5，不占装备槽。\n可以重复获得。"}, recruit_offer]

func take_reward(id: String) -> bool:
	if node.is_empty() or reward_taken:
		return false
	var valid = false
	for offer in offers():
		if offer.id == id:
			valid = true
	if not valid:
		return false
	match id:
		"badge": badge_owned = true
		"recruit": roster.append(4)
		"guard_training": _train(0)
		"archer_training": _train(1)
		"inventor_training": _train(4)
	reward_taken = true
	return true

func _train(role: int) -> void:
	training[role] = int(training.get(role, 0)) + 1

func complete_node() -> bool:
	if node.is_empty() or visited.has(node.id):
		return false
	visited.append(node.id)
	points += 3 if node.kind == "boss" else (2 if node.kind == "elite" else 1)
	stage += 1
	node = {}
	return true
