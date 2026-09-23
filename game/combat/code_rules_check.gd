extends Node
const Sim = preload("res://game/combat/code_battle_simulation.gd")
const Codes = preload("res://game/combat/code_catalog.gd")
const Catalog = preload("res://game/trial/trial_catalog.gd")
var checks := 0
var failures := 0

func expect(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)

func fresh(programs: Array = ["disconnect", "takeover"]):
	var sim = Sim.new()
	sim.start([0,-1,-1,2,1,3], 0, [], {}, -1, programs, Codes.stock())
	return sim

func impact(sim, actor: Dictionary, target: Dictionary, action: int, damage: float = 1) -> void:
	var hits: Array[Dictionary] = []
	sim.active_action_id = action
	sim._event(hits, actor, target, "damage", damage)
	sim._resolve(hits)

func _ready() -> void:
	expect(Codes.validate().is_empty(), "resource definitions valid")
	_config_validation()
	_production()
	_commands()
	_items()
	print("CODE_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _config_validation() -> void:
	var rules = Codes.RULES
	var person = Catalog.MANIFEST.characters[0]
	var original: int = rules.cache_cap
	rules.cache_cap = 0
	expect(not Codes.validate().is_empty(), "invalid cache rejected")
	rules.cache_cap = original
	var program = Codes.program("repair")
	var cost: Dictionary = program.cost.duplicate()
	for bad in [{"missing":1}, {"blue":0}, {"green":0.5}, {"red":99}]:
		program.cost = bad
		expect(not Codes.validate().is_empty(), "invalid recipe rejected")
	program.cost = cost
	program.effect = "unsupported"
	expect(not Codes.validate().is_empty(), "unknown program effect rejected")
	program.effect = "repair"
	var kind: String = person.code_type
	person.code_type = "unknown"
	expect(not Codes.validate().is_empty(), "unknown character production rejected")
	person.code_type = kind
	expect(Codes.validate().is_empty(), "fixtures restored without resource contamination")
	expect(not Codes.validate(null).is_empty(), "null config reports errors")
	var invalid = rules.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.programs[0] = Resource.new()
	expect(not Codes.validate(invalid).is_empty(), "wrong program resource reports errors instead of crashing")
	invalid = rules.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	invalid.items[0] = null
	expect(not Codes.validate(invalid).is_empty(), "null item reports errors instead of crashing")

func _production() -> void:
	var sim = fresh()
	var actor: Dictionary = sim.units.filter(func(u): return u.get("role") == 1)[0]
	var foe: Dictionary = sim._living(1)[0]
	sim.grant_shield(foe, 100, "test")
	impact(sim, actor, foe, 1)
	impact(sim, actor, foe, 1)
	impact(sim, actor, foe, 2)
	expect(sim.blocks.red == 0, "duplicate action and two attacks produce no block")
	impact(sim, actor, foe, 3)
	expect(sim.blocks.red == 1, "third shield-blocked attack produces one block")
	var hits: Array[Dictionary] = []
	sim.active_action_id = 4
	sim._event(hits, actor, foe, "damage", 1, true)
	sim._resolve(hits)
	expect(sim.attack_counts[actor.id] == 0, "skill hit does not count as basic attack")
	foe.hp = 0
	impact(sim, actor, foe, 5)
	expect(sim.attack_counts[actor.id] == 0, "dead target produces no block")
	foe.hp = 10
	impact(sim, actor, foe, 6, 0)
	expect(sim.attack_counts[actor.id] == 0, "zero damage produces no block")
	var author: Dictionary = sim.units.filter(func(u): return u.get("role") == 3)[0]
	sim.marks[foe.id] = {"owner":author.id,"until":4.0,"users":[],"limit":2}
	sim._verify(author, foe)
	expect(sim.blocks.blue == 0, "author cannot verify itself")
	sim._verify(actor, foe)
	sim._verify(actor, foe)
	expect(sim.blocks.blue == 1 and sim.blocks.red == 1, "verification awards author color once per verifier")
	sim._verify(sim.units[0], foe)
	expect(sim.blocks.blue == 2 and not sim.marks.has(foe.id), "second unique verifier consumes upgraded mark")
	sim.blocks.blue = 6
	sim._gain(author, "blue", 4, "test")
	expect(sim.blocks.blue == 6, "production respects cap")
	sim.progress = 0
	for i in 5: sim._add_progress(actor, 100, "legacy")
	expect(not sim.awaiting_choice and sim.progress == 0, "legacy meter cannot pause new mode")
	sim.start([0,-1,-1,2,1,3], 0, [], {}, -1)
	expect(sim.blocks.values().all(func(n): return n == 0) and sim.attack_counts.is_empty(), "retry clears all battle resource state")

func _commands() -> void:
	var sim = fresh()
	var before: Dictionary = sim.blocks.duplicate()
	expect(not sim.cast_program("disconnect") and sim.blocks == before, "unaffordable command is atomic")
	expect(not sim.cast_program("repair"), "uncarried command rejected")
	var foe: Dictionary = sim._living(1)[0]
	sim.grant_shield(foe, 40, "maintenance")
	sim.grant_shield(foe, 20, "native")
	sim.blocks.red = 2
	sim.blocks.purple = 3
	sim.blocks.blue = 2
	expect(sim.cast_program("disconnect") and sim.blocks.red == 0 and sim.blocks.purple == 2, "disconnect spends exact recipe")
	expect(foe.shield == 20 and sim.pending_pulse == "disconnect", "disconnect removes only system shields")
	before = sim.blocks.duplicate()
	expect(not sim.cast_program("takeover") and sim.blocks == before, "shared cooldown rejects repeat without spend")
	sim.elapsed = sim.ready_at
	expect(not sim.cast_program("takeover") and sim.blocks == before, "pending pulse cannot be overwritten")
	sim._maintenance_pulse()
	expect(foe.shield == 20 and sim.pending_pulse.is_empty(), "disconnect skips exactly one pulse")
	sim._maintenance_pulse()
	expect(foe.shield > 20, "enemy maintenance resumes after skip")
	expect(sim.cast_program("takeover") and sim.system_taken, "permanent takeover spends recipe")
	var ally: Dictionary = sim.units[1]
	ally.hp = 1
	var shield: float = ally.shield
	sim._maintenance_pulse()
	expect(ally.shield > shield, "takeover protects lowest ratio ally")
	sim.elapsed = sim.ready_at
	expect(not sim.cast_program("takeover"), "takeover cannot execute twice")
	sim = fresh(["redirect", "repair"])
	foe = sim._living(1)[0]
	sim.grant_shield(foe, 30, "maintenance")
	sim.blocks.blue = 4
	sim.blocks.green = 3
	expect(not sim.cast_program("repair") and sim.blocks.green == 3, "full health repair does not spend")
	ally = sim.units[1]
	ally.hp = 20
	var other: Dictionary = sim.units[2]
	other.hp = 30
	expect(sim.cast_program("redirect"), "redirect accepted")
	shield = ally.shield
	sim._maintenance_pulse()
	expect(ally.shield > shield and foe.shield == 30, "redirect protects ally without removing existing enemy shield")
	sim._maintenance_pulse()
	expect(foe.shield > 30, "redirect only affects next pulse")
	sim.elapsed = sim.ready_at
	var hp: float = ally.hp
	var hp2: float = other.hp
	expect(sim.cast_program("repair"), "repair accepted")
	expect(is_equal_approx(ally.hp - hp, ally.max_hp * 0.25) and is_equal_approx(other.hp - hp2, other.max_hp * 0.25), "repair heals two lowest ratios")
	sim.finished = true
	expect(not sim.cast_program("repair") and not sim.use_item("supply", "red"), "post-combat commands rejected")

func _items() -> void:
	var sim = fresh()
	sim.blocks.blue = 4
	var before: Dictionary = sim.blocks.duplicate()
	expect(not sim.use_item("supply", "blue") and sim.items.supply == 1 and sim.blocks == before, "full cache prevents item loss")
	expect(not sim.use_item("supply", "unknown") and sim.items.supply == 1, "bad type does not consume")
	expect(sim.use_item("supply", "purple") and sim.blocks.purple == 3 and sim.items.supply == 0, "supply generates three chosen blocks")
	expect(not sim.use_item("supply", "red"), "spent supply cannot duplicate")
	expect(not sim.use_item("converter", "purple", "purple") and sim.items.converter == 1, "self conversion rejected")
	expect(not sim.use_item("converter", "green", "red"), "insufficient conversion source rejected")
	expect(sim.use_item("converter", "blue", "purple") and sim.blocks.blue == 6 and sim.blocks.purple == 1, "conversion consumes two source and generates two target")
