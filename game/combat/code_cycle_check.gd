extends Node
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
var checks := 0
var failures := 0
var next_hit := 1000

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func fresh():
	var sim = Fixture.build()
	for u in sim.units:
		u.hp = 100000.0; u.max_hp = 100000.0; u.def = 0.0; u.timer = 1000.0; u.move_speed = 0.0
		u.shield = 0.0; u.shield_layers = []; u.moving = false
	sim.warning_next.clear(); sim.events.clear(); sim.tag_ids.clear()
	return sim

func author(sim) -> Dictionary:
	return sim.units.filter(func(u): return u.content_id == "archer")[0]

func hit(sim, actor: Dictionary, target: Dictionary, damage := 1.0) -> void:
	next_hit += 1
	sim.active_action_id = next_hit
	var due: Array[Dictionary] = []
	sim._event(due,actor,target,"damage",damage)
	sim._resolve(due)

func basics(sim, count: int) -> void:
	for i in count: hit(sim,author(sim),sim._living(1)[0])

func steps(sim, count: int) -> Array:
	var events: Array = []
	for i in count: events.append_array(sim.advance(0.05))
	return events

func _ready() -> void:
	attack_cycle()
	multiple_and_capacity()
	shield_cycle()
	death_and_close()
	reset_and_items()
	print("CODE_CYCLE_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func attack_cycle() -> void:
	var sim = fresh()
	var actor := author(sim)
	basics(sim,2)
	expect(sim.pending_code_cycles.is_empty() and sim.attack_counts[actor.id] == 2,"First two valid hits accumulate without producing")
	basics(sim,1)
	expect(sim.blocks[actor.code_type] == 0 and sim.pending_code_cycles.size() == 1,"Third hit queues earned code without early credit")
	expect(sim.attack_counts[actor.id] == 0,"Completed threshold resets immediately for next cycle")
	var started: Array = sim.events.filter(func(e): return e.kind == "code_cycle_started")
	expect(started.size() == 1 and is_equal_approx(started[0].duration,0.3) and is_equal_approx(started[0].ready_at,0.3),"UI event exposes actual simulation deadline")
	expect(started[0].actor_id == actor.id and not started[0].shared and started[0].amount == 1,"Attack cycle attributes its author and amount")
	var frozen: Array = [sim.elapsed,sim.pending_code_cycles.duplicate(true),sim.blocks.duplicate()]
	sim.advance(0); sim.advance(-1)
	expect(frozen == [sim.elapsed,sim.pending_code_cycles,sim.blocks],"Paused/invalid advances preserve queue and inventory")
	steps(sim,5)
	expect(sim.blocks[actor.code_type] == 0 and sim.pending_code_cycles.size() == 1,"No resource before 0.30 simulated seconds")
	basics(sim,1)
	expect(sim.attack_counts[actor.id] == 1,"New hit during collection belongs to the next cycle")
	var events := steps(sim,1)
	expect(sim.blocks[actor.code_type] == 1 and sim.pending_code_cycles.is_empty(),"Sixth fixed step credits exactly once")
	var generated: Array = events.filter(func(e): return e.kind == "code_generated")
	expect(generated.size() == 1 and generated[0].cycle_id == started[0].cycle_id,"Credit event links to the originating collection")
	expect(events.filter(func(e): return e.kind == "code_cycle_completed").size() == 1,"Completion event ends the UI cycle")
	steps(sim,10)
	expect(sim.blocks[actor.code_type] == 1,"Subsequent resolution cannot credit the completed cycle twice")

func multiple_and_capacity() -> void:
	var sim = fresh()
	var actor := author(sim)
	basics(sim,6)
	expect(sim.pending_code_cycles.size() == 2,"Rapid completed cycles each remain queued")
	expect(sim.pending_code_cycles[0].cycle_id != sim.pending_code_cycles[1].cycle_id,"Concurrent cycles have unique IDs")
	sim.blocks[actor.code_type] = sim.Codes.RULES.cache_cap - 1
	var events := steps(sim,6)
	expect(sim.blocks[actor.code_type] == sim.Codes.RULES.cache_cap,"Delivery applies live cache cap")
	expect(sim.generated[actor.code_type] == 2 and sim.overflow[actor.code_type] == 1,"Full-cache delivery records earned and overflow separately")
	var complete: Array = events.filter(func(e): return e.kind == "code_cycle_completed")
	expect(complete.size() == 2 and complete[1].actual == 0 and complete[1].overflow == 1,"Overflow still ends its collection animation")
	sim = fresh(); actor = author(sim)
	sim.blocks[actor.code_type] = sim.Codes.RULES.cache_cap
	basics(sim,3)
	sim.blocks[actor.code_type] -= 1
	sim.advance(0.3)
	expect(sim.blocks[actor.code_type] == sim.Codes.RULES.cache_cap and sim.overflow[actor.code_type] == 0,"Capacity is evaluated on delivery after intervening spending")
	var stepped = fresh(); var jumped = fresh()
	basics(stepped,3); basics(jumped,3)
	steps(stepped,6); jumped.advance(0.3)
	expect(stepped.blocks == jumped.blocks and stepped.generated == jumped.generated,"Fixed-step and equivalent large advance settle the same earned amount")

func shield_cycle() -> void:
	var sim = fresh()
	var foe: Dictionary = sim._living(1)[0]
	var allies: Array = sim._living(0)
	for i in 2:
		sim.grant_shield(allies[i],100,"test")
		hit(sim,foe,allies[i],100)
	expect(sim.pending_code_cycles.size() == 2 and is_equal_approx(sim.absorbed,40),"Shared absorption queues both thresholds and keeps remainder")
	expect(sim.blocks.purple == 0,"Absorbed shield code also waits for collection")
	var events: Array = sim.events.filter(func(e): return e.kind == "code_cycle_started")
	expect(events.size() == 2 and events.all(func(e): return e.shared and e.code_type == "purple"),"Purple collection is explicitly team-shared")
	steps(sim,6)
	expect(sim.blocks.purple == 2 and sim.generated.purple == 2,"Shared purple thresholds credit exactly once each")

func death_and_close() -> void:
	var sim = fresh()
	var actor := author(sim)
	basics(sim,3); actor.hp = 0
	steps(sim,6)
	expect(sim.blocks[actor.code_type] == 1,"Earned production survives its author's death")
	sim = fresh(); actor = author(sim)
	basics(sim,3)
	for foe in sim._living(1): foe.hp = 0
	steps(sim,1)
	expect(sim.closing and not sim.finished,"Victory waits briefly for already-earned production")
	expect(sim.program_error("redirect") == "战斗已结束","Closing cannot spend resources in an already-decided battle")
	steps(sim,5)
	expect(sim.finished and sim.won and sim.blocks[actor.code_type] == 1,"Victory settles queued production before final report")
	sim = fresh(); actor = author(sim)
	basics(sim,3)
	for ally in sim._living(0): ally.hp = 0
	steps(sim,6)
	expect(sim.finished and not sim.won and sim.blocks[actor.code_type] == 1,"Defeat also retains earned production for report")

func reset_and_items() -> void:
	var sim = fresh(); var actor := author(sim)
	basics(sim,3)
	sim.reset(sim.units)
	expect(sim.pending_code_cycles.is_empty() and sim.next_code_cycle_id == 0,"Reset clears pending production and identifiers")
	steps(sim,6)
	expect(sim.blocks[actor.code_type] == 0,"Old queued production cannot enter reset battle")
	basics(sim,3)
	sim.configure_combat(["disconnect","redirect"],sim.Codes.stock())
	expect(sim.pending_code_cycles.is_empty() and sim.attack_counts.is_empty(),"Configuration clears old queue and partial cycles")
	expect(sim.use_item("supply","red") and sim.blocks.red == 3,"Item-generated resources remain immediate")
	expect(sim.pending_code_cycles.is_empty(),"Item use never creates natural collection queue")
