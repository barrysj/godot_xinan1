extends RefCounted
## Process-local battle settings. Resources, run builds and save schemas stay authoritative.
const Content = preload("res://game/content/content_db.gd")
const Encounter = preload("res://game/content/encounter_def.gd")
const Commands = preload("res://game/debug/campus_debug.gd")
const BACKGROUNDS = {
	"courtyard": {"name":"庭院 · 日间", "path":"res://assets/art/backgrounds/battle_courtyard/day.png"},
	"lab": {"name":"实验室 · 夜间", "path":"res://assets/art/backgrounds/battle_lab/night.png"},
	"classroom": {"name":"教室 · 异常", "path":"res://assets/art/backgrounds/battle_classroom/anomaly.png"}
}
const STATS = {
	"max_hp": {"name":"生命", "min":1.0, "max":100000.0, "step":1.0},
	"atk": {"name":"攻击", "min":1.0, "max":10000.0, "step":1.0},
	"def": {"name":"防御", "min":0.0, "max":1000.0, "step":1.0},
	"interval": {"name":"攻击间隔", "min":0.1, "max":10.0, "step":0.05},
	"attack_range": {"name":"射程", "min":1.0, "max":6.0, "step":0.05},
	"move_speed": {"name":"移速", "min":0.5, "max":8.0, "step":0.1}
}

static func scope(hub) -> String:
	if hub.run == null or hub.run.node.is_empty(): return ""
	# Saving can reconstruct the build after a failed checkpoint. Persisted run /
	# journey identities keep the same battle scope stable across that rollback.
	return "%s|%s|%s|%s|%s|%s" % [hub.run.run_id, hub.journey.data.get("id",""), hub.run.node.get("id",""), hub.run.node.get("encounter_id",hub.encounter_id), hub.journey.data.get("step",-1), hub.journey.data.get("finale_phase",-1)]

static func active(hub) -> bool:
	return hub.debug_enabled and not hub.debug_battle_tuning.is_empty() and hub.debug_battle_tuning.get("scope","") == scope(hub)

static func enemy(id: String):
	for definition in Content.MANIFEST.enemies:
		if definition.id == id: return definition
	return null

static func ally_row(hub, role: int) -> Dictionary:
	if not active(hub): return {}
	return hub.debug_battle_tuning.get("allies",{}).get(Content.role_id(role),{})

static func ally_role(hub, role: int) -> int:
	return Content.role_index(ally_row(hub,role).get("id",Content.role_id(role)))

static func stats(unit: Dictionary) -> Dictionary:
	var result := {}
	for key in STATS: result[key] = float(unit[key])
	return result

static func default_stats(hub, id: String) -> Dictionary:
	var definition = enemy(id)
	if definition == null: return {}
	var unit: Dictionary = hub._from_definition(definition,-1,1,0)
	var power: float = hub.run.node.get("power",1.0)
	var difficulty: Dictionary = Commands.Difficulties.preset(hub.debug_battle_difficulty)
	unit.max_hp = roundf(unit.max_hp * power * difficulty.health)
	unit.atk = roundf(unit.atk * power * difficulty.attack)
	return stats(unit)

static func defaults(hub) -> Dictionary:
	var rows: Array[Dictionary] = []
	var group = Content.encounter(hub.encounter_id)
	for slot in 6:
		var index: int = group.slots.find(slot)
		var id: String = "" if index < 0 else group.units[index].id
		rows.append({"slot":slot, "id":id, "stats":default_stats(hub,id)})
	return {"scope":scope(hub), "enabled":false, "background":"", "ally_health":1.0, "ally_attack":1.0, "allies":{}, "enemies":rows}

static func snapshot(hub) -> Dictionary:
	if active(hub): return hub.debug_battle_tuning.duplicate(true)
	var result: Dictionary = defaults(hub)
	# Show effective full-health attributes, even when the live battle is damaged.
	for unit in hub.units:
		if unit.side == 1: result.enemies[unit.slot].stats = stats(unit)
	return result

static func validate(hub, settings: Dictionary) -> String:
	if not hub.debug_enabled: return "请从 Debug 启动器进入。"
	var blocked: String = Commands.reason(hub,"restart")
	if not blocked.is_empty(): return blocked
	if settings.get("scope","") != scope(hub): return "当前地点已变化，请重新打开修改器。"
	if typeof(settings.get("enabled")) != TYPE_BOOL: return "战斗配置无效。"
	if settings.get("background","") != "" and not BACKGROUNDS.has(settings.background): return "背景不在现有资源中。"
	for key in ["ally_health", "ally_attack"]:
		var value = settings.get(key)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or value < 0.1 or value > 5.0: return "己方倍率须在0.1至5之间。"
	var rows = settings.get("enemies")
	if typeof(rows) != TYPE_ARRAY or rows.size() != 6: return "敌阵需要六个位置。"
	var slots := {}
	var count := 0
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY or typeof(row.get("slot")) != TYPE_INT: return "敌方位置无效。"
		if row.slot < 0 or row.slot > 5 or slots.has(row.slot): return "敌方位置不能重复或越界。"
		slots[row.slot] = true
		if typeof(row.get("id")) != TYPE_STRING: return "敌人配置无效。"
		if row.id.is_empty(): continue
		if enemy(row.id) == null: return "敌人不在现有清单中。"
		count += 1
		var error: String = validate_stats(row.get("stats"))
		if not error.is_empty(): return error
	if count == 0: return "至少放置一名敌人。"
	var allies = settings.get("allies",{})
	if typeof(allies) != TYPE_DICTIONARY: return "友方配置无效。"
	for anchor in allies:
		var row = allies[anchor]
		if typeof(anchor) != TYPE_STRING or Content.role_index(anchor) < 0 or typeof(row) != TYPE_DICTIONARY: return "友方位置无效。"
		if typeof(row.get("id")) != TYPE_STRING or Content.role_index(row.id) < 0: return "同学不在现有清单中。"
		var error: String = validate_stats(row.get("stats"))
		if not error.is_empty(): return error
	var deployed := {}
	for role in hub.formation:
		if role < 0: continue
		var anchor: String = Content.role_id(role)
		var id: String = allies.get(anchor,{}).get("id",anchor)
		if deployed.has(id): return "同一位同学不能重复部署。"
		deployed[id] = true
	return ""

static func validate_stats(values) -> String:
	if typeof(values) != TYPE_DICTIONARY: return "角色数值无效。"
	for key in STATS:
		var value = values.get(key)
		var rule: Dictionary = STATS[key]
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or value < rule.min or value > rule.max: return rule.name + "超出可调范围。"
	return ""

static func encounter(hub, source):
	if not active(hub): return source
	var result = Encounter.new()
	result.id = source.id
	result.display_name = source.display_name
	result.maintenance_interval = source.maintenance_interval
	result.maintenance_shield = source.maintenance_shield
	for row in hub.debug_battle_tuning.enemies:
		if row.id.is_empty(): continue
		result.units.append(enemy(row.id))
		result.slots.append(row.slot)
	return result

static func apply_stats(hub) -> void:
	if not active(hub): return
	var settings: Dictionary = hub.debug_battle_tuning
	for unit in hub.units:
		if unit.side == 0:
			unit.max_hp = roundf(unit.max_hp * settings.ally_health)
			unit.atk = roundf(unit.atk * settings.ally_attack)
			var row: Dictionary = ally_row(hub,unit.get("deployment_role",unit.role))
			if not row.is_empty():
				for key in STATS: unit[key] = float(row.stats[key])
		else:
			for row in settings.enemies:
				if row.slot == unit.slot:
					for key in STATS: unit[key] = float(row.stats[key])
					break
		unit.hp = unit.max_hp
		unit.timer = unit.interval

static func apply(hub, settings: Dictionary, prepare_only := false) -> String:
	var error: String = validate(hub,settings)
	if not error.is_empty(): return error
	# First commit the ordinary restart with the previous settings. A failed save
	# must not make an uncommitted edit visible to the next battle build.
	if hub.paused: return "请先结束当前调试操作。"
	# Preparation edits are temporary instance changes and need no checkpoint.
	# Applying them never starts the clock; the ordinary Start action does that.
	if hub.phase == "prepare" and hub.screen == "battle":
		hub.debug_battle_tuning = settings.duplicate(true) if settings.enabled else {}
		hub._build_units()
		hub.queue_redraw()
		return ""
	var current_node: Dictionary = hub.run.node.duplicate(true)
	if not Commands.execute(hub,"restart"):
		# Campaign checkpoints intentionally omit the transient battle node. Keep
		# this unchanged encounter context when their rollback rebuilds the run.
		if not hub.campaign_mode.is_empty(): hub.run.node = current_node
		return "重开失败：" + hub.progress.error_message
	var previous: Dictionary = hub.debug_battle_tuning.duplicate(true)
	hub.debug_battle_tuning = settings.duplicate(true) if settings.enabled else {}
	if prepare_only:
		hub._build_units()
		hub.queue_redraw()
		return ""
	hub._start()
	if not hub.last_save_ok:
		hub.debug_battle_tuning = previous
		if not hub.campaign_mode.is_empty(): hub.run.node = current_node
		hub.phase = "prepare"
		hub._build_units()
		return "保存失败，已恢复原配置：" + hub.progress.error_message
	return ""
