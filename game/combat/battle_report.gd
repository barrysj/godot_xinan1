extends RefCounted
## Bounded accounting fed by resolved simulation events, independent of rendering.
const Codes = preload("res://game/combat/code_catalog.gd")
const METRICS := ["damage", "healing", "received", "shield_given", "shield_gain", "absorbed", "attacks", "skills"]
var counters := {}
var deaths := {}
var down_since := {}
var downtime := {}
var item_shield := 0.0
var first_core := -1.0
var program_damage := 0.0
var program_healing := 0.0
var program_shield := 0.0
var converted := {}

func reset(roster: Array[Dictionary]) -> void:
	counters.clear()
	deaths.clear()
	down_since.clear()
	downtime.clear()
	item_shield = 0.0
	converted.clear()
	first_core = -1.0
	program_damage = 0
	program_healing = 0
	program_shield = 0
	for unit in roster:
		var row := {}
		for key in METRICS: row[key] = 0.0
		counters[unit.id] = row

func observe(event: Dictionary, program_effect: bool = false) -> void:
	var actor: Dictionary = counters.get(event.actor_id, {})
	var target: Dictionary = counters.get(event.target_id, {})
	if event.kind == "revived" and down_since.has(event.target_id):
		downtime[event.target_id] = downtime.get(event.target_id,0.0) + event.time - down_since[event.target_id]
		down_since.erase(event.target_id)
	if event.kind == "action_released" and not actor.is_empty():
		var key := "skills" if event.get("action_kind", "attack") == "cast" else "attacks"
		actor[key] += 1
	elif event.kind == "hack_completed":
		if first_core < 0 and event.get("choice", "") in ["disconnect", "redirect"]: first_core = event.time
	elif event.kind == "impact" and not target.is_empty():
		var actual := maxf(0, event.get("actual", 0.0))
		match event.effect:
			"damage":
				target.received += actual
				target.absorbed += maxf(0, event.get("blocked", 0.0))
				if program_effect: program_damage += actual
				elif not actor.is_empty(): actor.damage += actual
				if event.get("hp",1.0) <= 0:
					if not deaths.has(event.target_id): deaths[event.target_id] = event.time
					if not down_since.has(event.target_id): down_since[event.target_id] = event.time
			"heal":
				if program_effect: program_healing += actual
				elif not actor.is_empty(): actor.healing += actual
			"shield":
				target.shield_gain += actual
				if event.get("item_effect",false): item_shield += actual
				elif program_effect: program_shield += actual
				elif not actor.is_empty(): actor.shield_given += actual

func snapshot(simulation, skipped: bool = false) -> Dictionary:
	var rows: Array[Dictionary] = []
	for unit in simulation.units:
		var row: Dictionary = counters[unit.id].duplicate()
		row.merge({"id":unit.id, "name":unit.get("name", "单位"), "content_id":unit.get("content_id", ""),
			"side":unit.side, "slot":unit.slot, "hp":maxf(0,unit.hp), "max_hp":unit.max_hp,
			"alive_time":maxf(0.0,down_since.get(unit.id,simulation.elapsed)-downtime.get(unit.id,0.0)), "defeated":unit.hp <= 0, "first_defeat":deaths.get(unit.id,-1.0)})
		rows.append(row)
	var consumed: Dictionary = simulation.spent.duplicate()
	for kind in converted: consumed[kind] = consumed.get(kind, 0) + converted[kind]
	return {"version":1, "duration":simulation.elapsed, "rows":rows, "first_core":first_core,
		"item_shield":item_shield, "program_damage":program_damage, "program_healing":program_healing, "program_shield":program_shield, "skipped":skipped,
		"program_uses":simulation.program_uses.duplicate(), "generated":simulation.generated.duplicate(),
		"spent":consumed, "overflow":simulation.overflow.duplicate(), "remaining":simulation.blocks.duplicate()}

static func numeric(value, minimum: float = 0.0, maximum: float = 1000000000.0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum

## Optional extension of the original checkpoints. Missing means a legacy report.
static func valid_snapshot(value) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if value.get("version") != 1 or not numeric(value.get("duration"),0,1000): return false
	var duration: float = value.duration
	if not numeric(value.get("first_core"),-1,duration): return false
	if not value.get("skipped") is bool: return false
	if not numeric(value.get("item_shield",0)): return false
	for key in ["program_damage", "program_healing", "program_shield"]:
		if not numeric(value.get(key)): return false
	for key in ["generated", "spent", "overflow", "remaining", "program_uses"]:
		if not value.get(key) is Dictionary: return false
		for id in value[key]:
			if not id is String or not numeric(value[key][id]) or value[key][id] != int(value[key][id]): return false
			if key == "program_uses":
				if Codes.program(id) == null: return false
			elif not Codes.RULES.types.has(id): return false
	if not value.get("rows") is Array or value.rows.size() > 12: return false
	var ids := {}
	var slots := {}
	for row in value.rows:
		if not row is Dictionary or not row.get("name") is String or not row.get("content_id") is String: return false
		if not numeric(row.get("id"),0,11) or row.id != int(row.id) or ids.has(row.id): return false
		if not numeric(row.get("side"),0,1) or row.side != int(row.side): return false
		if not numeric(row.get("slot"),0,5) or row.slot != int(row.slot): return false
		var key := "%d/%d" % [row.side, row.slot]
		if slots.has(key): return false
		ids[row.id] = true
		slots[key] = true
		for metric in METRICS:
			if not numeric(row.get(metric)): return false
		for metric in ["attacks", "skills"]:
			if row[metric] != int(row[metric]): return false
		if not numeric(row.get("max_hp"),1) or not numeric(row.get("hp"),0,row.max_hp): return false
		if not numeric(row.get("first_defeat",-1),-1,duration): return false
		if not numeric(row.get("alive_time"),0,duration) or not row.get("defeated") is bool: return false
	return true
