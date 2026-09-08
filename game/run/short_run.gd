extends RefCounted
## The short expedition owns route progress and all between-battle upgrades.

const STAGES = [
	[{"id": "gate", "name": "旧校门", "kind": "battle", "encounter": 0, "power": 0.62, "description": "纸甲守卫挡住了归校的路。\n先观察敌阵，试试保护后排。"}],
	[{"id": "library", "name": "图书角", "kind": "event", "encounter": 0, "power": 0.0, "description": "翻开旧借阅册，找到同学留下的补给。\n无需战斗，选择一项构筑奖励。"},
	 {"id": "court", "name": "篮球场", "kind": "elite", "encounter": 0, "power": 0.82, "description": "守卫与治疗者结伴巡游。\n额外获得 1 点修复资源。"}],
	[{"id": "hall", "name": "教学走廊", "kind": "battle", "encounter": 0, "power": 0.92, "description": "回声广播不断治疗敌人。\n后排打击可以打破僵局。"},
	 {"id": "lab", "name": "实验室", "kind": "battle", "encounter": 1, "power": 0.8, "description": "黑板释放整排攻击。\n尝试分散站位、提前叠盾。"}],
	[{"id": "supply", "name": "同学补给站", "kind": "event", "encounter": 0, "power": 0.0, "description": "探索途中的一次整备。\n选择装备、训练或新伙伴。"},
	 {"id": "classroom", "name": "异变教室", "kind": "elite", "encounter": 1, "power": 1.0, "description": "更强的整排攻击与后排投手。\n胜利额外获得 1 点修复资源。"}],
	[{"id": "boss", "name": "终点 · 放学铃", "kind": "boss", "encounter": 1, "power": 1.25, "description": "粉笔巨像守住校园最后的裂隙。\n用这一局的构筑，让放学铃重新响起。"}]
]

var stage = 0
var visited: Array[String] = []
var node: Dictionary = {}
var roster: Array[int] = [0, 1, 2, 3]
var formation: Array = [0, -1, 3, 2, 1, -1]
const Content = preload("res://game/content/content_db.gd")
var inventory: Dictionary = {"shoe": 0}
var shoe_wearer: int:
	get: return int(inventory.get("shoe", -1))
	set(value): inventory["shoe"] = value
var badge_wearer: int:
	get: return int(inventory.get("badge", -1))
	set(value):
		if badge_owned or value >= 0: inventory["badge"] = value
var badge_owned: bool:
	get: return inventory.has("badge")
	set(value):
		if value and not inventory.has("badge"): inventory["badge"] = -1
		elif not value: inventory.erase("badge")

func grant_gear(id: String) -> bool:
	if Content.gear(id) == null or inventory.has(id): return false
	inventory[id] = -1
	return true

func equip_gear(id: String, role: int) -> bool:
	if not roster.has(role) or (id != "none" and not inventory.has(id)): return false
	for key in inventory:
		if inventory[key] == role: inventory[key] = -1
	if id != "none": inventory[id] = role
	return true

func worn_gear(role: int) -> String:
	for key in inventory:
		if inventory[key] == role: return key
	return "empty"

var training: Dictionary = {}
var points = 0
var retries = 0
var reward_taken = false
var settled = false
var run_id = Crypto.new().generate_random_bytes(16).hex_encode()
var permanent_hp = 0
const Rewards = preload("res://game/run/reward_catalog.gd")
var route_seed = -1
var stages: Array = STAGES.duplicate(true)
var reward_ids: Array = []

func generate(seed_value: int = -1) -> void:
	route_seed = seed_value if seed_value >= 0 else int(Crypto.new().generate_random_bytes(4).decode_u32(0) & 0x7fffffff)
	stages = generated_stages(route_seed)

static func shuffle_with(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size()-1,0,-1):
		var j = rng.randi_range(0,i)
		var old = items[i]
		items[i] = items[j]
		items[j] = old

static func generated_stages(seed_value: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var safe = [STAGES[1][0],STAGES[2][0],STAGES[2][1],STAGES[3][0]].duplicate(true)
	shuffle_with(safe,rng)
	var risk = [safe.pop_back(),STAGES[1][1].duplicate(true),STAGES[3][1].duplicate(true)]
	shuffle_with(risk,rng)
	var generated: Array = [STAGES[0].duplicate(true)]
	for i in range(3):
		var layer = [safe[i],risk[i]]
		for place in layer:
			if place.kind != "event": place.power = (0.78 if place.kind == "elite" else 0.68) + i * 0.10
		shuffle_with(layer,rng)
		generated.append(layer)
	generated.append(STAGES[4].duplicate(true))
	return generated

func roll_rewards() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = (str(route_seed)+":"+str(stage)+":"+str(node.get("id",""))).hash()
	var pool = Rewards.eligible(badge_owned,roster,inventory).duplicate(true)
	shuffle_with(pool,rng)
	reward_ids.clear()
	for i in range(3): reward_ids.append(pool[i].id)

func _legacy_dict() -> Dictionary:
	var saved_training = {}
	for role in training: saved_training[str(role)] = int(training[role])
	return {"schema":3, "legacy_schema":2 if route_seed >= 0 else 1, "inventory":inventory.duplicate(), "seed":route_seed, "reward_ids":reward_ids.duplicate(), "id":run_id, "stage":stage, "visited":visited.duplicate(),
		"node_id":node.get("id", ""), "roster":roster.duplicate(), "formation":formation.duplicate(),
		"shoe_wearer":shoe_wearer, "badge_wearer":badge_wearer, "badge_owned":badge_owned,
		"training":saved_training, "points":points, "retries":retries, "reward_taken":reward_taken,
		"settled":settled, "permanent_hp":permanent_hp}

func to_dict() -> Dictionary:
	var data = _legacy_dict()
	data.schema = 4
	data.roster = roster.map(func(role): return Content.role_id(role))
	data.formation = formation.map(func(role): return "" if role == -1 else Content.role_id(role))
	data.training = {}
	for role in training: data.training[Content.role_id(role)] = training[role]
	data.inventory = {}
	for id in inventory: data.inventory[id] = "" if inventory[id] == -1 else Content.role_id(inventory[id])
	data.erase("shoe_wearer")
	data.erase("badge_wearer")
	data.erase("badge_owned")
	return data

func restore(data: Dictionary) -> bool:
	var candidate = get_script().new()
	var source = data.duplicate(true)
	var items = {}
	if data.get("schema") == 4:
		for key in ["roster", "formation"]:
			if not data.get(key) is Array: return false
			var converted = []
			for id in data[key]:
				if not id is String: return false
				if id.is_empty() and key == "formation": converted.append(-1)
				elif Content.role_index(id) < 0: return false
				else: converted.append(Content.role_index(id))
			source[key] = converted
		for key in ["training", "inventory"]:
			if not data.get(key) is Dictionary: return false
			source[key] = {}
			for id in data[key]:
				if not id is String: return false
				if key == "training":
					if Content.role_index(id) < 0: return false
					source.training[str(Content.role_index(id))] = data.training[id]
				else:
					var owner = data.inventory[id]
					if not owner is String or (not owner.is_empty() and Content.role_index(owner) < 0): return false
					source.inventory[id] = -1 if owner.is_empty() else Content.role_index(owner)
		source.schema = 3
	if source.get("schema") == 3:
		if not source.get("inventory") is Dictionary: return false
		items = source.inventory.duplicate()
		source.schema = data.get("legacy_schema", 0)
		var owners = []
		for id in items:
			var owner = items[id]
			if not id is String or Content.gear(id) == null: return false
			if not (owner is int or owner is float) or not is_finite(owner) or int(owner) != owner: return false
			if owner != -1 and (not source.get("roster", []).has(owner) or owners.has(owner)): return false
			if owner != -1: owners.append(owner)
		if not items.has("shoe"): return false
		source.shoe_wearer = items.shoe
		source.badge_owned = items.has("badge")
		source.badge_wearer = items.get("badge", -1)
	if not candidate._restore_legacy(source): return false
	if not items.is_empty(): candidate.inventory = items
	for property in candidate.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(property.name, candidate.get(property.name))
	return true

func _restore_legacy(data: Dictionary) -> bool:
	if data.get("schema",0) != 1 and data.get("schema",0) != 2: return false
	if not data.get("id",null) is String: return false
	var restored_seed = -1
	var restored_stages: Array = STAGES.duplicate(true)
	if data.schema == 2:
		var value = data.get("seed",null)
		if not (value is int or value is float) or value < 0 or value > 2147483647 or int(value) != value: return false
		restored_seed = int(value)
		restored_stages = generated_stages(restored_seed)
	if data.id.is_empty(): return false
	for key in ["stage","shoe_wearer","badge_wearer","retries","permanent_hp"]:
		var value = data.get(key,0)
		if not (value is int or value is float) or not is_finite(float(value)) or int(value) != value: return false
	for key in ["badge_owned","reward_taken","settled"]:
		if not data.get(key,false) is bool: return false
	var saved_stage = int(data.get("stage",-1))
	if saved_stage < 0 or saved_stage > STAGES.size(): return false
	if not data.get("visited",null) is Array or data.visited.size() != saved_stage: return false
	var restored_visited: Array[String] = []
	var derived_points = 0
	for i in range(saved_stage):
		var found = false
		for item in restored_stages[i]:
			if item.id == data.visited[i]:
				found = true
				derived_points += 3 if item.kind == "boss" else (2 if item.kind == "elite" else 1)
		if not found: return false
		restored_visited.append(data.visited[i])
	var saved_node: Dictionary = {}
	var node_id = str(data.get("node_id",""))
	if not node_id.is_empty():
		if saved_stage >= STAGES.size(): return false
		for item in restored_stages[saved_stage]:
			if item.id == node_id: saved_node = item.duplicate(true)
		if saved_node.is_empty(): return false
	if not data.get("roster",null) is Array or not data.get("formation",null) is Array: return false
	var restored_roster: Array[int] = []
	for value in data.roster:
		if not (value is int or value is float) or int(value) != value: return false
		var role = int(value)
		if role < 0 or role >= Content.characters().size() or restored_roster.has(role): return false
		restored_roster.append(role)
	for role in range(4):
		if not restored_roster.has(role): return false
	if data.formation.size() != 6: return false
	var restored_formation: Array = []
	var active: Array[int] = []
	for value in data.formation:
		if not (value is int or value is float) or int(value) != value: return false
		var role = int(value)
		if role != -1:
			if not restored_roster.has(role) or active.has(role): return false
			active.append(role)
		restored_formation.append(role)
	if active.size() != 4: return false
	var shoe = int(data.get("shoe_wearer",-1))
	var badge = int(data.get("badge_wearer",-1))
	if shoe != -1 and not restored_roster.has(shoe): return false
	if badge != -1 and (not restored_roster.has(badge) or not data.get("badge_owned",false)): return false
	if shoe >= 0 and shoe == badge: return false
	if not data.get("training",{}) is Dictionary: return false
	var restored_training = {}
	for key in data.get("training",{}):
		if not str(key).is_valid_int(): return false
		var value = data.training[key]
		if not (value is int or value is float) or not is_finite(float(value)) or int(value) != value: return false
		var role = int(key)
		var count = int(data.training[key])
		if not restored_roster.has(role) or count < 0 or count > 100: return false
		restored_training[role] = count
	run_id = data.id
	stage = saved_stage
	visited = restored_visited
	node = saved_node
	roster = restored_roster
	formation = restored_formation
	shoe_wearer = shoe
	badge_wearer = badge
	badge_owned = bool(data.get("badge_owned",false))
	training = restored_training
	points = derived_points
	retries = maxi(0,int(data.get("retries",0)))
	reward_taken = bool(data.get("reward_taken",false))
	settled = bool(data.get("settled",false))
	permanent_hp = clampi(int(data.get("permanent_hp",0)),0,60)
	route_seed = restored_seed
	stages = restored_stages
	reward_ids = []
	if restored_seed >= 0:
		if not data.get("reward_ids",null) is Array: return false
		for id in data.reward_ids:
			if not id is String or Rewards.find(id).is_empty() or reward_ids.has(id): return false
			reward_ids.append(id)
		if not node.is_empty() and reward_ids.size() != 3: return false
		if node.is_empty() and not reward_ids.is_empty(): return false
		if not reward_taken:
			for id in reward_ids:
				if id == "badge" and badge_owned: return false
				if id == "recruit" and roster.has(4): return false
				if id == "inventor_training" and not roster.has(4): return false
	return true

func choose(index: int) -> bool:
	if stage >= stages.size() or index < 0 or index >= stages[stage].size() or not node.is_empty():
		return false
	node = stages[stage][index].duplicate(true)
	reward_taken = false
	if route_seed >= 0: roll_rewards()
	return true

func offers() -> Array[Dictionary]:
	if route_seed >= 0:
		var choices: Array[Dictionary] = []
		for id in reward_ids: choices.append(Rewards.find(id))
		return choices
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
	if Content.gear(id) != null:
		if not grant_gear(id): return false
	if id.begins_with("recruit_"):
		var role = Content.role_index(id.trim_prefix("recruit_"))
		if role < 0 or roster.has(role): return false
		roster.append(role)
	match id:
		"badge": badge_owned = true
		"recruit": roster.append(4)
		"guard_training": _train(0)
		"archer_training": _train(1)
		"inventor_training": _train(4)
		"healer_training": _train(2)
		"striker_training": _train(3)
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
	reward_ids.clear()
	return true
