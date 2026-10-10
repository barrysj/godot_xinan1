extends Node
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const AnimationConfig = preload("res://assets/art/characters/cyber_librarian/battle_animation.tres")
const Simulation = preload("res://game/combat/battle_simulation.gd")
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
const Profile = preload("res://game/content/battle_action_profile.gd")
const Skill = preload("res://game/content/skill_def.gd")
const Effect = preload("res://game/content/effect_def.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func pawn(id: int, side: int, at: Vector2) -> Dictionary:
	return {"id":id, "side":side, "slot":id, "position":at, "cell":Vector2i(at),
		"destination":Vector2i(at), "moving":false, "target_id":1-id, "move_speed":2.4,
		"hp":10000.0, "max_hp":10000.0, "atk":1.0, "def":0.0, "shield":0.0,
		"interval":1.0, "timer":100.0, "count":0, "damage":0.0, "healing":0.0,
		"attack_range":1.45, "skill":Skill.new(), "action_profile":Profile.new()}

func fresh():
	var sim = Simulation.new()
	var units: Array[Dictionary] = [pawn(0,0,Vector2(3,3)),pawn(1,1,Vector2(3,2))]
	units[0].timer = 0
	var effect = Effect.new()
	effect.kind = "shield"; effect.target = "self"; effect.value = 30
	units[0].skill.effects.append(effect)
	units[0].skill.attacks_to_trigger = 3
	sim.reset(units)
	return sim

func steps(sim, count: int) -> Array:
	var result: Array = []
	for i in count: result.append_array(sim.advance(0.05))
	return result

func _ready() -> void:
	ordinary_cast()
	timed_cast()
	production()
	animation_mapping()
	intent_targets()
	print("CAST_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func ordinary_cast() -> void:
	var sim = fresh()
	var actor: Dictionary = sim.unit(0)
	var events: Array = []
	for i in 100:
		events.append_array(sim.advance(0.05))
		if actor.action.get("kind", "") == "cast": break
	expect(events.filter(func(e): return e.kind == "action_released" and not e.casts).size() == 3, "Three basics release before the separate cast")
	expect(actor.count == 0 and actor.shield == 0, "Trigger counted once, no support before cast release")
	var held_timer: float = actor.timer
	var held_position: Vector2 = actor.position
	var snapshot: Dictionary = sim.action_timing(0)
	var age: float = actor.action.age
	sim.advance(0); sim.advance(-1)
	expect(snapshot == sim.action_timing(0) and actor.action.age == age, "Zero delta and invalid delta preserve every HUD clock")
	actor.hp -= 10
	events = steps(sim, 15)
	expect(actor.shield == 0 and actor.action.kind == "cast", "Ordinary damage does not interrupt windup")
	expect(is_equal_approx(actor.timer, held_timer) and actor.position == held_position, "Cast freezes basic cooldown and movement")
	expect(events.filter(func(e): return e.kind == "action_released").is_empty(), "No basic or skill release before cast deadline")
	expect(not sim.request_action(0,1), "Cannot manually request a basic during casting")
	var timer = sim.action_timing(0)
	expect(timer.kind == "cast" and timer.progress > 0.9 and timer.remaining > 0, "Cast clock predicts release")
	events = steps(sim,1)
	expect(actor.shield == 30 and events.filter(func(e): return e.kind == "action_released" and e.casts).size() == 1, "One cast releases exactly one skill effect batch")
	expect(sim.action_timing(0).progress == 1 and actor.count == 0, "Released cast bar full and does not count as a basic")
	steps(sim,4)
	expect(actor.action.is_empty() and is_equal_approx(actor.timer, held_timer), "Recovery also preserves attack progress")
	steps(sim,1)
	expect(actor.timer < held_timer, "Attack clock resumes after full recovery")
	sim = fresh(); actor = sim.unit(0); actor.count = 2
	steps(sim,10)
	expect(actor.action.get("kind", "") == "cast", "Death fixture reached cast")
	actor.hp = 0
	events = steps(sim,20)
	expect(actor.shield == 0 and actor.pending_cast.is_empty() and actor.action.is_empty(), "Dead caster cancels pending release and queue")
	expect(events.any(func(e): return e.kind == "action_cancelled"), "Cancellation is observable")
	sim = fresh(); actor = sim.unit(0)
	sim.unit(1).position = Vector2(6,6)
	expect(sim.action_timing(0).waiting_target and sim.action_timing(0).progress == 1, "Ready unit without target shows full waiting bar")
	# The same 0.8 second cast duration survives extreme attack-speed changes.
	actor.interval = 0.1; actor.count = 2; sim.unit(1).position = Vector2(3,2)
	steps(sim,3)
	expect(actor.action.get("kind", "") == "cast" and is_equal_approx(actor.action.windup,0.8), "Attack speed does not shorten cast windup")

func timed_cast() -> void:
	var sim = Fixture.build()
	for u in sim.units: u.hp = 100000; u.max_hp = 100000; u.timer = 100; u.moving = false; u.move_speed = 0
	var foe: Dictionary = sim.units.filter(func(u): return u.content_id == "radio")[0]
	var target: Dictionary = sim._living(0)[0]
	foe.position = Vector2(3,2); target.position = Vector2(3,3)
	foe.timer = 0; sim.elapsed = 8.9
	expect(sim.request_action(foe.id,target.id), "Timed fixture has in-flight basic at scheduled warning")
	var events := steps(sim,3)
	expect(not sim.warnings.has(foe.id), "Warning waits for already started basic recovery")
	for i in 20:
		events.append_array(sim.advance(0.05))
		if sim.warnings.has(foe.id): break
	expect(events.filter(func(e): return e.kind == "action_released" and e.actor_id == foe.id and not e.casts).size() == 1, "Already-started basic still releases once")
	expect(foe.action.kind == "cast" and is_equal_approx(sim.warnings[foe.id].fire_at-sim.elapsed,3), "Warning deadline matches actual delayed cast start")
	var held: float = foe.timer
	var warning_start: float = sim.elapsed
	events = steps(sim,59)
	expect(sim.warnings.has(foe.id) and is_equal_approx(foe.timer,held), "All three warning seconds freeze basic progress")
	expect(not events.any(func(e): return e.actor_id == foe.id and e.kind == "action_released"), "No overlapping basic during warning")
	var intent: Dictionary = sim.intent_for(foe.id)
	expect(intent.kind == "cast" and intent.icon == "shield" and intent.description.contains("护盾"), "Timed intent exposes the actual skill")
	events = steps(sim,1)
	expect(events.filter(func(e): return e.kind == "enemy_release" and e.actor_id == foe.id).size() == 1, "Timed skill releases once at bar deadline")
	expect(is_equal_approx(sim.warning_next[foe.id],warning_start+10), "Next warning preserves actual start-to-start cadence")
	expect(not sim.warnings.has(foe.id), "Released warning is removed")
	sim.elapsed = sim.warning_next[foe.id]
	foe.action = {}; foe.timer = 100
	steps(sim,1); foe.hp = 0
	events = steps(sim,70)
	expect(not sim.warnings.has(foe.id) and not events.any(func(e): return e.kind == "enemy_release" and e.actor_id == foe.id), "Dead enemy cancels telegraphed skill")

func production() -> void:
	var sim = Fixture.build()
	for u in sim.units: u.hp = 100000; u.max_hp = 100000; u.timer = 100; u.moving = false; u.move_speed = 0
	var actor: Dictionary = sim.units.filter(func(u): return u.content_id == "archer")[0]
	var target: Dictionary = sim._living(1)[0]
	actor.position = Vector2(3,3); target.position = Vector2(3,2)
	actor.timer = 0
	var events := steps(sim,220)
	var basics := events.filter(func(e): return e.kind == "impact" and e.actor_id == actor.id and e.effect == "damage" and not e.special)
	var casts := events.filter(func(e): return e.kind == "action_released" and e.actor_id == actor.id and e.casts)
	expect(casts.size() >= 1, "Production fixture exercised independent skill")
	expect(int(sim.generated.get(actor.code_type,0)) == int(basics.size()/3), "Only basic hits produce attack-count code; casts never double-credit")
	expect(int(sim.attack_counts.get(actor.id,0)) == basics.size()%3, "Partial code counter retains actual basic hits")

func animation_mapping() -> void:
	for windup in [0.8,3.0]:
		var animator = Animator.new(AnimationConfig)
		var action := {"age":windup-0.05,"windup":windup,"duration":windup+0.2,"casts":true}
		animator.sync_motion(false,action)
		var release_age: float = animator._duration(&"cast") * AnimationConfig.impact_ratio
		expect(animator.state == &"cast" and animator.age < release_age, "Prepared pose persists until the real cast deadline")
		var before: float = animator.age
		animator.advance(10)
		expect(is_equal_approx(animator.age,before), "Playback cannot outrun a held three-second windup")
		action.age = windup
		animator.sync_motion(false,action)
		expect(is_equal_approx(animator.age,release_age), "Release frame coincides with simulation event")
		action.age = windup+0.2
		animator.sync_motion(false,action)
		expect(is_equal_approx(animator.age,animator._duration(&"cast")), "Recovery remains short independently of charge duration")

func intent_targets() -> void:
	var sim = fresh()
	var actor: Dictionary = sim.unit(0)
	sim._start_cast(actor,sim.unit(1),0.8)
	for rule in ["self","all_allies","all_enemies","low_ally","low_enemy","back","row","adjacent","normal"]:
		actor.skill.effects[0].target = rule
		var intent: Dictionary = sim.intent_for(actor.id)
		expect(not intent.target_description.is_empty(), "Every effect rule explains its actual recipient scope")
		if rule == "self": expect(intent.target_id == actor.id and intent.target_description == "自身", "Self shield never names its basic enemy target")
		elif rule == "normal": expect(intent.target_id == 1 and intent.locked, "Truly retained single target keeps its identity")
		else: expect(intent.target_id == -1 and not intent.locked, "Group or release-selected skill does not invent a locked single target")
	sim = Fixture.build([0,4,-1,2,1,-1])
	for id in ["guard","inventor","healer","archer"]:
		actor = sim.units.filter(func(u): return u.content_id == id)[0]
		sim._start_cast(actor,sim._living(1)[0],0.8)
		var intent: Dictionary = sim.intent_for(actor.id)
		expect(intent.target_id == -1 and not intent.target_description.is_empty(), "Mainline skill describes actual selection instead of retained enemy: " + id)
		if id == "inventor": expect(intent.target_description.contains("两名"), "Inventor preview matches the two-recipient runtime rule")
		if id == "guard": expect(intent.target_description.contains("一名"), "Guard preview does not promise shields to all nearby allies")
	var foe: Dictionary = sim.units.filter(func(u): return u.content_id == "radio")[0]
	for rule in ["radio","board","colossus"]:
		foe.skill = load("res://resources/content/skills/enemy_"+rule+".tres")
		foe.action = {}; sim.warnings.clear()
		sim._start_warning(foe)
		var intent: Dictionary = sim.intent_for(foe.id)
		var description: String = "其他存活敌人" if rule == "radio" else "锁定横排" if rule == "board" else "锁定半径 2 格区域"
		expect(foe.action.target_id >= 0 and intent.target_id == -1, "Timed intent hides unrelated basic target: " + rule)
		expect(intent.target_description == description, "Timed skill states its actual recipient region: " + rule)
		var due: Array[Dictionary] = []
		sim._cast_effects(foe,sim.unit(foe.action.target_id),due)
		expect(sim.intent_for(foe.id).target_id == -1 and sim.intent_for(foe.id).target_description == description, "Recovery does not reintroduce unrelated basic target")
