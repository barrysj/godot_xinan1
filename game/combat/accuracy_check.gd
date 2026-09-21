extends Node
## Behavioral fixtures for timing/targeting/provenance; no trial-specific rules.
const Simulation = preload("res://game/combat/battle_simulation.gd")
const AutoBattle = preload("res://game/combat/auto_battle.gd")
const Profile = preload("res://game/content/battle_action_profile.gd")
const Skill = preload("res://game/content/skill_def.gd")
const Effect = preload("res://game/content/effect_def.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func pawn(id: int, side: int, at: Vector2, reach := 1.45) -> Dictionary:
	return {"id": id, "side": side, "slot": id, "position": at, "cell": Vector2i(at),
		"destination": Vector2i(at), "moving": false, "target_id": -1, "move_speed": 2.4,
		"hp": 100.0, "max_hp": 100.0, "atk": 25.0, "def": 0.0, "shield": 0.0,
		"interval": 1.0, "timer": 100.0, "count": 0, "damage": 0.0, "healing": 0.0,
		"attack_range": reach, "skill": Skill.new(), "action_profile": Profile.new()}

func setup(roster: Array[Dictionary]) -> RefCounted:
	var sim = Simulation.new()
	sim.reset(roster)
	return sim

func effect(actor: Dictionary, target: Dictionary, value: float, kind := "damage", action_id := 1) -> Dictionary:
	return {"actor": actor, "target": target, "value": value, "kind": kind,
		"special": false, "action_id": action_id}

func steps(sim: RefCounted, count: int) -> Array:
	var events: Array = []
	for i in count: events.append_array(sim.advance(0.05))
	return events

func _ready() -> void:
	check_phase_order()
	check_target_rules()
	check_damage_batches()
	check_shield_sources()
	check_projectile_motion()
	check_replay_order()
	check(checks >= 46, "Every behavioral fixture reached its assertions")
	print("ACCURACY_CHECK ", "PASS" if failures == 0 else "FAIL", " checks=", checks, " failures=", failures)
	get_tree().quit(failures)

func check_phase_order() -> void:
	# At release the enemy crosses OUT of reach, irrespective of roster storage.
	for reverse in [false, true]:
		var attacker := pawn(0, 0, Vector2(3, 3))
		var runner := pawn(1, 1, Vector2(3, 2))
		var roster: Array[Dictionary] = [attacker, runner]
		if reverse: roster.reverse()
		var sim = setup(roster)
		attacker.timer = 0
		sim.request_action(0, 1)
		attacker.action.age = 0.15
		runner.moving = true
		runner.position = Vector2(3, 1.6)
		runner.destination = Vector2i(3, 1)
		var output: Array = sim.advance(0.05)
		check(runner.hp == 100 and attacker.count == 0, "Windup uses all movers' new positions, reverse=" + str(reverse))
		check(output.any(func(e): return e.kind == "action_missed"), "Range crossing reports a missed action")
	var attacker := pawn(0, 0, Vector2(3, 4))
	var target := pawn(1, 1, Vector2(3, 2))
	var sim = setup([attacker, target])
	attacker.position = Vector2(3, 3.05)
	attacker.destination = Vector2i(3, 3)
	attacker.moving = true
	attacker.timer = 0
	sim.advance(0.05)
	check(not attacker.moving and not attacker.action.is_empty(), "Arrival can start an action without a blank movement tick")
	attacker.action.age = 0.15
	target.hp = 1
	sim.advance(0.05)
	check(target.hp == 0 and target.action.is_empty() and sim.finished, "Lethal batch ends immediately without dead-unit action")
	var elapsed: float = sim.elapsed
	check(sim.advance(0).is_empty() and sim.elapsed == elapsed, "Zero delta never advances a completed simulation")
	attacker = pawn(0, 0, Vector2(3, 3))
	target = pawn(1, 1, Vector2(3, 2))
	sim = setup([attacker, target])
	attacker.timer = 0
	target.timer = 0
	attacker.atk = 100
	sim.request_action(0, 1)
	sim.request_action(1, 0)
	attacker.action.age = 0.15
	target.action.age = 0.1
	var output: Array = sim.advance(0.05)
	check(target.hp == 0 and target.count == 0 and target.action.is_empty(), "An unreleased windup dies in its lethal batch, not a tick later")
	check(output.any(func(e): return e.kind == "action_cancelled" and e.actor_id == 1), "Death cancels an unreleased action in the same event batch")

func check_target_rules() -> void:
	var actor := pawn(0, 0, Vector2(3, 4), 3.2)
	var near := pawn(1, 1, Vector2(3, 3))
	var locked := pawn(2, 1, Vector2(3, 2))
	var sim = setup([actor, near, locked])
	actor.target_id = locked.id
	check(AutoBattle.advance(actor, sim.units, 0).id == locked.id, "Retain reachable target instead of oscillating toward nearer foes")
	var skill_effect = Effect.new()
	skill_effect.target = "normal"
	skill_effect.value = 10
	actor.skill.effects.append(skill_effect)
	var due: Array[Dictionary] = []
	sim._skill_events(actor, locked, due)
	check(due.size() == 1 and due[0].target.id == locked.id, "Normal skill uses the basic attack's retained primary target")
	near.hp = 49
	near.max_hp = 100
	locked.hp = 50
	locked.max_hp = 200
	var candidates: Array[Dictionary] = [near, locked]
	check(sim._target(actor, candidates, "low").id == locked.id, "Lowest health means float ratio, including integer input stats")
	near.hp = 50.0
	near.max_hp = 100.0
	locked.hp = 49.999999
	locked.max_hp = 100.0
	check(sim._target(actor, candidates, "low").id == locked.id, "Tie-break cannot outweigh even a tiny actual HP ratio difference")
	near.position = Vector2(2, 2)
	locked.position = Vector2(3, 2)
	check(sim._target(actor, candidates, "back").id == locked.id, "Back row tie prefers closest reachable enemy")
	near.position = Vector2(2, 3)
	locked.position = Vector2(4, 3)
	actor.target_id = -1
	check(AutoBattle.advance(actor, [actor, locked, near], 0).id == near.id, "Equidistant basic attack tie uses ID, independent of candidates order")
	locked.hp = 0
	candidates.reverse()
	check(sim._target(actor, candidates, "low").id == near.id, "Skill target helper never selects a corpse")

func check_damage_batches() -> void:
	for reverse in [false, true]:
		var first := pawn(0, 0, Vector2(2, 3))
		var second := pawn(1, 0, Vector2(4, 3))
		var target := pawn(2, 1, Vector2(3, 3))
		var sim = setup([first, second, target])
		target.hp = 30
		sim.grant_shield(target, 30, "system")
		var one := effect(first, target, 20, "damage", 1)
		var two := effect(second, target, 40, "damage", 2)
		var due: Array[Dictionary] = [one, two]
		if reverse: due.reverse()
		sim._resolve(due)
		check(target.hp == 0 and target.shield == 0, "Simultaneous damage consumes shield and HP exactly once")
		check(is_equal_approx(one.actual, 10) and is_equal_approx(two.actual, 20), "Simultaneous overkill credit is independent of effect order")
		check(is_equal_approx(one.blocked, 10) and is_equal_approx(two.blocked, 20), "Shield absorption apportioned consistently to simultaneous hits")
		check(is_equal_approx(first.damage + second.damage, 30), "Recorded damage excludes absorption and overkill")
	var actor := pawn(0, 0, Vector2(3, 3))
	var target := pawn(1, 1, Vector2(3, 2))
	var sim = setup([actor, target])
	target.def = 100.0
	var due: Array[Dictionary] = [effect(actor, target, 25)]
	sim._resolve(due)
	check(target.hp == 87 and due[0].actual == 13, "Defense uses rounded mitigation at impact")
	due = [effect(actor, target, 0)]
	sim._resolve(due)
	check(target.hp == 87 and due[0].actual == 0, "Zero-valued effect never creates minimum damage")
	target.hp = 5
	due = [effect(actor, target, 20), effect(target, target, 30, "heal", 2)]
	sim._resolve(due)
	check(target.hp == 25, "Same-batch healing precedes mitigated incoming damage")
	target.hp = 0
	due = [effect(actor, target, 50, "heal")]
	sim._resolve(due)
	check(target.hp == 0 and not due[0].valid, "Ordinary healing cannot revive a previously dead target")

func check_shield_sources() -> void:
	var actor := pawn(0, 0, Vector2(3, 3))
	var target := pawn(1, 1, Vector2(3, 2))
	var sim = setup([actor, target])
	sim.grant_shield(target, 40, "sport", 0.1)
	sim.grant_shield(target, 30, "skill")
	var due: Array[Dictionary] = [effect(actor, target, 25)]
	sim._resolve(due)
	check(target.hp == 100 and target.shield == 45, "Damage consumes expiring shields before permanent shields")
	steps(sim, 2)
	check(target.shield == 30, "Expiry removes remaining temporary shield only, never borrowed permanent shield")
	check(sim.remove_shields(target, "sport") == 0, "Expired shield cannot be removed twice")
	check(sim.remove_shields(target, "skill") == 30 and target.shield == 0, "Source removal returns exactly its remaining amount")
	target.shield = 20
	sim.grant_shield(target, 30, "system")
	check(sim.remove_shields(target, "system") == 30 and target.shield == 20, "Direct legacy shield assignment survives source-specific removal")
	check(sim.grant_shield(target, 1000, "skill") == 124 and target.shield == 144, "All sources share the shield cap and report effective gain")
	check(sim.grant_shield(target, 10, "system") == 0 and target.shield == 144, "Capped shield emits no negative gain")
	target.shield = 10
	sim.grant_shield(target, 5, "system")
	check(target.shield == 15 and sim.remove_shields(target, "system") == 5, "External shield decrease reconciles layers before a new grant")
	for layer in target.shield_layers:
		check(layer.amount > 0, "Shield layers never retain negative or empty amounts")
	target.hp = 0
	check(sim.grant_shield(target, 50) == 0, "Dead units cannot gain a new shield")

func check_projectile_motion() -> void:
	var actor := pawn(0, 0, Vector2(3, 4), 3.2)
	var target := pawn(1, 1, Vector2(3, 2))
	var sim = setup([actor, target])
	actor.timer = 0
	sim.request_action(actor.id, target.id)
	steps(sim, 4)
	check(sim.projectiles.size() == 1 and target.hp == 100, "Ranged release creates a pending projectile, no launch-time damage")
	target.moving = true
	target.destination = Vector2i(4, 2)
	var target_previous: Vector2 = target.position
	var previous: Vector2 = sim.projectiles[0].position
	sim.advance(0.05)
	check(target.position != target_previous, "Projectile fixture actually moves the target while the source lives")
	check(sim.projectiles.size() == 1 and target.hp == 100, "Moving target is not damaged before projectile arrives")
	if not sim.projectiles.is_empty():
		check(sim.projectiles[0].position.distance_to(previous) <= 0.40001, "Projectile travel obeys its configured speed")
		check(sim.projectiles[0].position.x > 3.0, "Projectile steering follows the target's updated position")
	actor.hp = 0
	steps(sim, 20)
	check(target.hp == 75 and sim.projectiles.is_empty(), "Launched projectile still lands after its source dies")

func check_replay_order() -> void:
	var snapshots: Array = []
	var event_streams: Array = []
	for reverse in [false, true]:
		var roster: Array[Dictionary] = [
			pawn(0, 0, Vector2(1, 6)), pawn(1, 0, Vector2(3, 6), 3.2), pawn(2, 0, Vector2(3, 4)),
			pawn(10, 1, Vector2(1, 0)), pawn(11, 1, Vector2(3, 0), 3.2), pawn(12, 1, Vector2(3, 2))]
		for u in roster: u.timer = 0
		if reverse: roster.reverse()
		var sim = setup(roster)
		var stream: Array = []
		var overlap := false
		for i in 700:
			stream.append_array(sim.advance(0.05))
			var reserved := {}
			for u in sim.units:
				if u.hp <= 0: continue
				for cell in [u.cell, u.destination]:
					if reserved.has(cell) and reserved[cell] != u.id: overlap = true
					reserved[cell] = u.id
			if sim.finished: break
		check(not overlap, "Live movement reserves both endpoints with no overlaps, reverse=" + str(reverse))
		check(sim.finished, "Multi-unit pathing resolves before timeout")
		var snapshot: Array = []
		for id in [0, 1, 2, 10, 11, 12]:
			var u: Dictionary = sim.unit(id)
			snapshot.append([u.position, u.hp, u.count, u.damage, u.target_id])
		snapshots.append(snapshot)
		event_streams.append(stream)
	check(snapshots[0] == snapshots[1], "Complete battle state is invariant under roster storage order")
	check(event_streams[0] == event_streams[1], "Complete battle event replay is invariant under roster storage order")
