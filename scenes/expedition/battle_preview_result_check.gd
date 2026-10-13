extends RefCounted
## Exercise actual preview victory/defeat, its two buttons, retry rollback and quit.
const Model = preload("res://game/debug/battle_tuning.gd")
const Helpers = preload("res://scenes/expedition/battle_tuning_check.gd")
const Commands = preload("res://game/debug/campus_debug.gd")
var checks := 0
var failures := 0
var hub
var helpers = Helpers.new()

func verify(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("PREVIEW_RESULT_CHECK: "+label)

func frames() -> void:
	await hub.get_tree().process_frame
	await hub.get_tree().process_frame

func click_at(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = hub.origin+at*hub.scale_factor
	event.pressed = true
	hub.get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	hub.get_viewport().push_input(event,true)
	await frames()

func visible_buttons() -> Array:
	return hub.find_children("*","Button",true,false).filter(func(button): return button.is_visible_in_tree()).map(func(button): return button.text)

func stats() -> Array:
	return hub.units.map(func(unit): return [unit.side,unit.slot,unit.content_id,Model.stats(unit)])

func finish_fight(expected_win: bool) -> void:
	for index in 2400:
		if hub.screen == "report": break
		hub._process(0.05)
	await frames()
	verify(hub.screen == "report" and hub.result_won == expected_win,"natural simulation ends in expected preview result")
	verify(visible_buttons() == ["退出游戏","重新战斗"],"result exposes exactly the two requested actions")
	verify(not hub.campaign_panel.visible and not hub.debug_panel.entry.visible and not hub.pause_overlay.visible,"no campaign, debug or pause menu covers result")
	verify(not hub.journey.visit.data.guard_won and not hub.journey.data.has("offers") and not hub.run.reward_taken,"preview never consumes guard or creates rewards")
	verify(not hub.battle_actor_layer.visible and not hub.code_panel.visible,"original battlefield presentation clears on report")

func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or "--preview-result-capture" not in OS.get_cmdline_user_args(): return
	await frames()
	await RenderingServer.frame_post_draw
	verify(hub.get_viewport().get_texture().get_image().save_png("res://.godot/"+filename+".png") == OK,"actual preview result capture saved")

func run_checks(owner_hub) -> void:
	hub = owner_hub
	hub.set_process(false)
	var profiles := ["user://campus_progress.json","user://campus_debug_progress.json"]
	var originals: Array = profiles.map(func(path): return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())
	if not hub.debug_battle_preview:
		verify(not is_instance_valid(hub.battle_preview_results),"normal campus has no preview result controls")
		verify(hub.screen == "base","normal campus still starts at its original base")
		finish()
		return
	await frames()
	var formation: Array = hub.formation.duplicate()
	var build: Dictionary = hub.run.to_dict().duplicate(true)
	var settings: Dictionary = Model.snapshot(hub)
	settings.enabled = true
	settings.background = "lab"
	for row in settings.enemies:
		row.id = "radio" if row.slot == 4 else ""
		row.stats = Model.default_stats(hub,row.id)
	settings.enemies[4].stats.max_hp = 25
	settings.enemies[4].stats.atk = 1
	verify(Model.apply(hub,settings,true) == "","prepare a configured trial through original modifier")
	var initial_stats := stats()
	await click_at(hub._action_rect(0).get_center())
	verify(hub.phase == "battle","actual Start begins the trial")
	await finish_fight(true)
	verify(hub.report.size() == 4 and hub.report.any(func(row): return row.damage > 0),"ordinary report retains actual contributions")
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		if DisplayServer.get_name() != "headless": hub.get_window().size = resolution
		await frames()
		var result_ui = hub.battle_preview_results
		verify(hub.get_viewport_rect().encloses(result_ui.retry_button.get_global_rect()) and hub.get_viewport_rect().encloses(result_ui.quit_button.get_global_rect()),"two result actions fit viewport")
		await capture("battle-preview-victory-%dx%d" % [resolution.x,resolution.y])
	# The former reward/menu hitboxes and F8/Esc cannot escape the result screen.
	await click_at(Vector2(640,620))
	await click_at(Vector2(1187,53))
	for code in [KEY_F8,KEY_ESCAPE,KEY_P]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = true
		hub.get_viewport().push_input(event,true)
		await frames()
	verify(hub.screen == "report" and visible_buttons() == ["退出游戏","重新战斗"] and not hub.debug_panel.panel.visible and not hub.pause_overlay.visible,"old hitboxes and shortcuts cannot open rewards/map/menu")
	hub.debug_panel.open()
	verify(not hub.debug_panel.panel.visible,"direct debug open respects terminal preview")
	verify(not Commands.reason(hub,"difficulty").is_empty() and not Commands.reason(hub,"skip").is_empty(),"finished preview offers only restart developer transition")
	var previous_report_details: Dictionary = hub.report_details.duplicate(true)
	var save_path: String = hub.progress.path
	hub.progress.path = "res://.godot/missing-preview-result-directory/profile.json"
	await helpers.click(hub,hub.battle_preview_results.retry_button)
	verify(hub.screen == "report" and visible_buttons() == ["退出游戏","重新战斗"] and hub.battle_preview_results.error_label.visible,"failed retry keeps two-action report and readable error")
	verify(hub.debug_battle_tuning == settings and Model.active(hub),"failed retry preserves configured battle scope")
	verify(hub.report_details == previous_report_details and hub.report_view.snapshot == previous_report_details,"failed retry preserves visible and stored detailed statistics")
	hub.progress.path = save_path
	await helpers.click(hub,hub.battle_preview_results.retry_button)
	verify(hub.screen == "battle" and hub.phase == "prepare" and hub.elapsed == 0 and not hub.battle_preview_results.visible,"actual retry returns to preparation without auto-start")
	verify(stats() == initial_stats and hub.debug_battle_tuning == settings and hub.battle_background == load(Model.BACKGROUNDS.lab.path),"retry retains enemies, final values and background")
	verify(hub.formation == formation and hub.run.to_dict() == build and hub.units.all(func(unit): return unit.hp == unit.max_hp and unit.damage == 0),"retry retains build/formation and resets health/statistics")
	# A real overwhelming trial covers the defeat path without injecting a result.
	settings = Model.snapshot(hub)
	settings.enemies[4].stats.max_hp = 50000
	settings.enemies[4].stats.atk = 10000
	settings.enemies[4].stats.attack_range = 6
	settings.enemies[4].stats.interval = 0.1
	verify(Model.apply(hub,settings,true) == "","configure a defeat trial through original modifier")
	await click_at(hub._action_rect(0).get_center())
	await finish_fight(false)
	await capture("battle-preview-defeat")
	await helpers.click(hub,hub.battle_preview_results.retry_button)
	verify(hub.phase == "prepare" and hub.debug_battle_tuning == settings,"defeat also restarts into the same preparation")
	verify(Commands.execute(hub,"skip"),"existing Debug skip remains usable before result")
	await frames()
	verify(hub.screen == "report" and visible_buttons() == ["退出游戏","重新战斗"] and not hub.journey.data.has("offers"),"Debug skip also reaches preview report instead of rewards")
	for index in profiles.size():
		var current: PackedByteArray = FileAccess.get_file_as_bytes(profiles[index]) if FileAccess.file_exists(profiles[index]) else PackedByteArray()
		verify(current == originals[index],"player profile bytes unchanged")
	# Click the real quit action last; inspect its synchronous original quit path.
	await frames()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = hub.battle_preview_results.quit_button.get_global_rect().get_center()
	event.pressed = true
	hub.get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	hub.get_viewport().push_input(event,true)
	verify(hub.leaving and hub.pending_exit == "quit","actual exit button uses original quit route")
	finish()

func finish() -> void:
	print("PREVIEW_RESULT_CHECK %d checks / %d failures" % [checks,failures])
	hub.get_tree().quit(1 if failures else 0)
