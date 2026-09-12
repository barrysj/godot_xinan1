extends RefCounted
## Deterministic simulation. Views consume snapshots, never decide damage timing.
const AutoBattle = preload("res://game/combat/auto_battle.gd")
const Profile = preload("res://game/content/battle_action_profile.gd")
var units: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var events: Array[Dictionary] = []
var elapsed := 0.0
var closing := false
var finished := false
var won := false
var next_action_id := 0
var active_action_id := -1

func reset(roster: Array[Dictionary]) -> void:
	units = roster
	projectiles.clear()
	events.clear()
	elapsed = 0
	closing = false
	finished = false
	won = false
	next_action_id = 0
	for u in units:
		u.action = {}
		u.previous_position = u.position
		u.facing = Vector2.UP if u.side == 0 else Vector2.DOWN
		if u.get("action_profile") == null: u.action_profile = Profile.new()

func unit(id: int) -> Dictionary:
	for u in units:
		if u.id == id: return u
	return {}

func _emit(kind: String, actor: Dictionary, target: Dictionary, action_id: int, extra: Dictionary = {}) -> void:
	var snapshot = {"kind": kind, "time": elapsed, "action_id": action_id,
		"actor_id": actor.id, "target_id": target.id,
		"from": actor.position, "to": target.position}
	snapshot.merge(extra, true)
	events.append(snapshot)

## Shared request boundary. Future manual abilities/items add explicit kinds here.
## Unsupported kinds are rejected rather than silently becoming basic attacks.
func request_action(actor_id: int, target_id: int, kind: StringName = &"attack") -> bool:
	var actor = unit(actor_id)
	var target = unit(target_id)
	if kind != &"attack" or closing or finished or actor.is_empty() or target.is_empty(): return false
	if actor.hp <= 0 or target.hp <= 0 or actor.side == target.side: return false
	if actor.moving or not actor.action.is_empty() or actor.timer > 0.00001: return false
	if not AutoBattle.in_range(actor, target): return false
	var timing: Vector2 = actor.action_profile.timing(actor.interval)
	next_action_id += 1
	actor.action = {"id": next_action_id, "target_id": target.id, "age": 0.0,
		"windup": timing.x, "duration": timing.x + timing.y, "released": false,
		"phase": "windup", "casts": actor.count + 1 >= actor.skill.attacks_to_trigger}
	actor.timer = actor.interval
	actor.facing = actor.position.direction_to(target.position)
	_emit("action_started", actor, target, next_action_id, {"casts": actor.action.casts,
		"windup": timing.x, "duration": timing.x + timing.y})
	return true

func advance(delta: float) -> Array[Dictionary]:
	if finished: return []
	elapsed += delta
	var due: Array[Dictionary] = []
	if _living(0).is_empty() or _living(1).is_empty() or elapsed >= 90: closing = true
	for actor in units:
		actor.previous_position = actor.position
		if actor.hp <= 0 or closing:
			if not actor.action.is_empty():
				_emit("action_cancelled", actor, actor, actor.action.id)
			actor.action = {}
			continue
		if not actor.action.is_empty():
			actor.timer = maxf(0, actor.timer - delta)
			actor.action.age += delta
			if not actor.action.released and actor.action.age + 0.00001 >= actor.action.windup:
				_release(actor, due)
			if actor.action.age + 0.00001 >= actor.action.duration:
				_emit("action_finished", actor, actor, actor.action.id)
				actor.action = {}
			continue
		var target = AutoBattle.advance(actor, units, delta)
		if actor.position != actor.previous_position:
			actor.facing = actor.previous_position.direction_to(actor.position)
		if not target.is_empty(): request_action(actor.id, target.id)
	# New projectiles are visible at their launch point for one simulation step.
	for shot in projectiles:
		shot.previous_position = shot.position
		var target = unit(shot.target_id)
		if target.is_empty() or target.hp <= 0:
			shot.done = true
			_emit("projectile_expired", unit(shot.actor_id), unit(shot.actor_id), shot.action_id)
			continue
		if shot.spawn_time == elapsed: continue
		shot.position = shot.position.move_toward(target.position, shot.speed * delta)
		if shot.position.is_equal_approx(target.position):
			due.append(shot.effect)
			shot.done = true
	projectiles = projectiles.filter(func(p): return not p.done)
	_resolve(due)
	if _living(0).is_empty() or _living(1).is_empty() or elapsed >= 90: closing = true
	if closing and projectiles.is_empty():
		for actor in units:
			if not actor.action.is_empty():
				_emit("action_finished" if actor.action.released else "action_cancelled", actor, actor, actor.action.id)
			actor.action = {}
		finished = true
		won = not _living(0).is_empty() and _living(1).is_empty()
	var output: Array[Dictionary] = events.duplicate(true)
	events.clear()
	return output

func _release(actor: Dictionary, due: Array[Dictionary]) -> void:
	var action: Dictionary = actor.action
	action.released = true
	action.phase = "recovery"
	var target = unit(action.target_id)
	if target.is_empty() or not AutoBattle.in_range(actor, target):
		_emit("action_missed", actor, actor, action.id)
		return
	active_action_id = action.id
	var effects: Array[Dictionary] = []
	_event(effects, actor, target, "damage", actor.atk)
	actor.count += 1
	if actor.count >= actor.skill.attacks_to_trigger:
		actor.count = 0
		_skill_events(actor, target, effects)
	_emit("action_released", actor, target, action.id, {"casts": action.casts})
	for effect in effects:
		if effect.kind == "damage" and actor.action_profile.is_projectile(actor.attack_range):
			projectiles.append({"action_id": action.id, "actor_id": actor.id,
				"target_id": effect.target.id, "position": actor.position,
				"previous_position": actor.position, "speed": maxf(1, actor.action_profile.projectile_speed),
				"spawn_time": elapsed, "effect": effect, "special": effect.special, "done": false})
		else:
			due.append(effect)
func _living(side: int) -> Array[Dictionary]:
	return units.filter(func(u): return u.side == side and u.hp > 0)

func _target(actor: Dictionary, candidates: Array[Dictionary], rule: String = "normal") -> Dictionary:
	var best: Dictionary = {}
	var best_score = INF
	for u in candidates:
		var score: float
		if rule == "low":
			score = u.hp / u.max_hp * 1000.0 + u.slot * 0.001
		elif rule == "back":
			score = u.position.y if actor.side == 0 else -u.position.y
		else:
			score = AutoBattle.distance(actor, u)
		if score < best_score:
			best_score = score
			best = u
	return best

func _event(events: Array[Dictionary], actor: Dictionary, target: Dictionary, kind: String, value: float, special: bool = false) -> void:
	if not target.is_empty():
		events.append({"actor": actor, "target": target, "kind": kind, "value": value, "special": special, "action_id": active_action_id})


func _skill_events(actor: Dictionary, target: Dictionary, events: Array[Dictionary]) -> void:
	var foes = _living(1 - actor.side)
	var allies = _living(actor.side)
	for effect in actor.skill.effects:
		var targets: Array[Dictionary] = []
		match effect.target:
			"self": targets = [actor]
			"all_allies": targets = allies
			"all_enemies": targets = foes
			"adjacent":
				for ally in allies:
					if AutoBattle.distance(actor, ally) <= 2.05: targets.append(ally)
			"row":
				var first = target
				if not first.is_empty():
					for foe in foes:
						if absf(foe.position.y - first.position.y) <= 0.5 and AutoBattle.in_range(actor, foe): targets.append(foe)
			_:
				var candidates = allies if effect.target == "low_ally" else foes.filter(func(foe): return AutoBattle.in_range(actor, foe))
				targets = [_target(actor, candidates, "low" if effect.target.begins_with("low") else effect.target)]
		for skill_target in targets: _event(events,actor,skill_target,effect.kind,effect.value+actor.atk*effect.attack_scale,true)

func _resolve(events: Array[Dictionary]) -> void:
	# Collect every action before resolving; support precedes simultaneous damage.
	for e in events:
		if e.kind == "shield":
			e.actual = minf(e.value, 144 - e.target.shield)
			e.target.shield = minf(e.target.shield + e.value, 144)
		elif e.kind in ["max_hp", "attack", "interval"]:
			e.actual = e.value
			if e.kind == "max_hp":
				e.target.max_hp = minf(100000, e.target.max_hp + e.value)
				e.target.hp = minf(e.target.max_hp, e.target.hp + e.value)
			elif e.kind == "attack": e.target.atk = minf(10000, e.target.atk + e.value)
			else: e.target.interval = clampf(e.value, 0.1, 10)
		elif e.kind == "heal":
			var healed = minf(e.value, e.target.max_hp - e.target.hp)
			e.actual = healed
			e.target.hp += healed
			e.actor.healing += healed
	for e in events:
		if e.kind == "damage":
			var damage = maxf(1, roundf(e.value * 100.0 / (100.0 + e.target.def)))
			var blocked = minf(damage, e.target.shield)
			e.actual = minf(maxf(0, e.target.hp), damage - blocked)
			e.blocked = blocked
			e.shield_break = e.target.shield > 0 and blocked >= e.target.shield
			e.target.shield -= blocked
			e.target.hp = maxf(0, e.target.hp - (damage - blocked))
			e.actor.damage += e.actual
			e.target.flash = 0.2


	for e in events:
		_emit("impact", e.actor, e.target, e.action_id, {"effect": e.kind, "value": e.value,
			"actual": e.get("actual", 0.0), "special": e.special,
			"blocked": e.get("blocked", 0), "shield_break": e.get("shield_break", false),
			"hp": maxf(0, e.target.hp), "max_hp": e.target.max_hp, "shield": e.target.shield})
