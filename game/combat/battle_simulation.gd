extends RefCounted
## Deterministic simulation. Views consume snapshots, never decide damage timing.
const AutoBattle = preload("res://game/combat/auto_battle.gd")
const Profile = preload("res://game/content/battle_action_profile.gd")
const SHIELD_CAP := 144.0
const EPSILON := 0.00001
const CAST_WINDUP := 0.8
const CAST_RECOVERY := 0.2
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
	active_action_id = -1
	for u in units:
		u.action = {}
		u.pending_cast = {}
		u.previous_position = u.position
		u.facing = Vector2.UP if u.side == 0 else Vector2.DOWN
		if u.get("action_profile") == null: u.action_profile = Profile.new()
		u.shield_layers = []
		_sync_shields(u)

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
	if actor.moving or not actor.action.is_empty() or not actor.get("pending_cast", {}).is_empty() or actor.timer > 0.00001: return false
	if not AutoBattle.in_range(actor, target): return false
	var timing: Vector2 = actor.action_profile.timing(actor.interval)
	next_action_id += 1
	actor.action = {"id": next_action_id, "target_id": target.id, "age": 0.0,
		"windup": timing.x, "duration": timing.x + timing.y, "released": false,
		"phase": "windup", "kind": "attack", "casts": false,
		"mode": "ranged" if actor.action_profile.is_projectile(actor.attack_range) else "melee"}
	actor.timer = actor.interval
	actor.facing = actor.position.direction_to(target.position)
	_emit("action_started", actor, target, next_action_id, {"casts": actor.action.casts,
		"windup": timing.x, "duration": timing.x + timing.y, "mode": actor.action.mode})
	return true

func advance(delta: float) -> Array[Dictionary]:
	if finished or not is_finite(delta) or delta <= 0: return []
	elapsed += delta
	var due: Array[Dictionary] = []
	var ordered: Array[Dictionary] = units.duplicate()
	ordered.sort_custom(func(a, b): return a.id < b.id)
	if _living(0).is_empty() or _living(1).is_empty() or elapsed >= 90: closing = true
	# Commit motion globally before windups, range checks, or projectile collisions.
	# All later decisions observe positions from the same simulation timestamp.
	for actor in ordered:
		actor.previous_position = actor.position
		_expire_shields(actor)
		if actor.hp <= 0 or closing: continue
		if actor.action.get("kind", "attack") != "cast": actor.timer = maxf(0, actor.timer - delta)
		if actor.action.is_empty():
			AutoBattle.advance_movement(actor, delta)
			if actor.position != actor.previous_position:
				actor.facing = actor.previous_position.direction_to(actor.position)
	for actor in ordered:
		if actor.hp <= 0 or closing:
			_end_action(actor)
			continue
		if not actor.action.is_empty():
			actor.action.age += delta
			if not actor.action.released and actor.action.age + 0.00001 >= actor.action.windup:
				_release(actor, due)
			if actor.action.age + 0.00001 >= actor.action.duration:
				_emit("action_finished", actor, actor, actor.action.id)
				actor.action = {}
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
			shot.effect.impact_position = target.position
			due.append(shot.effect)
			shot.done = true
	projectiles = projectiles.filter(func(p): return not p.done)
	_resolve(due)
	if _living(0).is_empty() or _living(1).is_empty() or elapsed >= 90: closing = true
	for actor in ordered:
		if actor.hp <= 0:
			_end_action(actor)
			actor.moving = false
			continue
		if closing:
			_end_action(actor)
			continue
		# New requests use the resolved state: no swings at targets killed this tick.
		# A completed recovery or movement may immediately acquire its next action.
		if actor.action.is_empty():
			if _start_pending_action(actor): continue
			var next_target = AutoBattle.advance(actor, units, 0)
			if not next_target.is_empty(): request_action(actor.id, next_target.id)
	if closing and projectiles.is_empty():
		finished = true
		won = not _living(0).is_empty() and _living(1).is_empty()
	var output: Array[Dictionary] = events.duplicate(true)
	events.clear()
	return output

func _end_action(actor: Dictionary) -> void:
	actor.pending_cast = {}
	if actor.action.is_empty(): return
	_emit("action_finished" if actor.action.released else "action_cancelled", actor, actor, actor.action.id)
	actor.action = {}

func _release(actor: Dictionary, due: Array[Dictionary]) -> void:
	var action: Dictionary = actor.action
	action.released = true
	action.phase = "recovery"
	var target = unit(action.target_id)
	if action.kind == "cast":
		active_action_id = action.id
		var cast_effects: Array[Dictionary] = []
		_cast_effects(actor, target, cast_effects)
		_emit("action_released", actor, actor if target.is_empty() else target, action.id, {"casts":true, "action_kind":"cast"})
		_deliver_effects(actor, cast_effects, due)
		return
	if target.is_empty() or not AutoBattle.in_range(actor, target):
		_emit("action_missed", actor, actor, action.id)
		return
	active_action_id = action.id
	var effects: Array[Dictionary] = []
	_event(effects, actor, target, "damage", actor.atk)
	actor.count += 1
	if actor.count >= actor.skill.attacks_to_trigger:
		actor.count = 0
		if _uses_attack_skill(actor): actor.pending_cast = {"target_id":target.id}
	_emit("action_released", actor, target, action.id, {"casts": action.casts})
	_deliver_effects(actor, effects, due)

func _deliver_effects(actor: Dictionary, effects: Array[Dictionary], due: Array[Dictionary]) -> void:
	var action: Dictionary = actor.action
	for effect in effects:
		if effect.kind == "damage" and actor.action_profile.is_projectile(actor.attack_range):
			projectiles.append({"action_id": action.id, "actor_id": actor.id,
				"target_id": effect.target.id, "position": actor.position,
				"origin": actor.position,
				"previous_position": actor.position, "speed": maxf(1, actor.action_profile.projectile_speed),
				"spawn_time": elapsed, "effect": effect, "special": effect.special, "done": false})
		else:
			due.append(effect)
func _uses_attack_skill(actor: Dictionary) -> bool:
	return not actor.skill.effects.is_empty()

func _start_pending_action(actor: Dictionary) -> bool:
	if actor.get("pending_cast", {}).is_empty(): return false
	var target := unit(actor.pending_cast.target_id)
	# Reacquire only when the retained target has died. Individual effects still
	# check their own range; support does not disappear with the old enemy.
	if target.is_empty() or target.hp <= 0: target = _target(actor, _living(1 - actor.side))
	actor.pending_cast = {}
	if target.is_empty(): return false
	_start_cast(actor, target, CAST_WINDUP)
	return true

func _start_cast(actor: Dictionary, target: Dictionary, windup: float) -> void:
	next_action_id += 1
	actor.action = {"id":next_action_id, "target_id":target.id, "age":0.0,
		"windup":windup, "duration":windup + CAST_RECOVERY, "released":false,
		"phase":"windup", "kind":"cast", "casts":true,
		"mode":"ranged" if actor.action_profile.is_projectile(actor.attack_range) else "melee"}
	actor.facing = actor.position.direction_to(target.position)
	_emit("action_started", actor, target, next_action_id, {"casts":true,
		"windup":windup, "duration":windup + CAST_RECOVERY, "mode":actor.action.mode, "action_kind":"cast"})

func _cast_effects(actor: Dictionary, target: Dictionary, due: Array[Dictionary]) -> void:
	_skill_events(actor, target, due)

## A single authoritative clock; paused callers do not advance the simulation.
func action_timing(actor_id: int) -> Dictionary:
	var actor := unit(actor_id)
	if actor.is_empty() or actor.hp <= 0: return {}
	var action: Dictionary = actor.get("action", {})
	var is_cast: bool = action.get("kind", "attack") == "cast"
	var windup: float = actor.action_profile.timing(actor.interval).x
	var remaining: float = maxf(0, actor.timer) + windup
	var duration: float = maxf(EPSILON, actor.interval)
	if not action.is_empty():
		remaining = maxf(0, action.windup - action.age)
		if is_cast: duration = action.windup
	var has_target := _living(1 - actor.side).any(func(foe): return AutoBattle.in_range(actor, foe))
	var waiting: bool = action.is_empty() and actor.timer <= EPSILON and (actor.moving or not has_target)
	if waiting: remaining = 0
	return {"kind":"cast" if is_cast else "attack", "phase":action.get("phase", "waiting" if waiting else "cooldown"),
		"progress":clampf(1 - remaining / duration, 0, 1), "remaining":remaining, "duration":duration,
		"waiting_target":waiting, "skill_id":actor.skill.id, "target_id":action.get("target_id", actor.target_id)}

func intent_for(actor_id: int) -> Dictionary:
	var actor := unit(actor_id)
	if actor.is_empty() or actor.hp <= 0: return {}
	var timing := action_timing(actor_id)
	var casting: bool = timing.kind == "cast"
	var result := {"icon":actor.skill.glyph if casting else "attack", "label":actor.skill.display_name if casting else "普攻",
		"description":actor.skill.description if casting else "对射程内目标自动攻击。", "target_id":timing.target_id,
		"locked":false, "remaining":timing.remaining, "kind":timing.kind}
	if casting: result.merge(_skill_target_intent(actor, int(timing.target_id)), true)
	return result

## Skill recipients are distinct from the basic target that initiated the cast.
func _skill_target_intent(actor: Dictionary, primary_id: int) -> Dictionary:
	var ally: String = "友方" if actor.side == 0 else "敌方"
	var foe: String = "敌方" if actor.side == 0 else "友方"
	var descriptions: Array[String] = []
	var rules: Array[String] = []
	for effect in actor.skill.effects:
		var rule: String = effect.target
		if rules.has(rule): continue
		rules.append(rule)
		match rule:
			"self": descriptions.append("自身")
			"all_allies": descriptions.append("全部存活" + ally)
			"all_enemies": descriptions.append("全部存活" + foe)
			"adjacent": descriptions.append("自身及周围" + ally)
			"low_ally": descriptions.append("最低生命比例" + ally + "（释放时选定）")
			"low", "low_enemy": descriptions.append("射程内最低生命比例" + foe + "（释放时选定）")
			"back": descriptions.append("射程内后排" + foe + "（释放时选定）")
			"row": descriptions.append("主目标所在横排的射程内" + foe + "（释放时判定）")
			"normal":
				var primary := unit(primary_id)
				descriptions.append(primary.get("name", "锁定目标") if not primary.is_empty() and primary.hp > 0 else "原目标已失效")
			_: descriptions.append("按技能规则选定")
	var target_id := -1
	if rules == ["self"]: target_id = actor.id
	elif rules == ["normal"]:
		var primary := unit(primary_id)
		if not primary.is_empty() and primary.hp > 0: target_id = primary_id
	return {"target_description":"；".join(descriptions), "target_id":target_id, "locked":rules == ["normal"] and target_id >= 0}

func _living(side: int) -> Array[Dictionary]:
	return units.filter(func(u): return u.side == side and u.hp > 0)

func _target(actor: Dictionary, candidates: Array[Dictionary], rule: String = "normal") -> Dictionary:
	var best: Dictionary = {}
	var best_score = INF
	for u in candidates:
		if u.is_empty() or u.hp <= 0: continue
		var score: float
		if rule == "low":
			score = float(u.hp) / maxf(1, u.max_hp)
		elif rule == "back":
			score = u.position.y if actor.side == 0 else -u.position.y
		else:
			score = AutoBattle.distance(actor, u)
		if score < best_score or (score == best_score and _target_tie_precedes(actor, u, best)):
			best_score = score
			best = u
	return best

func _target_tie_precedes(actor: Dictionary, candidate: Dictionary, current: Dictionary) -> bool:
	if current.is_empty(): return true
	if actor.has("position"):
		var candidate_distance := AutoBattle.distance(actor, candidate)
		var current_distance := AutoBattle.distance(actor, current)
		if not is_equal_approx(candidate_distance, current_distance):
			return candidate_distance < current_distance
	return int(candidate.id) < int(current.id)

func _event(events: Array[Dictionary], actor: Dictionary, target: Dictionary, kind: String, value: float, special: bool = false) -> void:
	if not target.is_empty():
		events.append({"actor": actor, "target": target, "kind": kind, "value": value,
			"special": special, "action_id": active_action_id, "origin": actor.position,
			"ordinal": events.size()})


func _skill_events(actor: Dictionary, target: Dictionary, events: Array[Dictionary]) -> void:
	var foes = _living(1 - actor.side)
	var allies = _living(actor.side)
	for effect in actor.skill.effects:
		var targets: Array[Dictionary] = []
		match effect.target:
			"normal":
				if not target.is_empty() and AutoBattle.in_range(actor, target): targets = [target]
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

## Add/remove shield by provenance. No impact event is emitted here: callers own
## the skill/trait presentation. Direct legacy writes to `shield` stay supported.
func grant_shield(target: Dictionary, amount: float, source: String = "skill", duration: float = 0.0) -> float:
	if target.is_empty() or target.hp <= 0 or not is_finite(amount) or amount <= 0: return 0.0
	_sync_shields(target)
	var gain := minf(amount, maxf(0, SHIELD_CAP - target.shield))
	if gain <= 0: return 0.0
	var expiry := elapsed + duration if duration > 0 else 0.0
	# Repeated pulses with the same lifetime share one layer, keeping long fights bounded.
	for layer in target.shield_layers:
		if layer.source == source and is_equal_approx(layer.expires_at, expiry):
			layer.amount += gain
			target.shield += gain
			return gain
	target.shield_layers.append({"source": source, "amount": gain, "expires_at": expiry})
	target.shield += gain
	return gain

func remove_shields(target: Dictionary, source: String) -> float:
	if target.is_empty(): return 0.0
	_sync_shields(target)
	var removed := 0.0
	for layer in target.shield_layers:
		if layer.source == source:
			removed += layer.amount
			layer.amount = 0.0
	target.shield_layers = target.shield_layers.filter(func(layer): return layer.amount > EPSILON)
	target.shield = maxf(0, target.shield - removed)
	return removed

func _sync_shields(target: Dictionary) -> void:
	if not target.has("shield_layers"): target.shield_layers = []
	var recorded := 0.0
	for layer in target.shield_layers: recorded += layer.amount
	var supplied := maxf(0, target.get("shield", 0.0))
	if supplied > recorded + EPSILON:
		target.shield_layers.append({"source": "legacy", "amount": supplied - recorded, "expires_at": 0.0})
	elif supplied + EPSILON < recorded:
		_consume_shield_layers(target, recorded - supplied)
	target.shield = supplied

func _consume_shield_layers(target: Dictionary, amount: float) -> float:
	# Expiring shields protect first; equal expiry uses a stable source order.
	target.shield_layers.sort_custom(func(a, b):
		var a_time: float = a.expires_at if a.expires_at > 0 else INF
		var b_time: float = b.expires_at if b.expires_at > 0 else INF
		if a.get("priority", 0) != b.get("priority", 0): return a.get("priority", 0) > b.get("priority", 0)
		return str(a.source) < str(b.source) if a_time == b_time else a_time < b_time)
	var remaining := maxf(0, amount)
	for layer in target.shield_layers:
		var consumed := minf(layer.amount, remaining)
		layer.amount -= consumed
		remaining -= consumed
		if layer.amount <= EPSILON and consumed > 0: _shield_ended(target, layer, "broken")
		if remaining <= EPSILON: break
	target.shield_layers = target.shield_layers.filter(func(layer): return layer.amount > EPSILON)
	return amount - remaining

func _expire_shields(target: Dictionary) -> void:
	_sync_shields(target)
	for layer in target.shield_layers:
		if layer.expires_at <= 0 or layer.expires_at > elapsed + EPSILON: continue
		var expired: float = layer.amount
		layer.amount = 0.0
		_shield_ended(target, layer, "expired")
		target.shield = maxf(0, target.shield - expired)
		_emit("shield_expired", target, target, -1, {"source": layer.source, "actual": expired, "shield": target.shield})
	target.shield_layers = target.shield_layers.filter(func(layer): return layer.amount > EPSILON)

func _resolve(due: Array[Dictionary]) -> void:
	# Stable effect ordering is a tie-break, never a substitute for shared damage.
	due.sort_custom(func(a, b):
		if a.action_id != b.action_id: return a.action_id < b.action_id
		if a.actor.id != b.actor.id: return a.actor.id < b.actor.id
		if a.target.id != b.target.id: return a.target.id < b.target.id
		if a.kind != b.kind: return str(a.kind) < str(b.kind)
		if a.special != b.special: return not a.special
		return a.get("ordinal", 0) < b.get("ordinal", 0))
	var damage_groups := {}
	for e in due:
		e.actual = 0.0
		e.blocked = 0.0
		e.valid = not e.target.is_empty() and e.target.hp > 0
		if not e.valid: continue
		if e.kind == "shield":
			e.actual = grant_shield(e.target, e.value, e.get("source", "skill"), e.get("duration", 0.0))
		elif e.kind in ["max_hp", "attack", "interval"]:
			if e.kind == "max_hp":
				var previous: float = e.target.max_hp
				e.target.max_hp = clampf(previous + e.value, 1, 100000)
				e.actual = e.target.max_hp - previous
				e.target.hp = clampf(e.target.hp + e.actual, 0, e.target.max_hp)
			elif e.kind == "attack":
				var previous: float = e.target.atk
				e.target.atk = clampf(previous + e.value, 0, 10000)
				e.actual = e.target.atk - previous
			else:
				_set_attack_interval(e.target, e.value)
				e.actual = e.target.interval
		elif e.kind == "heal":
			e.actual = minf(maxf(0, e.value), maxf(0, e.target.max_hp - e.target.hp))
			e.target.hp += e.actual
			e.actor.healing += e.actual
		elif e.kind == "damage":
			# Positive attacks retain the historical one-point minimum. Zero damage
			# effects are useful for triggers, but must never manufacture a hit point.
			e.mitigated = maxf(1, roundf(e.value * 100.0 / (100.0 + maxf(0, e.target.def)))) if e.value > 0 else 0.0
			if not damage_groups.has(e.target.id): damage_groups[e.target.id] = []
			damage_groups[e.target.id].append(e)
	# All support has completed before any hit. One target takes the entire batch
	# at once; damage/blocked attribution is proportional, so array order cannot
	# award all credit to the first actor when simultaneous attacks overkill.
	for id in damage_groups:
		var hits: Array = damage_groups[id]
		var target: Dictionary = hits[0].target
		_sync_shields(target)
		var total := 0.0
		for hit in hits: total += hit.mitigated
		if total <= 0: continue
		var shield_before: float = target.shield
		var blocked := minf(total, shield_before)
		var actual := minf(target.hp, total - blocked)
		_consume_shield_layers(target, blocked)
		target.shield = maxf(0, shield_before - blocked)
		target.hp = maxf(0, target.hp - actual)
		target.flash = 0.2
		for hit in hits:
			var weight: float = hit.mitigated / total
			hit.actual = actual * weight
			hit.blocked = blocked * weight
			hit.shield_break = shield_before > 0 and target.shield <= EPSILON
			hit.actor.damage += hit.actual
	for e in due:
		if not e.valid: continue
		_emit("impact", e.actor, e.target, e.action_id, {"effect": e.kind, "value": e.value,
			"actual": e.actual, "special": e.special, "from": e.get("origin", e.actor.position),
			"blocked": e.blocked, "shield_break": e.get("shield_break", false),
			"hp": maxf(0, e.target.hp), "max_hp": e.target.max_hp, "shield": e.target.shield})
	_after_impact_batch(due)

## Derived rules receive final batch values, including custom effect metadata.
## Reactions must not resurrect a target killed by the batch unless explicitly
## implemented as a separate revival mechanic.
func _after_impact_batch(_due: Array[Dictionary]) -> void:
	pass

## Temporary modifier layers can preserve absolute skill changes as their base.
func _set_attack_interval(target: Dictionary, value: float) -> void:
	target.interval = clampf(value, 0.1, 10)

func _shield_ended(_target: Dictionary, _layer: Dictionary, _reason: String) -> void:
	pass
