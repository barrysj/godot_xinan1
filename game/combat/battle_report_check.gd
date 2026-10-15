extends Node
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
const Report = preload("res://game/combat/battle_report.gd")
var checks := 0
var failures := 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BATTLE_REPORT_CHECK: "+label)

func row(snapshot: Dictionary, id: int) -> Dictionary:
	return snapshot.rows.filter(func(entry): return entry.id == id)[0]

func hit(sim, actor: Dictionary, target: Dictionary, amount: float) -> void:
	var due: Array[Dictionary] = []
	sim._event(due,actor,target,"damage",amount)
	sim._resolve(due)

func _ready() -> void:
	var sim = Fixture.build()
	for actor in sim.units: actor.timer = 1000
	var a: Dictionary = sim.units[0]
	var b: Dictionary = sim.units[1]
	var enemy: Dictionary = sim._living(1)[0]
	enemy.hp = 100
	enemy.max_hp = 100
	enemy.def = 0
	enemy.shield = 40
	sim.elapsed = 2
	var due: Array[Dictionary] = []
	sim._event(due,a,enemy,"damage",100)
	sim._event(due,b,enemy,"damage",100)
	sim._resolve(due)
	var snapshot: Dictionary = sim.report_stats.snapshot(sim)
	verify(is_equal_approx(row(snapshot,a.id).damage,50) and is_equal_approx(row(snapshot,b.id).damage,50),"simultaneous overkill gives proportional effective damage")
	verify(row(snapshot,enemy.id).received == 100 and row(snapshot,enemy.id).absorbed == 40,"damage taken excludes shield; absorption does not count overkill")
	verify(row(snapshot,enemy.id).defeated and row(snapshot,enemy.id).alive_time == 2,"first fatal batch records one defeat timestamp")
	sim.drain_events()
	verify(sim.report_stats.snapshot(sim) == snapshot,"draining visual events cannot erase or double-count statistics")
	a.hp = a.max_hp-10
	due = []
	sim._event(due,b,a,"heal",100,true)
	sim._resolve(due)
	verify(sim.report_stats.counters[b.id].healing == 10,"overheal is excluded")
	sim._apply_shield(a,a,10000,"report-fixture",0.1,"fixture")
	verify(sim.report_stats.counters[a.id].shield_given == 144 and sim.report_stats.counters[a.id].shield_gain == 144,"shield gains respect the actual shared cap")
	sim.advance(0.2)
	verify(sim.report_stats.counters[a.id].absorbed == 0,"expiry is not absorption")
	verify(Report.valid_snapshot(sim.report_stats.snapshot(sim)),"real accounting snapshot is valid")
	# Real request/release path; counts persist across event draining and skill counters.
	sim = Fixture.build()
	a = sim.units[0]
	enemy = sim._living(1)[0]
	for actor in sim.units: actor.timer = 1000
	a.position = Vector2(3,3)
	enemy.position = Vector2(3,2)
	a.timer = 0
	verify(sim.request_action(a.id,enemy.id),"original simulation accepts an in-range basic attack")
	for step in 12: sim.advance(0.05)
	verify(sim.report_stats.counters[a.id].attacks == 1 and sim.report_stats.counters[a.id].skills == 0,"counts released basic attacks, not render frames or trigger remainder")
	sim._start_cast(a,enemy,0.1)
	for step in 3: sim.advance(0.05)
	verify(sim.report_stats.counters[a.id].skills == 1,"skill count requires the actual release")
	# Actual programs, generation at capacity, conversion and reset.
	sim = Fixture.build(Fixture.DEFAULT,[],{},["redirect","repair"])
	a = sim.units[0]
	a.hp = a.max_hp-50
	sim.elapsed = 2
	sim._gain(a,"red",3,"fixture")
	verify(sim.cast_program("repair",a.id),"original repair is executed")
	verify(sim.report_stats.program_healing == 50 and sim.report_stats.counters[a.id].healing == 0,"direct program healing is separate from arbitrary unit attribution")
	verify(sim.report_stats.first_core == -1,"repair is not incorrectly counted as the first core program")
	sim.elapsed = 6
	sim._gain(a,"purple",2,"fixture")
	sim._gain(a,"green",1,"fixture")
	var shield_before: float = sim.report_stats.counters[a.id].shield_given
	verify(sim.cast_program("redirect"),"original core program is executed")
	verify(sim.report_stats.program_shield == 120 and sim.report_stats.counters[a.id].shield_given == shield_before,"program shields are separated from unit provision")
	verify(sim.report_stats.first_core == 6 and sim.casts == 2,"records successful first core time and all program uses")
	sim._gain(a,"blue",100,"fixture")
	verify(sim.use_item("converter","red","blue"),"conversion uses the real item route")
	snapshot = sim.report_stats.snapshot(sim)
	for kind in sim.Codes.RULES.types:
		verify(snapshot.generated.get(kind,0)-snapshot.overflow.get(kind,0)-snapshot.spent.get(kind,0) == snapshot.remaining.get(kind,0),"resource accounting balances including conversion: "+kind)
	verify(Report.valid_snapshot(snapshot),"program and resource snapshot passes codec validation")
	var malformed: Dictionary = snapshot.duplicate(true)
	malformed.rows[0].absorbed = NAN
	verify(not Report.valid_snapshot(malformed),"rejects nonfinite optional counters")
	malformed = snapshot.duplicate(true)
	malformed.rows.append(malformed.rows[0].duplicate(true))
	verify(not Report.valid_snapshot(malformed),"rejects duplicate unit records")
	malformed = snapshot.duplicate(true)
	malformed.first_core = snapshot.duration+1
	verify(not Report.valid_snapshot(malformed),"rejects future program timestamps")
	var pursuit = Fixture.build(Fixture.DEFAULT,[],{},["disconnect","repair"])
	var pursuer: Dictionary = pursuit.units[0]
	var victim: Dictionary = pursuit._living(1)[0]
	pursuit._place_scan(pursuer,victim)
	pursuit._verify(pursuit.units[1],victim)
	pursuit.elapsed = 2
	pursuit.blocks.red = 1
	pursuit.blocks.blue = 3
	var before := 0.0
	for entry in pursuit.report_stats.counters.values(): before += entry.damage
	var hp_before: float = victim.hp
	verify(pursuit.cast_program("disconnect",victim.id),"actual pursuit is valid on a confirmed target")
	var after := 0.0
	for entry in pursuit.report_stats.counters.values(): after += entry.damage
	verify(after > before and is_equal_approx(pursuit.report_stats.program_damage+after-before,hp_before-victim.hp),"direct pursuit and already queued unit followup retain their actual independent attribution")
	verify(pursuit.report_stats.counters[pursuer.id].healing == 0,"program commands do not create unit healing")
	var rescue = Fixture.build()
	var rescued: Dictionary = rescue._living(0)[1]
	var attacker: Dictionary = rescue._living(1)[0]
	rescue.elapsed = 2.0
	hit(rescue,attacker,rescued,10000)
	rescue.elapsed = 4.0
	rescue.items.revive = 1
	verify(rescue.use_item("revive",str(rescued.id)),"actual preparation item revives fallen teammate")
	rescue.elapsed = 8.0
	var revived_report: Dictionary = rescue.report_stats.snapshot(rescue)
	verify(not row(revived_report,rescued.id).defeated and row(revived_report,rescued.id).alive_time == 6.0 and row(revived_report,rescued.id).first_defeat == 2.0,"revival preserves first defeat but counts subsequent living time")
	rescue.items.shield = 1
	var original_supply: float = rescue.report_stats.counters[rescue._living(0)[0].id].shield_given
	verify(rescue.use_item("shield",str(rescued.id)),"actual preparation shield is available")
	verify(rescue.report_stats.item_shield == 120 and rescue.report_stats.counters[rescue._living(0)[0].id].shield_given == original_supply,"item shield is not falsely attributed to the first teammate")
	rescue.elapsed = 9.0
	hit(rescue,attacker,rescued,10000)
	rescue.elapsed = 10.0
	var fallen_report: Dictionary = rescue.report_stats.snapshot(rescue)
	verify(row(fallen_report,rescued.id).defeated and row(fallen_report,rescued.id).alive_time == 7.0,"second defeat stops accumulated living time")
	verify(Report.valid_snapshot(JSON.parse_string(JSON.stringify(fallen_report))),"revival report survives original JSON contract")
	verify(Report.valid_snapshot({}),"absent legacy extension remains compatible")
	var independent := snapshot.duplicate(true)
	sim.generated.clear()
	verify(snapshot == independent,"stored report is detached from later simulation mutation")
	sim.reset(sim.units)
	verify(sim.report_stats.first_core == -1 and sim.report_stats.program_healing == 0 and sim.report_stats.deaths.is_empty() and sim.report_stats.converted.is_empty(),"retry clears all bounded counters")
	verify(sim.report_stats.counters.values().all(func(entry): return entry.values().all(func(value): return value == 0)),"new battle has no previous contribution")
	print("BATTLE_REPORT_ACCOUNTING_CHECK %d checks / %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
