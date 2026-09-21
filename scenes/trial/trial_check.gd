extends Node
const Sim = preload("res://game/trial/trial_simulation.gd")
const Model = preload("res://game/trial/trial_run.gd")
const Catalog = preload("res://game/trial/trial_catalog.gd")
var checks := 0
var failures := 0

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	_mechanics()
	var run = Model.new()
	expect(Catalog.active_tags(run.formation) == ["运动社", "广播站", "守护"], "default synergies")
	expect(not run.assign(5, 1), "cannot deploy a fifth ally into empty slot")
	expect(run.assign(5, 4) and not run.formation.has(1), "bench replacement")
	run.restart()
	expect(not run.select_reward("lens"), "cannot claim before victory")
	run.finish(true, "won")
	expect(run.select_reward("training", 1), "targeted training")
	expect(not run.select_reward("backup"), "reward cannot be claimed twice")
	var snapshot = run.snapshot()
	var restored = Model.new()
	expect(restored.restore(JSON.parse_string(JSON.stringify(snapshot))), "JSON checkpoint roundtrip")
	expect(restored.battle == 1 and restored.trainee == 1, "training persists")
	snapshot.formation = [0, 0, -1, 2, 1, 3]
	expect(not restored.restore(snapshot) and restored.battle == 1, "invalid checkpoint rejected atomically")
	run.path = "res://.godot/trial-check.json"
	expect(run.save(), "save test checkpoint")
	expect(run.save(), "replace existing checkpoint atomically")
	var saved = Model.new()
	saved.path = run.path
	expect(saved.read_save() and saved.trainee == 1, "read saved checkpoint")
	run.finish(true, "won")
	expect(run.select_reward("backup"), "second reward")
	expect(run.equip("backup", 3), "equip")
	run.finish(true, "complete")
	expect(run.unlocked and run.phase == "complete", "completion unlock")
	run.restart("lens")
	expect(run.gear.lens == 1 and run.rewards == ["lens"], "starting supply reset")
	var formations = [[0, -1, -1, 2, 1, 3], [0, -1, -1, 2, 4, 3], [0, -1, 5, -1, 1, 4]]
	var builds = [["lens", "verify"], ["training", "pierce"], ["cover", "backup"]]
	for f in range(formations.size()):
		for b in range(3):
			for choice in ["disconnect", "takeover"]:
				var sim = Sim.new()
				var items = builds[f]
				var equipment = {"lens": 1} if f == 0 else ({"backup": 3} if f == 2 else {})
				sim.start(formations[f], b, items, equipment, 1 if f == 1 else -1)
				var pause_seen = false
				for tick in range(1900):
					sim.advance(0.05)
					if sim.awaiting_choice:
						pause_seen = true
						var time = sim.elapsed
						var hp = sim.units.map(func(u): return u.hp)
						sim.advance(5)
						expect(sim.elapsed == time and hp == sim.units.map(func(u): return u.hp), "hack choice freezes simulation")
						expect(not sim.choose_hack("invalid"), "invalid choice rejected")
						expect(sim.choose_hack(choice) and not sim.choose_hack(choice), "choice exactly once")
					if sim.finished: break
				expect(sim.finished, "battle terminates")
				print("TRIAL sample team=%d battle=%d choice=%s won=%s time=%.1f hack=%d paused=%s" % [f, b, choice, sim.won, sim.elapsed, sim.progress, pause_seen])
	# Full unboosted-to-reward runs, not just end-build encounters.
	for route in range(3):
		var journey = Model.new()
		for b in range(3):
			var sim = Sim.new()
			sim.start(journey.formation, b, journey.rewards, journey.gear, journey.trainee)
			for tick in range(1900):
				sim.advance(0.05)
				if sim.awaiting_choice: sim.choose_hack("disconnect" if route != 2 else "takeover")
				if sim.finished: break
			expect(sim.won, "route %d battle %d wins" % [route, b])
			journey.finish(sim.won, "sample")
			if b < 2:
				var id: String = builds[route][b]
				expect(journey.select_reward(id, 1 if id == "training" else -1), "route reward")
				if id in ["lens", "backup"]: journey.equip(id, 1 if id == "lens" else 3)
		expect(journey.unlocked, "full route unlock")
	print("TRIAL CHECK: %d checks / %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _mechanics() -> void:
	var formation = [0, -1, -1, 2, 1, 3]
	var sim = Sim.new()
	sim.start(formation, 0, ["verify"], {}, -1)
	var analyst = sim.units.filter(func(u): return u.role == 3)[0]
	var archer = sim.units.filter(func(u): return u.role == 1)[0]
	var guard = sim.units[0]
	var foe = sim.units.filter(func(u): return u.side == 1)[0]
	sim.marks[foe.id] = {"owner": analyst.id, "until": 4.0, "users": [], "limit": 2}
	sim._verify(analyst, foe)
	expect(sim.progress == 0, "mark author cannot self-verify")
	sim._verify(archer, foe)
	sim._verify(archer, foe)
	expect(sim.progress == 16 and sim.marks.has(foe.id), "same ally cannot double-verify")
	sim._verify(guard, foe)
	expect(sim.progress == 32 and not sim.marks.has(foe.id), "different ally completes upgraded mark")
	sim.marks[foe.id] = {"owner": analyst.id, "until": -1.0, "users": [], "limit": 1}
	sim._verify(archer, foe)
	expect(sim.progress == 32, "expired marks give no progress")
	foe.shield = 70.0
	foe.system_shield = 50.0
	sim.progress = 100
	sim.awaiting_choice = true
	sim.choose_hack("disconnect")
	expect(foe.shield == 20 and foe.system_shield == 0, "disconnect preserves non-system shields")
	sim.start(formation, 0, [], {}, -1)
	foe = sim.units.filter(func(u): return u.side == 1)[0]
	foe.shield = 70.0
	foe.system_shield = 50.0
	sim.progress = 100
	sim.awaiting_choice = true
	sim.choose_hack("takeover")
	expect(foe.shield == 70, "takeover preserves existing enemy shields")
	var lowest = sim.units[1]
	lowest.hp = 1.0
	sim.next_pulse = 0
	sim.advance(0.05)
	expect(lowest.shield > 0, "takeover protects lowest-health ally")
	sim.start(formation, 0, [], {}, -1)
	var base_interval: float = sim.units[0].interval
	for enemy in sim.units.filter(func(u): return u.side == 1): enemy.hp = 0
	sim.progress = 100
	sim.advance(0.05)
	expect(sim.finished and sim.won and not sim.awaiting_choice, "victory takes priority over full hack meter")
	sim.start(formation, 0, [], {}, -1)
	expect(sim.progress == 0 and sim.hack_choice.is_empty() and sim.units[0].interval == base_interval, "retry resets combat-only state")
	expect(sim.units.all(func(u): return u.hp == u.max_hp), "retry restores every character")
	var first = _replay(formation, 1)
	var second = _replay(formation, 2)
	expect(first == second, "1x and 2x fixed-step outcome identical")
	var model = Model.new()
	model.rewards = ["lens", "backup"]
	model.gear = {"lens": 1, "backup": 3}
	expect(model.equip("backup", 1) and model.gear.lens == -1, "transferring equipment returns occupied item to bag")
	model.path = "res://.godot/no-such-trial-directory/save.json"
	expect(not model.save(), "failed persistence returns failure")
	# Skill contribution must not be awarded when damage is only launched.
	sim.start(formation, 0, [], {}, -1)
	archer = sim.units.filter(func(u): return u.role == 1)[0]
	foe = sim.units.filter(func(u): return u.side == 1)[0]
	archer.position = Vector2(2, 3)
	foe.position = Vector2(2, 1)
	var effects: Array[Dictionary] = []
	sim.active_action_id = 123
	sim._skill_events(archer, foe, effects)
	expect(sim.progress == 0, "skill generation does not award progress before impact")
	sim._resolve(effects)
	expect(sim.progress == 4, "skill contributes once on impact")
	sim._resolve(effects)
	expect(sim.progress == 4, "multiple hits of one skill do not multiply base contribution")

func _replay(formation: Array, batch: int) -> Array:
	var sim = Sim.new()
	sim.start(formation, 2, ["lens", "verify"], {"lens": 1}, -1)
	for frame in range(1900):
		for step in range(batch):
			sim.advance(0.05)
			if sim.awaiting_choice: sim.choose_hack("disconnect")
			if sim.finished: break
		if sim.finished: break
	return [sim.won, sim.elapsed, sim.progress, sim.units.map(func(u): return u.hp)]
