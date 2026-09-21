extends Node
## Isolated integration checks. Never reads or writes user:// player progress.
const Model = preload("res://game/trial/trial_run.gd")
var checks := 0
var failures := 0
var directory := ""

func _ready() -> void:
	directory = "res://.godot/trial-run-check-" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	_state_invariants()
	_legacy_migration()
	_transactions()
	_recovery()
	print("TRIAL RUN CHECK: %d checks / %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _fresh(filename: String):
	var run = Model.new()
	run.path = directory + "/" + filename + ".json"
	return run

func _state_invariants() -> void:
	var run = _fresh("invariants")
	var before: Dictionary = run.snapshot()
	expect(run.can_start() and run.options().is_empty(), "fresh party can start without receiving a reward")
	expect(not run.restart("lens") and run.snapshot() == before, "locked starting supply cannot be granted")
	for mutation in [
		{"formation": [-1, -1, -1, -1, -1, -1]},
		{"formation": [0, 0, -1, 2, 1, 3]},
		{"battle": 1},
		{"phase": "complete", "battle": 2, "unlocked": true},
		{"rewards": ["cover"]},
		{"gear": {"lens": 1}},
		{"starting_supply": "lens", "rewards": ["lens"], "gear": {"lens": 1}},
		{"trainee": 4},
		{"version": 500},
		{"battle": 0.25},
	]:
		var bad: Dictionary = before.duplicate(true)
		bad.merge(mutation, true)
		expect(not run.restore(bad) and run.snapshot() == before, "invalid checkpoint rejected without partial mutation: " + str(mutation))
	expect(run.finish(true, "first victory"), "first victory opens rewards")
	before = run.snapshot()
	expect(not run.finish(false, "late duplicate") and run.snapshot() == before, "late outcome cannot erase a won reward")
	expect(not run.assign(5, 4) and not run.equip("lens", 3), "preparation commands reject reward phase")
	expect(not run.select_reward("training", -1) and run.snapshot() == before, "targeted training requires a valid target")
	expect(run.select_reward("training", 3) and run.trainee == 3, "training binds to chosen character")
	expect(run.assign(4, 5) and run.trainee == 3, "training remains with benched character")
	expect(run.assign(3, 5) and run.trainee == 3, "trained character can return without losing investment")
	before = run.snapshot()
	expect(not run.select_reward("cover") and run.snapshot() == before, "already claimed reward cannot advance battle again")
	run.finish(true, "second victory")
	expect(run.select_reward("backup") and run.gear.backup == -1, "new equipment enters inventory")
	run.equip("backup", 3)
	expect(run.finish(true, "final victory") and run.unlocked, "final victory unlocks future starting supply")
	before = run.snapshot()
	expect(not run.finish(false, "late failure") and run.snapshot() == before, "completed trial cannot revert on duplicate outcome")
	expect(run.restart("lens") and run.claimed_rewards.is_empty() and run.starting_supply == "lens", "new run clears claims but retains unlocked supply")
	run.finish(true, "supply victory")
	before = run.snapshot()
	expect(not run.select_reward("lens") and run.snapshot() == before, "starting item cannot be claimed a second time")
	run.select_reward("cover")
	run.finish(true, "second")
	run.select_reward("backup")
	expect(run.equip("backup", 1) and run.gear.lens == -1 and run.gear.backup == 1, "equipment transfer frees occupied slot to inventory")
	expect(run.equip("backup", -1) and run.gear.backup == -1, "unequip retains owned item")
	expect(run.save(), "valid final preparation can be saved")

func _legacy_migration() -> void:
	for supply in [false, true]:
		var run = _fresh("legacy-" + str(supply))
		run.unlocked = supply
		run.restart("lens" if supply else "")
		for stage in range(3):
			_check_v1(run)
			run.finish(true, "won")
			_check_v1(run)
			if stage < 2: run.select_reward("cover" if stage == 0 else "backup")
	var bad = _fresh("legacy-invalid").snapshot()
	bad.version = 1
	bad.battle = 1
	bad.rewards = ["pierce"]
	expect(not Model.new().restore(bad), "legacy rewards from wrong battle are rejected")
	bad.rewards = ["lens"]
	bad.gear = {}
	expect(not Model.new().restore(bad), "legacy owned equipment must have an inventory entry")

func _check_v1(run) -> void:
	var legacy: Dictionary = run.snapshot()
	legacy.version = 1
	legacy.erase("starting_supply")
	legacy.erase("claimed_rewards")
	var restored = Model.new()
	expect(restored.restore(JSON.parse_string(JSON.stringify(legacy))), "v1 stage migration " + str(run.battle) + "/" + run.phase)
	expect(restored.snapshot() == run.snapshot(), "v1 migration preserves explicit reward and supply provenance")

func _transactions() -> void:
	var run = _fresh("transaction")
	expect(run.transact(func(): return run.assign(5, 4)), "valid preparation transaction commits")
	var reader = _fresh("transaction")
	expect(reader.read_save() and reader.formation == run.formation, "new reader sees committed preparation")
	var before: Dictionary = run.snapshot()
	var bytes := FileAccess.get_file_as_string(run.path)
	expect(not run.transact(func(): return run.assign(4, 1)), "illegal fifth member fails transaction")
	expect(run.snapshot() == before and FileAccess.get_file_as_string(run.path) == bytes, "illegal transaction changes neither state nor file")
	run.finish(true, "won")
	before = run.snapshot()
	run.path = directory + "/missing/failure.json"
	expect(not run.transact(func(): return run.select_reward("training", 1)), "failed reward persistence reports failure")
	expect(run.snapshot() == before and run.phase == "reward", "failed reward persistence rolls back claim and stage")
	run.path = directory + "/transaction.json"
	expect(run.transact(func(): return run.select_reward("training", 1)), "same reward can be retried after storage recovers")
	reader.read_save()
	expect(reader.battle == 1 and reader.trainee == 1, "retry commits chosen reward exactly once")
	before = run.snapshot()
	bytes = FileAccess.get_file_as_string(run.path)
	DirAccess.make_dir_absolute(run.path + ".bak.tmp")
	expect(not run.transact(func(): return run.assign(1, 4)), "backup failure cancels deployment transaction")
	expect(run.snapshot() == before and FileAccess.get_file_as_string(run.path) == bytes, "backup failure preserves durable and in-memory state")
	DirAccess.remove_absolute(run.path + ".bak.tmp")
	expect(run.transact(func(): return run.assign(1, 4)), "deployment retry succeeds after backup destination recovers")

func _recovery() -> void:
	var run = _fresh("recover")
	run.save()
	run.transact(func(): return run.assign(5, 4))
	var previous := FileAccess.get_file_as_string(run.path + ".bak")
	_write(run.path, "{broken-json")
	var restored = _fresh("recover")
	expect(restored.read_save() and restored.recovered_backup and not restored.load_blocked, "corrupt primary recovers from validated backup")
	var expected_checkpoint = Model.new()
	expected_checkpoint.restore(JSON.parse_string(previous))
	expect(restored.snapshot() == expected_checkpoint.snapshot(), "backup recovery restores whole previous checkpoint")
	expect(restored.transact(func(): return restored.assign(4, 5)), "recovered checkpoint can commit new actions")
	expect(not restored.recovered_backup and FileAccess.get_file_as_string(run.path + ".bak") == previous, "repair preserves good backup rather than copying corruption")
	var preserved := false
	for file in DirAccess.get_files_at(directory):
		if file.begins_with("recover.json.corrupt-") and FileAccess.get_file_as_string(directory + "/" + file) == "{broken-json": preserved = true
	expect(preserved, "corrupt bytes retained for diagnosis")
	var future: Dictionary = run.snapshot()
	future.version = 900
	_write(run.path, JSON.stringify(future))
	var future_bytes := FileAccess.get_file_as_string(run.path)
	var old_reader = _fresh("recover")
	expect(not old_reader.read_save() and old_reader.load_blocked, "future primary does not silently fall back to older backup")
	expect(not old_reader.save() and FileAccess.get_file_as_string(run.path) == future_bytes, "future save is never downgraded")
	var bad = _fresh("bad")
	_write(bad.path, "bad")
	expect(not bad.read_save() and not bad.save() and bad.load_blocked, "bad save without backup is blocked")
	var stale = _fresh("changed-underfoot")
	stale.save()
	_write(stale.path, "externally damaged")
	expect(not stale.transact(func(): return stale.assign(5, 4)) and stale.load_blocked, "save rechecks existing file before replacement")
	var missing = _fresh("missing-primary")
	missing.save()
	missing.transact(func(): return missing.assign(5, 4))
	DirAccess.remove_absolute(missing.path)
	var recovery = _fresh("missing-primary")
	expect(recovery.read_save() and recovery.recovered_backup, "backup recovered when primary is missing")
	expect(recovery.save(), "missing primary can be restored durably")

func _write(target: String, text: String) -> void:
	var file := FileAccess.open(target, FileAccess.WRITE)
	file.store_string(text)
	file.close()
