extends Node
## Contract checks for declarative reactions through the real combat resolver.
const Simulation = preload("res://game/trial/trial_simulation.gd")
const Catalog = preload("res://game/trial/trial_catalog.gd")
const Proc = preload("res://game/content/battle_proc.gd")
const DEFAULT = [0, -1, 3, 2, 1, -1]
var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func fresh(formation: Array = DEFAULT, rewards: Array = [], gear: Dictionary = {}, trainee: int = -1):
	var sim = Simulation.new()
	sim.start(formation, 0, rewards, gear, trainee)
	quiet(sim)
	return sim

func quiet(sim) -> void:
	for unit in sim.units:
		unit.timer = 1000.0
		unit.move_speed = 0.0
		unit.moving = false
		unit.action = {}

func role(sim, index: int) -> Dictionary:
	for unit in sim.units:
		if unit.side == 0 and unit.role == index: return unit
	return {}

func foe(sim, index: int = 0) -> Dictionary:
	return sim.units.filter(func(unit): return unit.side == 1)[index]

func place(unit: Dictionary, at: Vector2) -> void:
	unit.position = at
	unit.previous_position = at
	unit.cell = Vector2i(at)
	unit.destination = Vector2i(at)
	unit.moving = false

func clear_shield(unit: Dictionary) -> void:
	unit.shield = 0.0
	unit.shield_layers = []

func hit(actor: Dictionary, target: Dictionary, action: int, skill: bool = false, amount: float = 10) -> Dictionary:
	return {"actor":actor,"target":target,"action_id":action,"kind":"damage","value":amount,
		"special":skill,"trial_skill":skill,"origin":actor.position}

func resolve(sim, effects: Array) -> void:
	var batch: Array[Dictionary] = []
	batch.assign(effects)
	sim._resolve(batch)

func tick(sim, seconds: float) -> Array:
	var result: Array = []
	for i in roundi(seconds / 0.05): result.append_array(sim.advance(0.05))
	return result

func _ready() -> void:
	_sports_and_protect()
	_team_broadcast()
	_makers_expiry()
	_assault_and_analysis()
	_content_extension()
	_enemy_speed_extension()
	_interval_change_during_modifier()
	_marks()
	_equipment_and_exclusive()
	_piercing_backline()
	_failed_skills()
	_maintenance_provenance()
	print("TRIAL_PROC_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _sports_and_protect() -> void:
	var sim = fresh()
	var guard = role(sim,0)
	var archer = role(sim,1)
	var healer = role(sim,2)
	expect(guard.shield == 40 and archer.shield == 40 and healer.shield == 0, "Sports applies to both members and no outsiders")
	sim._dispatch("battle_start")
	expect(guard.shield == 40 and archer.shield == 40, "Sports owner scope only triggers once per member")
	sim.grant_shield(guard, 50, "natural")
	tick(sim, 5.95)
	expect(guard.shield == 90, "Sports shield remains until six-second expiry")
	tick(sim, 0.05)
	expect(guard.shield == 50 and archer.shield == 0, "Sports expiry preserves unrelated natural shields")
	clear_shield(guard)
	guard.hp = guard.max_hp * 0.5
	healer.hp = healer.max_hp * 0.5
	resolve(sim, [])
	expect(guard.shield == 45 and healer.shield == 45, "Protect grants each living member their own half-health shield")
	resolve(sim, [])
	expect(guard.shield == 45 and healer.shield == 45, "Protect does not repeat on subsequent half-health frames")
	# Cover is the same half-health event, not a standing proximity aura.
	sim = fresh(DEFAULT, ["cover"])
	guard = role(sim,0)
	archer = role(sim,1)
	place(guard,Vector2(0,0))
	place(archer,Vector2(6,6))
	place(role(sim,2),Vector2(6,5))
	place(role(sim,3),Vector2(5,6))
	clear_shield(guard)
	clear_shield(archer)
	guard.hp = guard.max_hp * 0.5
	resolve(sim, [])
	place(archer,Vector2(0,1))
	archer.hp = archer.max_hp * 0.4
	resolve(sim, [])
	expect(archer.shield == 0, "Cover cannot trigger late when an ally enters radius after the half-health event")

func _team_broadcast() -> void:
	var sim = fresh()
	var guard = role(sim,0)
	var archer = role(sim,1)
	var analyst = role(sim,3)
	guard.hp -= 90
	archer.hp -= 80
	var original: float = archer.hp
	sim.marks[foe(sim).id] = {"owner":analyst.id,"until":4.0,"users":[],"limit":2}
	sim._verify(guard,foe(sim))
	expect(archer.hp == original + 45, "Broadcast heals lowest fraction ally once across two installed members")
	sim._verify(archer,foe(sim))
	expect(archer.hp == original + 45, "Further verifications cannot repeat a team-limited effect")
	sim = fresh()
	guard = role(sim,0)
	archer = role(sim,1)
	analyst = role(sim,3)
	role(sim,2).hp = 0
	analyst.hp = 0
	archer.hp -= 90
	original = archer.hp
	sim.marks[foe(sim).id] = {"owner":analyst.id,"until":4.0,"users":[],"limit":1}
	sim._verify(guard,foe(sim))
	expect(archer.hp == original + 45, "Locked broadcast trait persists after both tag holders die when a living ally verifies")
	expect(role(sim,2).hp == 0 and analyst.hp == 0, "Broadcast cannot resurrect its original holders")

func _makers_expiry() -> void:
	var formation = [0,-1,5,2,4,-1]
	var sim = fresh(formation)
	var inventor = role(sim,4)
	var striker = role(sim,5)
	var base: float = inventor.interval
	var other_base: float = role(sim,0).interval
	sim.awaiting_choice = true
	expect(sim.choose_hack("takeover"), "Hack choice accepted once")
	expect(is_equal_approx(inventor.interval,base*0.75) and is_equal_approx(striker.interval,striker.base_interval*0.75), "Makers speeds both trait holders")
	expect(role(sim,0).interval == other_base, "Makers does not buff unrelated characters")
	expect(not sim.choose_hack("takeover"), "Hack complete cannot be repeated")
	tick(sim,7.95)
	expect(is_equal_approx(inventor.interval,base*0.75), "Makers bonus lasts to just before eight seconds")
	tick(sim,0.05)
	expect(is_equal_approx(inventor.interval,base) and sim.speed_modifiers.is_empty(), "Makers expires exactly at eight seconds")
	sim.start(formation,0,[],{},-1)
	expect(role(sim,4).interval == base and sim.speed_modifiers.is_empty(), "Speed does not leak into the next battle")

func _assault_and_analysis() -> void:
	var sim = fresh([0,-1,5,2,1,-1])
	var archer = role(sim,1)
	var striker = role(sim,5)
	var first = hit(archer,foe(sim,0),11,true)
	var second = hit(archer,foe(sim,1),11,true)
	resolve(sim,[first,second])
	expect(first.value == 35 and second.value == 10, "Assault bonus belongs to only one hit of a multi-target skill")
	var later = hit(archer,foe(sim),12,true)
	var other = hit(striker,foe(sim),13,true)
	resolve(sim,[later,other])
	expect(later.value == 10 and other.value == 35, "Assault owner scope is independent for each member")
	sim = fresh([0,-1,3,2,4,-1])
	var analyst = role(sim,3)
	var inventor = role(sim,4)
	resolve(sim,[hit(analyst,foe(sim),21,true),hit(analyst,foe(sim,1),21,true)])
	expect(sim.progress == 16, "Analysis gets one base plus one first-skill contribution across multiple hits")
	resolve(sim,[hit(analyst,foe(sim),22,true)])
	expect(sim.progress == 20, "Analysis first-skill contribution does not repeat next action")
	resolve(sim,[hit(inventor,foe(sim),23,true),hit(inventor,foe(sim,1),23,true)])
	expect(sim.progress == 40, "Inventor contributes base and research once per action plus own analysis bonus")
	resolve(sim,[hit(inventor,foe(sim),24,true)])
	expect(sim.progress == 48, "Inventor action-limited research can trigger on the next action")

func _content_extension() -> void:
	var sim = fresh()
	var guard = role(sim,0)
	var proc = Proc.new()
	proc.id = "test_support"
	proc.trigger = "skill_impact"
	proc.effect = "shield"
	proc.limit = "action"
	proc.value = 7
	sim.install_effects(guard,[proc],"extension/test_support","护航测试")
	clear_shield(guard)
	resolve(sim,[hit(guard,foe(sim),31,true),hit(guard,foe(sim,1),31,true)])
	expect(guard.shield == 7, "New resource effect installs and works without changing battle runtime")
	resolve(sim,[hit(guard,foe(sim),32,true)])
	expect(guard.shield == 14, "New action scope resets for a new action ID")
	expect(proc.value == 7 and proc.limit == "action", "Proc runtime does not mutate resource configuration")
	sim.start(DEFAULT,0,[],{},-1)
	expect(not sim.bindings.any(func(binding): return binding.source == "extension/test_support"), "Runtime-installed extension does not leak to another battle")

func _enemy_speed_extension() -> void:
	var sim = fresh()
	var actor = role(sim,0)
	var target = foe(sim)
	var original: float = target.interval
	var proc = Proc.new()
	proc.id = "latency"
	proc.trigger = "skill_impact"
	proc.effect = "attack_speed"
	proc.target = "skill_target"
	proc.value = 1.5
	proc.duration = 1.0
	sim.install_effects(actor,[proc],"extension/latency","延迟测试")
	resolve(sim,[hit(actor,target,38,true)])
	expect(is_equal_approx(target.interval,original*1.5), "New declarative skill-target slowdown affects an enemy")
	expect(is_equal_approx(actor.interval,actor.base_interval), "Enemy slowdown does not affect its owner")
	tick(sim,0.95)
	expect(is_equal_approx(target.interval,original*1.5), "Enemy slowdown persists until its expiry")
	tick(sim,0.05)
	expect(is_equal_approx(target.interval,original), "Enemy slowdown restores its original interval")

func _interval_change_during_modifier() -> void:
	for change_at_expiry in [false, true]:
		var sim = fresh()
		var actor = role(sim,0)
		var target = foe(sim)
		var original: float = target.interval
		var proc = Proc.new()
		proc.id = "latency"
		proc.trigger = "skill_impact"
		proc.effect = "attack_speed"
		proc.target = "skill_target"
		proc.value = 1.5
		proc.duration = 1.0
		sim.install_effects(actor,[proc],"extension/interval_composition","延迟测试")
		var original_timer: float = target.timer
		resolve(sim,[hit(actor,target,81,true)])
		expect(is_equal_approx(target.interval,original*1.5) and is_equal_approx(target.timer,original_timer*1.5), "Slowdown rescales remaining attack cooldown with interval")
		if not change_at_expiry:
			tick(sim,0.25)
			var timer_before: float = target.timer
			var changed = hit(actor,target,82,true,1.2)
			changed.kind = "interval"
			resolve(sim,[changed])
			expect(is_equal_approx(target.base_interval,1.2) and is_equal_approx(target.interval,1.8), "Permanent interval change preserves an active temporary multiplier")
			expect(is_equal_approx(target.timer,timer_before*1.8/(original*1.5)), "Permanent interval change preserves cooldown fraction under a modifier")
			tick(sim,0.7)
			timer_before = target.timer
			tick(sim,0.05)
			expect(is_equal_approx(target.interval,1.2) and sim.speed_modifiers.is_empty(), "Temporary slowdown expires to the new permanent baseline")
			expect(is_equal_approx(target.timer,(timer_before-0.05)*1.2/1.8), "Expiry rescales remaining cooldown to the new baseline")
		else:
			# A real melee skill changes the baseline in the exact expiry batch.
			tick(sim,0.95)
			place(actor,Vector2(3,3))
			place(target,Vector2(3,2))
			var skill = preload("res://game/content/skill_def.gd").new()
			var effect = preload("res://game/content/effect_def.gd").new()
			effect.kind = "interval"
			effect.target = "normal"
			effect.value = 1.4
			effect.attack_scale = 0
			skill.attacks_to_trigger = 1
			skill.effects.append(effect)
			actor.skill = skill
			actor.action_profile = preload("res://game/content/battle_action_profile.gd").new()
			actor.action_profile.windup = 0.05
			actor.action_profile.recovery = 0.2
			actor.timer = 0
			var timer_before: float = target.timer
			expect(sim.request_action(actor.id,target.id), "Expiry-boundary interval fixture starts through the action API")
			var events = sim.advance(0.05)
			expect(events.any(func(event): return event.kind == "impact" and event.effect == "interval"), "Interval skill actually resolves in the modifier expiry batch")
			expect(is_equal_approx(target.base_interval,1.4) and is_equal_approx(target.interval,1.4), "Same-batch skill and modifier expiry retain the new baseline")
			expect(is_equal_approx(target.timer,(timer_before-0.05)*1.4/(original*1.5)), "Same-batch composition preserves cooldown fraction exactly once")

func _marks() -> void:
	var sim = fresh(DEFAULT,["verify"])
	var analyst = role(sim,3)
	var archer = role(sim,1)
	var guard = role(sim,0)
	var target = foe(sim)
	sim.marks[target.id] = {"owner":analyst.id,"until":4.0,"users":[],"limit":2}
	sim._verify(analyst,target)
	expect(sim.progress == 0, "Exposer cannot verify their own vulnerability")
	sim.grant_shield(target,100,"fixture")
	var health: float = target.hp
	resolve(sim,[hit(archer,target,41,false,10)])
	expect(target.hp == health and sim.progress == 16, "A valid fully absorbed basic hit verifies vulnerability")
	resolve(sim,[hit(archer,target,42,false,10)])
	expect(sim.progress == 16, "Same ally cannot use the second verification slot")
	resolve(sim,[hit(guard,target,43,false,10)])
	expect(sim.progress == 32 and not sim.marks.has(target.id), "A second distinct ally consumes the remaining slot")
	sim.marks[target.id] = {"owner":analyst.id,"until":sim.elapsed+0.05,"users":[],"limit":1}
	tick(sim,0.05)
	sim._verify(guard,target)
	expect(not sim.marks.has(target.id) and sim.progress == 32, "Mark expires before effects on its exact expiry boundary")

func _equipment_and_exclusive() -> void:
	var sim = fresh(DEFAULT,["lens","backup","verify","pierce"],{"lens":1,"backup":3})
	var archer = role(sim,1)
	var analyst = role(sim,3)
	var target = foe(sim)
	place(archer,Vector2(2,2))
	place(analyst,Vector2(2,2))
	place(target,Vector2(2,1))
	resolve(sim,[hit(archer,target,51,true)])
	expect(sim.marks.has(target.id) and sim.marks[target.id].owner == archer.id and sim.marks[target.id].limit == 1, "Lens belongs to wearer and does not borrow analyst-exclusive mark capacity")
	sim.marks.clear()
	resolve(sim,[hit(archer,target,52,true)])
	expect(sim.marks.is_empty(), "Lens only exposes once per battle")
	resolve(sim,[hit(analyst,target,53,true)])
	expect(sim.marks[target.id].owner == analyst.id and sim.marks[target.id].limit == 2, "Analyst-exclusive reward upgrades only analyst marks")
	clear_shield(analyst)
	analyst.hp = analyst.max_hp*0.4
	resolve(sim,[])
	expect(is_equal_approx(analyst.shield,analyst.max_hp*0.25), "Backup grants shield only to its actual wearer")
	expect(sim.bindings.filter(func(binding): return binding.source == "reward/pierce").size() == 1 and sim.bindings.any(func(binding): return binding.source == "reward/pierce" and binding.owner == archer.id), "Pierce exclusive installs only on archer")
	# Training remains tied to character identity after changing deployment slot.
	var base = Catalog.definition(1)
	var trained = fresh([1,-1,3,2,0,-1],["training"],{},1)
	expect(is_equal_approx(role(trained,1).max_hp,base.health*1.15) and is_equal_approx(role(trained,1).atk,base.attack*1.15), "Training follows the character rather than a formation slot")
	expect(is_equal_approx(role(trained,0).max_hp,Catalog.definition(0).health), "Training does not increase other characters")

func _piercing_backline() -> void:
	var sim = fresh(DEFAULT,["pierce"])
	var archer = role(sim,1)
	var back = foe(sim,0)
	var front = foe(sim,1)
	place(archer,Vector2(3,5))
	place(back,Vector2(3,2))
	place(front,Vector2(3,3))
	sim.active_action_id = 61
	var due: Array[Dictionary] = []
	sim._skill_events(archer,front,due)
	expect(due.size() == 2 and due[0].target.id == back.id and due[1].target.id == front.id, "Backline-priority skill pierces a front enemy on the actual shot line")
	if due.size() == 2:
		expect(is_equal_approx(due[1].value,due[0].value*0.6), "Piercing hit has configured sixty-percent damage")
	sim._dispatch("skill_emit",archer,{"target":front,"action_id":61,"effects":due,"begin":0})
	expect(due.size() == 2, "Pierce cannot append a second bonus for the same action")
	due.clear()
	sim.active_action_id = 62
	sim._skill_events(archer,front,due)
	expect(due.size() == 2, "Pierce is available on the next skill action")
	due.clear()
	place(front,Vector2(5,3))
	sim.active_action_id = 63
	sim._skill_events(archer,front,due)
	expect(due.size() == 1 and due[0].target.id == back.id, "Pierce excludes enemies away from the shot line")
	due.clear()
	place(front,Vector2(3,0))
	sim.active_action_id = 64
	sim._skill_events(archer,back,due)
	expect(due.size() == 1 and due[0].target.id == back.id, "Pierce excludes a collinear enemy beyond actual attack range")
	due.clear()
	place(front,Vector2(3,6))
	sim.active_action_id = 65
	sim._skill_events(archer,back,due)
	expect(due.size() == 1 and due[0].target.id == back.id, "Pierce excludes enemies behind the shooter")

func _failed_skills() -> void:
	var sim = fresh()
	var analyst = role(sim,3)
	var target = foe(sim)
	place(analyst,Vector2(3,3))
	place(target,Vector2(3,2))
	analyst.timer = 0
	analyst.count = analyst.skill.attacks_to_trigger - 1
	expect(sim.request_action(analyst.id,target.id), "Ready analyst starts a real skill windup")
	place(target,Vector2(0,0))
	var events = tick(sim,0.8)
	expect(events.any(func(event): return event.kind == "action_missed") and sim.progress == 0, "Out-of-range skill release earns no progress")
	sim = fresh()
	analyst = role(sim,3)
	target = foe(sim)
	place(analyst,Vector2(3,3))
	place(target,Vector2(3,2))
	analyst.timer = 0
	analyst.count = analyst.skill.attacks_to_trigger - 1
	expect(sim.request_action(analyst.id,target.id), "Projectile fixture starts through action API")
	events.clear()
	for i in 20:
		events.append_array(sim.advance(0.05))
		if not sim.projectiles.is_empty(): break
	expect(not sim.projectiles.is_empty(), "Skill actually launches a projectile before target dies")
	target.hp = 0
	events.append_array(sim.advance(0.05))
	expect(events.any(func(event): return event.kind == "projectile_expired") and sim.progress == 0 and sim.marks.is_empty(), "Expired projectiles against dead targets earn neither skill progress nor marks")
	var dead = hit(analyst,target,99,true)
	resolve(sim,[dead])
	expect(not dead.valid and sim.progress == 0, "Resolver rejects already-dead skill targets")

func _maintenance_provenance() -> void:
	var sim = fresh()
	var target = foe(sim)
	sim.grant_shield(target,30,"natural")
	tick(sim,6.0)
	expect(target.shield == 100, "Natural and maintenance shields coexist")
	resolve(sim,[hit(role(sim,0),target,70,false,21.6)])
	var natural := 0.0
	for layer in target.shield_layers:
		if layer.source == "natural": natural += layer.amount
	sim.awaiting_choice = true
	sim.choose_hack("disconnect")
	expect(is_equal_approx(target.shield,natural) and natural > 0, "Disconnect only removes remaining maintenance layers after partial shield absorption")
	sim = fresh()
	target = foe(sim)
	sim.grant_shield(target,30,"natural")
	tick(sim,6.0)
	sim.awaiting_choice = true
	sim.choose_hack("takeover")
	var previous: float = target.shield
	var guard = role(sim,0)
	guard.hp *= 0.6
	clear_shield(guard)
	tick(sim,6.0)
	expect(target.shield == previous and guard.shield == 70, "Takeover preserves enemy existing shields and redirects next pulse to lowest-health ally")
