extends RefCounted
const MANIFEST = preload("res://resources/content/manifest.tres")

static func gear(id: String):
	for item in MANIFEST.equipment:
		if item != null and item.id == id: return item
	return null

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var ids = {}
	for item in MANIFEST.equipment:
		if item == null:
			errors.append("manifest: 装备引用为空")
			continue
		var location = item.resource_path
		if item.id.is_empty() or ids.has(item.id): errors.append(location+": 空 ID 或重复 ID: "+item.id)
		ids[item.id] = true
		if item.display_name.is_empty(): errors.append(location+": 名称为空")
		if item.health_bonus < 0 or item.health_bonus > 10000 or item.attack_bonus < 0 or item.attack_bonus > 1000 or not is_finite(item.interval_multiplier) or item.interval_multiplier < 0.1 or item.interval_multiplier > 3:
			errors.append(location+": 装备数值越界")
	for group in [MANIFEST.characters, MANIFEST.enemies, MANIFEST.skills, MANIFEST.encounters]:
		for item in group:
			if item == null:
				errors.append("manifest: 空引用")
				continue
			if item.id.is_empty() or ids.has(item.id): errors.append(item.resource_path+": 空 ID 或重复 ID: "+item.id)
			ids[item.id] = true
			if item.display_name.is_empty(): errors.append(item.resource_path+": 名称为空")
	for unit in MANIFEST.characters + MANIFEST.enemies:
		if unit == null: continue
		if unit.skill == null or not MANIFEST.skills.has(unit.skill): errors.append(unit.resource_path+": 技能未注册")
		if unit.portrait == null: errors.append(unit.resource_path+": 缺少图像")
		if unit.health < 1 or unit.health > 10000 or unit.attack < 1 or unit.attack > 1000 or unit.defense < 0 or unit.defense > 1000 or not is_finite(unit.interval) or unit.interval < 0.1 or unit.interval > 10: errors.append(unit.resource_path+": 单位数值越界")
	for skill in MANIFEST.skills:
		if skill == null: continue
		if skill.attacks_to_trigger < 1 or skill.attacks_to_trigger > 20 or skill.effects.is_empty(): errors.append(skill.resource_path+": 触发次数或效果为空")
		for effect in skill.effects:
			if effect == null or not effect.kind in ["damage","heal","shield","max_hp","attack","interval"] or not effect.target in ["normal","back","low_enemy","low_ally","adjacent","row","self","all_allies","all_enemies"]:
				errors.append(skill.resource_path+": 无效效果或目标")
			elif not is_finite(effect.value) or not is_finite(effect.attack_scale) or effect.value < 0 or effect.value > 10000 or effect.attack_scale < 0 or effect.attack_scale > 10:
				errors.append(skill.resource_path+": 效果数值越界")
	for group in MANIFEST.encounters:
		if group == null: continue
		if group.units.is_empty() or group.units.size() != group.slots.size(): errors.append(group.resource_path+": 敌群槽位数量不匹配")
		var occupied = []
		for slot in group.slots:
			if slot < 0 or slot > 5 or occupied.has(slot): errors.append(group.resource_path+": 敌群槽位重复或越界")
			occupied.append(slot)
		for unit in group.units:
			if unit == null or not MANIFEST.enemies.has(unit): errors.append(group.resource_path+": 敌人未注册")
	for id in LEGACY_CHARACTERS:
		if not ids.has(id): errors.append("manifest: 缺少旧档身份 "+id)
	for group in [MANIFEST.rewards,MANIFEST.reward_pools,MANIFEST.events,MANIFEST.locations]:
		var local_ids = []
		for item in group:
			if item == null:
				errors.append("manifest: 空内容引用")
				continue
			if item.id.is_empty() or local_ids.has(item.id): errors.append(item.resource_path+": 同类空 ID 或重复 ID: "+item.id)
			local_ids.append(item.id)
	for reward in MANIFEST.rewards:
		if reward == null: continue
		if reward.display_name.is_empty() or reward.amount < 1 or reward.amount > 100: errors.append(reward.resource_path+": 奖励名称或数量无效")
		if not reward.operation in ["gear","recruit","train","points"]: errors.append(reward.resource_path+": 无效奖励操作")
		if reward.operation == "gear" and not MANIFEST.equipment.has(reward.equipment): errors.append(reward.resource_path+": 装备未注册")
		if reward.operation in ["train","recruit"] and not MANIFEST.characters.has(reward.character): errors.append(reward.resource_path+": 人物未注册")
	for pool in MANIFEST.reward_pools:
		if pool == null: continue
		var unique = []
		var renewable = []
		for reward in pool.rewards:
			if reward == null or not MANIFEST.rewards.has(reward) or unique.has(reward): errors.append(pool.resource_path+": 奖励未注册或重复")
			else:
				unique.append(reward)
				if reward.operation == "train" and reward.character != null and reward.character.id in LEGACY_CHARACTERS.slice(0,4): renewable.append(reward)
		if renewable.size() < 3: errors.append(pool.resource_path+": 至少保留三项初始人物训练，确保奖励可抽取")
	for event in MANIFEST.events:
		if event == null: continue
		if event.options.is_empty() or event.options.size() > 3: errors.append(event.resource_path+": 事件选项须为 1 至 3 项")
		var options = []
		for option in event.options:
			if option == null:
				errors.append(event.resource_path+": 空选项")
				continue
			if option.id.is_empty() or options.has(option.id) or option.text.is_empty(): errors.append(event.resource_path+": 选项身份或文字无效")
			options.append(option.id)
			if option.minimum_points < 0 or option.minimum_points > 100 or option.cost < 0 or option.cost > 100: errors.append(event.resource_path+": 条件或支付越界")
			if option.required_character != null and not MANIFEST.characters.has(option.required_character): errors.append(event.resource_path+": 条件人物未注册")
			if option.required_equipment != null and not MANIFEST.equipment.has(option.required_equipment): errors.append(event.resource_path+": 条件装备未注册")
			for reward in option.results:
				if reward == null or not MANIFEST.rewards.has(reward): errors.append(event.resource_path+": 结果奖励未注册")
	var pool_counts = {"start":0,"safe":0,"risk":0,"final":0}
	for place in MANIFEST.locations:
		if place == null: continue
		if not pool_counts.has(place.route_pool): errors.append(place.resource_path+": 路线池无效")
		else: pool_counts[place.route_pool] += 1
		if not place.kind in ["battle","elite","event","boss"] or not is_finite(place.power) or place.power < 0.1 or place.power > 3: errors.append(place.resource_path+": 地点类型或强度无效")
		if place.kind == "event":
			if not MANIFEST.events.has(place.event): errors.append(place.resource_path+": 事件未注册")
		elif not MANIFEST.encounters.has(place.encounter): errors.append(place.resource_path+": 敌群未注册")
		if not MANIFEST.reward_pools.has(place.rewards): errors.append(place.resource_path+": 奖励池未注册")
		if place.route_pool == "final" and place.kind != "boss": errors.append(place.resource_path+": 终点须为首领")
	if pool_counts.start != 1 or pool_counts.final != 1 or pool_counts.safe < 4 or pool_counts.risk < 2: errors.append("manifest: 路线须有 1 起点、1 终点、至少 4 安全地点和 2 风险地点")
	return errors

# 仅用于迁移旧整数身份；不得随展示排序修改。
const LEGACY_CHARACTERS = ["guard", "archer", "healer", "striker", "inventor"]

static func characters() -> Array:
	var result = []
	for id in LEGACY_CHARACTERS:
		for unit in MANIFEST.characters:
			if unit.id == id: result.append(unit)
	for unit in MANIFEST.characters:
		if not LEGACY_CHARACTERS.has(unit.id): result.append(unit)
	return result

static func character(role: int):
	var items = characters()
	return items[role] if role >= 0 and role < items.size() else null

static func role_id(role: int) -> String:
	var item = character(role)
	return item.id if item != null else ""

static func role_index(id: String) -> int:
	var items = characters()
	for i in range(items.size()):
		if items[i].id == id: return i
	return -1

static func encounter(id: String):
	for item in MANIFEST.encounters:
		if item.id == id: return item
	return null
