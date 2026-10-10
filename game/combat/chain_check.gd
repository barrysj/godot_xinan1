extends Node
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
const Codes = preload("res://game/combat/code_catalog.gd")
const Run = preload("res://game/run/short_run.gd")
var checks := 0
var failures := 0
var empty_batch: Array[Dictionary] = []
func expect(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func fresh():
	var sim = Fixture.build([0,5,-1,3,1,-1], [], {}, ["disconnect", "redirect"])
	for u in sim.units: u.hp = 10000.0; u.max_hp = 10000.0
	return sim
func hit(sim, actor: Dictionary, target: Dictionary, amount: float) -> void:
	sim.next_action_id += 1
	sim.active_action_id = sim.next_action_id
	var due: Array[Dictionary] = []
	sim._event(due, actor, target, "damage", amount)
	sim._resolve(due)
func _ready() -> void:
	expect(Codes.validate().is_empty(), "definitions validate")
	var sim = fresh()
	var analyst: Dictionary = sim.units.filter(func(u): return u.content_id == "analyst")[0]
	var other: Dictionary = sim.units.filter(func(u): return u.content_id == "archer")[0]
	var foe: Dictionary = sim._living(1)[0]
	sim._place_scan(analyst, foe)
	hit(sim, analyst, foe, 1)
	expect(sim.blocks.blue == 0, "owner cannot verify")
	hit(sim, other, foe, 1)
	expect(sim.blocks.blue == 1, "verification gives one blue")
	expect(sim.marks[foe.id].confirmed_until > sim.elapsed, "confirmed window remains")
	var damage: float = other.damage
	hit(sim, other, foe, 1)
	expect(other.damage - damage <= 1, "one opportunity one verification")
	sim.elapsed = 4.1
	sim._place_scan(analyst, foe)
	hit(sim, other, foe, 1)
	expect(sim.blocks.blue == 2, "next scan verifies again")
	sim.blocks.blue = 3; sim.blocks.red = 1
	expect(sim.cast_program("disconnect", foe.id), "pursuit legal")
	expect(sim.blocks.blue == 0 and sim.blocks.red == 0, "exact debit")
	damage = other.damage
	hit(sim, other, foe, 1)
	expect(other.damage - damage > 10, "exposed hit follows up")
	damage = other.damage
	hit(sim, other, foe, 1)
	expect(other.damage - damage <= 1, "followup one per actor")
	sim.ready_at = 0
	expect(not sim.cast_program("disconnect"), "individual cooldown")

	sim = fresh()
	var ally: Dictionary = sim._living(0)[0]
	foe = sim._living(1)[0]
	sim.grant_shield(ally, 100, "test", 10)
	hit(sim, foe, ally, 50)
	expect(sim.blocks.purple == 0, "remainder retained")
	hit(sim, foe, ally, 60)
	expect(sim.blocks.purple == 0 and sim.pending_code_cycles.size() == 1, "absorption threshold starts collection")
	for i in 6: sim.advance(0.05)
	expect(sim.blocks.purple == 1, "absorption production settles after collection")
	expect(sim.absorbed > 0 and sim.absorbed < 80, "fractional remainder")
	sim.blocks.purple = 2; sim.blocks.green = 1
	expect(sim.cast_program("redirect"), "recoil legal")
	for u in sim._living(0):
		expect(u.shield_layers.any(func(layer): return layer.source == "recoil" and layer.amount == 30), "independent layer")
	ally.position = foe.position
	sim.events.clear()
	hit(sim, foe, ally, 100)
	expect(sim.events.filter(func(e): return e.kind == "recoil_burst" and e.actor_id == ally.id).size() == 1, "break explodes once")
	sim.elapsed += 6; sim._expire_shields(ally); sim._resolve(empty_batch)
	expect(sim.events.filter(func(e): return e.kind == "recoil_burst" and e.actor_id == ally.id).size() == 1, "expiry cannot repeat")

	sim = fresh()
	ally = sim._living(0)[0]; foe = sim._living(1)[0]
	sim.blocks.purple = 2; sim.blocks.green = 1; sim.cast_program("redirect")
	ally.hp = 1; ally.position = foe.position; sim.events.clear()
	hit(sim, foe, ally, 1000)
	expect(ally.hp == 0, "lethal hits kill")
	expect(sim.events.any(func(e): return e.kind == "recoil_burst" and e.actor_id == ally.id), "lethal break explodes")
	sim = fresh()
	sim.blocks.purple = 2; sim.blocks.green = 1; sim.cast_program("redirect")
	sim.elapsed = 6; sim.events.clear()
	for u in sim._living(0): sim._expire_shields(u)
	sim._resolve(empty_batch)
	expect(sim.events.filter(func(e): return e.kind == "recoil_burst").size() == 4, "all four expiries explode")

	sim = fresh(); sim.loadout = ["disconnect", "repair"]
	ally = sim._living(0)[0]; ally.hp -= 80; sim.blocks.red = 3
	expect(not sim.cast_program("repair", ally.id, {"red":2}), "bad payment rejected")
	expect(sim.blocks.red == 3, "payment failure atomic")
	expect(sim.cast_program("repair", ally.id, {"red":3}), "any color repair")
	expect(ally.hp == ally.max_hp - 20, "heal sixty")
	sim.ready_at = 0; sim.elapsed = 12
	expect(not sim.cast_program("repair"), "repair once")
	expect(sim.use_item("supply", "blue"), "chosen supply")
	sim.items.supply = 1
	expect(not sim.use_item("supply", "green"), "item once per battle")
	var run = Run.new()
	var saved: Dictionary = run.to_dict()
	saved.code_programs = ["disconnect", "takeover"]
	expect(run.restore(saved), "old save valid")
	expect(run.code_programs == ["disconnect", "redirect"], "retired id migrates")

	for formation in [[0,5,-1,3,1,-1], [0,5,-1,4,2,-1], [0,2,-1,3,1,-1]]:
		sim = Fixture.build(formation)
		var first := -1.0
		for step in range(1800):
			sim.advance(0.05)
			for id in sim.loadout:
				if sim.program_error(id).is_empty():
					if first < 0: first = sim.elapsed
					sim.cast_program(id)
			if sim.finished: break
		expect(sim.finished, "real combat terminates")
		print("CHAIN_PARTY ", sim.units.filter(func(u): return u.side == 0).map(func(u): return {"name":u.name,"hp":u.hp,"damage":u.damage}))
		print("CHAIN_BENCH formation=%s win=%s time=%.2f first=%.2f casts=%d generated=%s" % [formation,sim.won,sim.elapsed,first,sim.casts,sim.generated])
	print("CHAIN_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
