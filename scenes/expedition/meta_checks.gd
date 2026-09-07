extends RefCounted
const Profile = preload("res://game/meta/campus_progress.gd")
const Checkpoint = preload("res://game/run/run_checkpoint.gd")
var failures = 0
var checks = 0

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("META_CHECK_FAILED: " + label)

func reload_profile(source):
	var loaded = Profile.new()
	loaded.path = source.path
	verify(loaded.read_save(), "profile reload")
	return loaded

func run_checks(hub) -> void:
	var p = Profile.new()
	p.path = "res://.godot/meta-unit-tests.json"
	var file = FileAccess.open(p.path,FileAccess.WRITE)
	file.store_string('{"version":1,"points":30,"completions":2,"supply_unlocked":true}')
	file.close()
	verify(p.read_save() and p.points == 30 and p.level("supply") == 1, "v1 migration")
	verify(not p.purchase("supply") and p.points == 30, "duplicate unlock")
	verify(not p.purchase("gym"), "unlock dependency")
	verify(p.purchase("dispatch") and p.points == 27, "dispatch unlock")
	verify(p.start_dispatch("archivist","library",1000) and p.points == 25, "dispatch deduction")
	var id = p.dispatches[0].id
	verify(not p.start_dispatch("archivist","library",1000), "busy staff")
	verify(not p.start_dispatch("liaison","library",1000), "parallel limit")
	verify(not p.claim_dispatch(id,1059) and p.points == 25, "early claim")
	p = reload_profile(p)
	verify(p.busy("archivist") and p.claim_dispatch(id,1060) and p.points == 29, "offline completion")
	verify(not p.claim_dispatch(id,1061) and p.points == 29 and not p.busy("archivist"), "claim once and free staff")
	verify(p.purchase("gym") and p.purchase("staffing") and p.available_staff().size() == 3, "unlock location and staff")
	verify(p.start_dispatch("archivist","library",2000) and p.start_dispatch("liaison","gym",2000), "two simultaneous jobs")
	var before = p.to_dict()
	var old_path = p.path
	p.path = "res://.godot/nonexistent-meta-folder/profile.json"
	verify(not p.purchase("fitness") and p.to_dict() == before, "upgrade save failure rollback")
	verify(not p.claim_dispatch(p.dispatches[0].id,3000) and p.to_dict() == before, "claim save failure rollback")
	p.path = old_path
	verify(p.claim_dispatch(p.dispatches[0].id,3000), "claim retry")
	before = p.to_dict()
	p.path = "res://.godot/nonexistent-meta-folder/profile.json"
	verify(not p.start_dispatch("archivist","library",3000) and p.to_dict() == before, "dispatch save failure rollback")
	p.path = "res://.godot/meta-corrupt-test.json"
	file = FileAccess.open(p.path,FileAccess.WRITE)
	file.store_string("broken-save")
	file.close()
	verify(not p.read_save() and p.load_blocked and not p.write_save(), "corrupt profile protected")
	verify(FileAccess.get_file_as_string(p.path) == "broken-save", "corrupt bytes preserved")
	p = Profile.new()
	p.path = "res://.godot/meta-upgrades-test.json"
	verify(not p.purchase("fitness") and p.level("fitness") == 0, "insufficient resources")
	p.points = 30
	verify(p.purchase("fitness") and p.purchase("fitness") and p.purchase("fitness") and p.points == 12, "tiered upgrade costs")
	verify(not p.purchase("fitness") and p.points == 12 and p.level("fitness") == 3, "max upgrade level")
	p = Profile.new()
	p.path = "res://.godot/meta-scene-test.json"
	p.points = 40
	hub.progress = p
	hub._new_run()
	var original_id = hub.run.run_id
	verify(not Checkpoint.decode(p.active_run).is_empty(), "map checkpoint")
	verify(p.purchase("fitness") and hub.run.permanent_hp == 0, "mid-run upgrade deferred")
	hub._to_base()
	hub.progress = reload_profile(p)
	hub._test_click(Vector2(460,415))
	verify(hub.screen == "map" and hub.run.run_id == original_id and hub.run.permanent_hp == 0, "continue real button")
	hub._enter_node()
	hub.formation = [-1,0,3,1,2,-1]
	hub.equipment = 1
	hub._sync_team()
	hub._start()
	hub._process(1.0)
	hub._to_base()
	hub.progress = reload_profile(hub.progress)
	hub._continue_run()
	verify(hub.screen == "battle" and hub.phase == "prepare" and hub.elapsed == 0 and hub.formation == [-1,0,3,1,2,-1] and hub.equipment == 1, "interrupted battle restores formation")
	for unit in hub.units:
		if unit.side == 0: verify(unit.hp == unit.max_hp, "restored HP")
	hub._start()
	for unit in hub.units:
		if unit.side == 0: unit.hp = 1
		else: unit.atk = 9999; unit.timer = 0
	fight_to_end(hub)
	verify(not hub.result_won, "forced defeat")
	hub.progress = reload_profile(hub.progress)
	hub._continue_run()
	verify(hub.screen == "report" and not hub.result_won and hub.report.size() == 4, "defeat report persists")
	hub._after_report()
	verify(hub.run.retries == 1 and hub.phase == "prepare", "unlimited retry preserves counter")
	hub._start()
	fight_to_end(hub)
	verify(hub.result_won, "retry win")
	hub.progress = reload_profile(hub.progress)
	hub._continue_run()
	verify(hub.screen == "report" and hub.result_won, "victory report persists")
	hub._after_report()
	hub.progress = reload_profile(hub.progress)
	hub._continue_run()
	verify(hub.screen == "reward", "reward choice persists")
	hub._choose_reward(1)
	hub._choose_reward(1)
	hub.progress = reload_profile(hub.progress)
	hub._continue_run()
	verify(hub.run.stage == 1 and hub.run.training.get(1,0) == 1, "JSON training keys and single reward")
	hub._enter_node()
	hub.progress = reload_profile(hub.progress)
	hub._continue_run()
	verify(hub.screen == "event", "event persists")
	hub._test_click(Vector2(450,460))
	verify(hub.screen == "reward" and hub.progress.active_run.screen == "reward", "event reward click saves")
	hub._choose_reward(0)
	while hub.run.stage < 5:
		hub.chosen_node = 0
		hub._enter_node()
		if hub.screen == "battle":
			hub._start()
			fight_to_end(hub)
			verify(hub.result_won, "full route victory")
			if not hub.result_won: break
			hub._after_report()
		else: hub.screen = "reward"
		if hub.screen == "reward": hub._choose_reward(1)
	verify(hub.screen == "summary" and hub.run.settled and hub.run.points == 7, "complete and settle")
	var settled_points = hub.progress.points
	hub.progress = reload_profile(hub.progress)
	hub._continue_run()
	hub._settle()
	verify(hub.progress.points == settled_points and hub.progress.completions == 1, "reload settlement no duplicate")
	verify(hub.progress.finish_run(hub._pack_checkpoint(),7) and hub.progress.points == settled_points, "service settlement idempotent")
	var failed_profile = Profile.new()
	failed_profile.path = "res://.godot/nonexistent-meta-folder/profile.json"
	verify(not failed_profile.finish_run(hub._pack_checkpoint(),7) and failed_profile.points == 0 and failed_profile.completions == 0 and failed_profile.active_run.is_empty(), "settlement failure rollback")
	var malformed = hub._pack_checkpoint()
	malformed.run.stage = {}
	verify(Checkpoint.decode(malformed).is_empty(), "malformed run rejected")
	malformed = hub._pack_checkpoint()
	malformed.seconds = []
	verify(Checkpoint.decode(malformed).is_empty(), "malformed checkpoint rejected")
	hub._new_run()
	verify(hub.run.permanent_hp == 20 and hub.run.run_id != original_id, "new run applies permanent upgrade")
	hub._to_base()
	hub._test_click(Vector2(1080,345))
	verify(hub.screen == "growth", "growth entry")
	hub._test_click(Vector2(1100,657))
	hub._test_click(Vector2(1080,420))
	verify(hub.screen == "dispatch", "dispatch entry")
	print("META_SMOKE checks=",checks," failures=",failures)
	hub.get_tree().quit(0 if failures == 0 else 1)

func fight_to_end(hub) -> void:
	for frame in range(10000):
		if hub.screen != "battle": return
		hub._process(1.0 / 30.0)
	verify(false,"battle timeout")
