extends Node
const Simulation = preload("res://game/combat/battle_simulation.gd")
const Profile = preload("res://game/content/battle_action_profile.gd")
const Skill = preload("res://game/content/skill_def.gd")
const Effect = preload("res://game/content/effect_def.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func pawn(id: int, side: int, at: Vector2, ranged := false) -> Dictionary:
	return {"id": id, "side": side, "slot": id, "position": at, "cell": Vector2i(at),
		"destination": Vector2i(at), "moving": false, "target_id": -1, "move_speed": 2.4,
		"hp": 100.0, "max_hp": 100.0, "atk": 25.0, "def": 0.0, "shield": 0.0,
		"interval": 1.0, "timer": 0.0, "count": 0, "damage": 0.0, "healing": 0.0,
		"attack_range": 3.2 if ranged else 1.45, "skill": Skill.new(), "action_profile": Profile.new()}

func setup(ranged := false) -> RefCounted:
	var sim = Simulation.new()
	var roster: Array[Dictionary] = [pawn(0, 0, Vector2(3, 3), ranged), pawn(1, 1, Vector2(3, 2))]
	roster[1].timer = 100
	sim.reset(roster)
	return sim

func steps(sim: RefCounted, count: int) -> Array:
	var output: Array = []
	for i in count: output.append_array(sim.advance(0.05))
	return output

func _ready() -> void:
	var sim = setup()
	check(not sim.request_action(0, 1, &"item"), "Unknown future requests rejected")
	check(sim.request_action(0, 1), "Valid attack accepted")
	check(not sim.request_action(0, 1), "Busy actor cannot queue duplicate attack")
	steps(sim, 3)
	check(sim.units[1].hp == 100 and sim.units[0].count == 0, "Windup deals no damage/count")
	var events = steps(sim, 1)
	check(sim.units[1].hp == 75 and sim.units[0].count == 1, "Melee hits at release")
	var impact: Dictionary = events.filter(func(e): return e.kind == "impact")[0]
	sim.units[1].hp = 1
	check(impact.hp == 75 and not impact.has("target"), "Event contains detached result snapshot")
	check(sim.units[0].position == Vector2(3, 3), "Attack does not move logical position")
	sim = setup()
	sim.request_action(0, 1)
	sim.units[1].position = Vector2(6, 6)
	steps(sim, 4)
	check(sim.units[1].hp == 100 and sim.units[0].count == 0, "Out-of-range melee misses")
	sim = setup()
	sim.request_action(0, 1)
	sim.units[0].hp = 0
	steps(sim, 5)
	check(sim.units[1].hp == 100 and sim.units[0].action.is_empty(), "Death cancels windup")
	sim = setup(true)
	sim.request_action(0, 1)
	steps(sim, 4)
	check(sim.units[1].hp == 100 and sim.projectiles.size() == 1, "Projectile release delays damage")
	sim.units[0].hp = 0
	sim.units[1].hp = 20
	steps(sim, 4)
	check(sim.units[1].hp <= 0 and sim.finished and not sim.won, "Last projectile survives caster and produces mutual defeat")
	sim = setup(true)
	sim.request_action(0, 1)
	steps(sim, 4)
	sim.units[1].hp = 0
	steps(sim, 1)
	check(sim.projectiles.is_empty() and sim.units[0].damage == 0, "Dead target discards projectile without retarget")
	sim = setup()
	sim.units[1].timer = 0
	sim.units[0].atk = 100
	sim.units[1].atk = 100
	sim.request_action(0, 1)
	sim.request_action(1, 0)
	steps(sim, 4)
	check(sim.units[0].hp <= 0 and sim.units[1].hp <= 0, "Same-step attacks resolve simultaneously")
	sim = setup()
	var shield = Effect.new()
	shield.kind = "shield"
	shield.target = "self"
	shield.value = 30
	sim.units[1].skill.effects.append(shield)
	sim.units[1].skill.attacks_to_trigger = 1
	sim.units[1].timer = 0
	sim.request_action(0, 1)
	sim.request_action(1, 0)
	events = steps(sim, 4)
	check(sim.units[1].hp == 100 and sim.units[1].shield == 5, "Support precedes damage on same step")
	check(events.filter(func(e): return e.kind == "action_released" and e.casts).size() == 1, "Skill emits one release for all effects")
	sim = setup()
	sim.units[0].interval = 0.1
	sim.request_action(0, 1)
	check(sim.units[0].action.duration <= 0.10001, "Fast attacks fit action duration")
	steps(sim, 4)
	sim.reset(sim.units.duplicate())
	check(sim.elapsed == 0 and sim.projectiles.is_empty() and sim.events.is_empty() and sim.units[0].action.is_empty(), "Reset clears transient state")
	print("ACTION_CHECK ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	get_tree().quit(failures)
