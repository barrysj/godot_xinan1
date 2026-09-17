extends RefCounted
const Commands = preload("res://game/debug/campus_debug.gd")
var checks = 0
var failures = 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DEBUG_CHECK: " + label)

func capture(hub, filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await hub.get_tree().process_frame
	await hub.get_tree().process_frame
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/" + filename + ".png")

func run_checks(hub) -> void:
	hub.set_process(false)
	var normal_path: String = hub.ProgressModel.new().path
	var original = FileAccess.get_file_as_bytes(normal_path) if FileAccess.file_exists(normal_path) else PackedByteArray()
	verify(hub.progress.path == "res://.godot/debug-check-profile.json","check profile isolated before load")
	var enabled: bool = hub.debug_enabled
	hub.debug_enabled = false
	for command in ["skip","restart","reroll"]:
		verify(not Commands.execute(hub,command),"normal mode rejects " + command)
	hub.debug_enabled = enabled
	if not enabled:
		verify(not is_instance_valid(hub.debug_panel),"normal mode has no debug panel")
		finish(hub)
		return
	hub.progress = hub.ProgressModel.new()
	hub.progress.path = "res://.godot/debug-check-profile.json"
	hub.progress.complete_prologue()
	hub.progress.complete_tutorial_dispatch()
	hub._home()
	verify(not Commands.execute(hub,"skip"),"home cannot skip unrelated progress")
	hub._begin_region("library")
	hub._campaign_action("enter:0")
	var old_memory: String = hub.journey.visit.data.hotspots[1].id
	verify(Commands.execute(hub,"reroll"),"reroll unopened M1 memory")
	verify(hub.journey.visit.data.hotspots[1].id != old_memory,"memory candidate actually changes")
	var snapshot = hub.progress.active_run.duplicate(true)
	hub._continue_run()
	verify(hub.progress.active_run == snapshot,"new memory persists on continue")
	hub._guard()
	hub.formation = [0,-1,3,2,1,-1]
	hub._build_units()
	hub._start()
	hub._process(1.5)
	verify(hub.elapsed > 0,"real simulation advanced")
	await capture(hub,"debug-battle")
	if DisplayServer.get_name() != "headless":
		hub.get_window().mode = Window.MODE_WINDOWED
		await hub.get_tree().process_frame
		for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
			hub.get_window().size = resolution
			hub.queue_redraw()
			await capture(hub,"debug-corner-%dx%d" % [resolution.x,resolution.y])
			var rect: Rect2 = hub.debug_panel.entry.get_global_rect()
			var menu = Rect2(hub.origin+Vector2(1148,28)*hub.scale_factor,Vector2(78,36)*hub.scale_factor)
			verify(not rect.intersects(menu),"corner entry does not cover menu")
			verify(rect.position.y <= 8 and absf(rect.end.x-hub.size.x+12) < 1,"entry stays in top right corner")
			verify(hub.get_viewport().get_texture().get_image().get_size() == resolution,"actual capture resolution")
		var click = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = hub.debug_panel.entry.get_global_rect().get_center()
		click.pressed = true
		hub.get_viewport().push_input(click,true)
		click = click.duplicate()
		click.pressed = false
		hub.get_viewport().push_input(click,true)
		verify(hub.debug_panel.panel.visible and hub.paused,"actual corner button click opens modal")
		hub.debug_panel.close()
	var build = hub.run.to_dict()
	var formation = hub.formation.duplicate()
	hub.debug_panel.open()
	var elapsed: float = hub.elapsed
	hub._process(1.0)
	verify(hub.elapsed == elapsed and hub.paused,"debug modal freezes simulation")
	await capture(hub,"debug-battle-panel")
	if DisplayServer.get_name() != "headless":
		var popup: Rect2 = hub.debug_panel.panel.get_global_rect()
		verify(popup.size.x < hub.size.x and popup.size.y < hub.size.y and popup.position.x > 0 and popup.position.y > 0,"popup leaves current scene visible around all edges")
		var outside = InputEventMouseButton.new()
		outside.button_index = MOUSE_BUTTON_LEFT
		outside.position = hub.origin+Vector2(1187,46)*hub.scale_factor
		outside.pressed = true
		hub.get_viewport().push_input(outside,true)
		outside = outside.duplicate()
		outside.pressed = false
		hub.get_viewport().push_input(outside,true)
		verify(not hub.debug_panel.panel.visible and not hub.debug_panel.backdrop.visible and not hub.paused,"backdrop closes popup without clicking underlying menu")
		hub.debug_panel.open()
	hub.debug_panel._action("restart")
	verify(hub.screen == "battle" and hub.phase == "prepare" and hub.elapsed == 0,"UI restart resets battle to deployment")
	verify(hub.formation == formation and hub.run.to_dict() == build,"restart preserves whole build")
	verify(hub.units.all(func(u): return u.hp == u.max_hp and u.damage == 0 and u.healing == 0),"restart restores HP and statistics")
	hub._open_pause()
	hub.debug_panel.open()
	hub.debug_panel.close()
	verify(hub.paused and hub.pause_overlay.visible,"closing debug preserves previous pause")
	hub._resume_battle()
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	hub.debug_panel.open()
	hub._input(escape)
	verify(not hub.paused and not hub.debug_panel.panel.visible,"Escape closes debug and resumes")
	var toggle = InputEventKey.new()
	toggle.keycode = KEY_F8
	toggle.pressed = true
	hub._input(toggle)
	verify(hub.debug_panel.panel.visible,"F8 opens debug")
	var tab = InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	verify(not hub.debug_panel.handle_input(tab),"native keyboard navigation remains available")
	hub._request_exit("quit")
	verify(not hub.debug_panel.panel.visible and hub.pending_exit == "quit" and hub.pause_overlay.visible,"window close exposes exit confirmation")
	hub._resume_battle()
	var before = hub.progress.active_run.duplicate(true)
	var valid_path: String = hub.progress.path
	hub.progress.path = "res://.godot/nonexistent-debug-directory/profile.json"
	verify(not Commands.execute(hub,"skip"),"failed skip reports failure")
	verify(hub.progress.active_run == before and not hub.journey.visit.data.guard_won,"failed skip preserves checkpoint and guard")
	hub.progress.path = valid_path
	hub._continue_run()
	hub.debug_panel.open()
	hub.debug_panel._action("skip")
	verify(hub.journey.data.screen == "reward" and hub.journey.visit.data.guard_won,"UI skip reaches normal reward")
	verify(not Commands.execute(hub,"skip") and not Commands.execute(hub,"restart"),"settled guard cannot duplicate battle reward")
	var offers = hub.journey.data.offers.duplicate(true)
	hub.progress.path = "res://.godot/nonexistent-debug-directory/profile.json"
	verify(not Commands.execute(hub,"reroll") and hub.journey.data.offers == offers,"failed reroll restores old offers")
	hub.progress.path = valid_path
	hub._continue_run()
	verify(Commands.execute(hub,"reroll"),"reroll reward")
	verify(hub.journey.data.offers.any(func(item): return not offers.any(func(old): return old.id == item.id)),"reward contains genuinely different candidate")
	snapshot = hub.progress.active_run.duplicate(true)
	hub._continue_run()
	verify(hub.progress.active_run == snapshot,"rerolled rewards persist")
	hub.debug_panel.open()
	await capture(hub,"debug-reward-panel")
	hub.debug_panel.close()
	hub._campaign_action("reward:0")
	build = hub.run.to_dict()
	hub._campaign_action("reward:0")
	verify(hub.run.to_dict() == build,"reward still single claim")
	hub._hotspot(hub.journey.visit.data.hotspots[1].id)
	hub._show_journey()
	verify(not Commands.execute(hub,"reroll"),"viewed memory cannot be reset")
	hub._campaign_action("leave")
	# All three regions and the finale still require their normal traversal/operations.
	for region in ["library","region_b","region_c"]:
		if hub.campaign_mode.is_empty() or hub.journey.data.region != region: hub._begin_region(region)
		while not hub.campaign_mode.is_empty():
			if hub.journey.visit.data.is_empty(): hub._campaign_action("enter:0")
			verify(Commands.execute(hub,"skip"),"skip region guard")
			hub._campaign_action("reward:0")
			hub._campaign_action("leave")
		verify(hub.progress.campaign.terminals.has(region),"normal terminal settlement")
	hub._begin_region("library","finale")
	for stage in range(3):
		hub._guard()
		verify(Commands.execute(hub,"skip"),"skip finale guard")
		verify(hub.journey.data.screen == "operation" and hub.progress.campaign.finale_stage == stage,"skip does not auto-submit operation")
		hub._campaign_action("operation")
	verify(hub.progress.campaign.restored,"finale normal settlement completes")
	# Compatibility: active old random runs retain real event snapshots.
	hub.campaign_mode = ""
	hub.campaign_panel.hide()
	hub.run = hub.RunModel.new()
	hub.run.generate(8)
	hub.run.choose(0)
	hub.formation = hub.run.formation.duplicate()
	hub.screen = "battle"
	hub.phase = "prepare"
	hub._build_units()
	hub._checkpoint()
	hub._start()
	hub._process(1.0)
	verify(Commands.execute(hub,"restart") and hub.elapsed == 0 and hub.phase == "prepare","legacy battle restart")
	verify(Commands.execute(hub,"skip") and hub.screen == "reward","legacy battle skip")
	verify(Commands.execute(hub,"reroll") and not hub.Checkpoint.decode(hub.progress.active_run).is_empty(),"legacy rerolled rewards restore")
	hub._choose_reward(0)
	var event_found = false
	while hub.run.stage < 4 and not event_found:
		var index = hub.run.stages[hub.run.stage].find_custom(func(node): return node.kind == "event")
		if index >= 0:
			hub.run.choose(index)
			event_found = true
		else:
			hub.run.choose(0)
			hub.run.complete_node()
	verify(event_found,"legacy event fixture exists")
	if event_found:
		hub.screen = "event"
		hub._checkpoint()
		var old_event: String = hub.run.current_event().id
		verify(Commands.execute(hub,"reroll") and hub.run.current_event().id != old_event,"legacy event changes")
		var decoded = hub.Checkpoint.decode(hub.progress.active_run)
		verify(not decoded.is_empty() and decoded.run.current_event() == hub.run.current_event(),"legacy event snapshot restores")
		var frozen = hub.run.current_event()
		hub.progress.path = "res://.godot/nonexistent-debug-directory/profile.json"
		verify(not Commands.execute(hub,"reroll") and hub.run.current_event() == frozen,"legacy failed reroll rolls back")
		hub.progress.path = valid_path
		hub.run.event_done = true
		verify(not Commands.execute(hub,"reroll"),"consumed legacy event cannot reroll")
	# Debug reset uses the same formal confirmation, against the isolated profile.
	hub._home()
	hub._campaign_action("reset_profile")
	hub._campaign_action("reset_confirm")
	verify(hub.progress.to_dict() == hub.ProgressModel.new().to_dict(),"debug restart clears only selected profile")
	var after = FileAccess.get_file_as_bytes(normal_path) if FileAccess.file_exists(normal_path) else PackedByteArray()
	verify(after == original,"normal profile bytes untouched")
	await capture(hub,"debug-home")
	finish(hub)

func finish(hub) -> void:
	print("DEBUG_CHECK %d checks / %d failures" % [checks,failures])
	hub.get_tree().quit(0 if failures == 0 else 1)
