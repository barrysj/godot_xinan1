extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func click(game, logical: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = game.origin + logical * game.scale_factor
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		get_viewport().push_input(event,true)
func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var size := get_window().size
	get_viewport().get_texture().get_image().save_png("res://.godot/playback-%s-%dx%d.png" % [name,size.x,size.y])
func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/playback-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game.storage_ready = false
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game._start()
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		click(game,game._action_rect(0).get_center())
		verify(game.paused and not game.pause_overlay.visible, "Battle pause button only freezes playback")
		game.code_panel._update_hud()
		verify(game.code_panel.summary.text == "已暂停","Bottom playback status reports manual pause")
		verify(game.code_panel.dock.get_global_rect().encloses(game.code_panel.clock.get_global_rect()),"Clock stays inside bottom dock")
		var before: float = game.elapsed
		game._process(1)
		verify(game.elapsed == before,"Manual pause freezes simulation time")
		click(game,game.BATTLE_MENU_RECT.get_center())
		verify(game.pause_overlay.visible and game.paused,"Separate menu remains accessible while manually paused")
		game._request_exit("menu")
		game._open_pause()
		game._resume_battle()
		verify(game.paused and not game.pause_overlay.visible,"Cancel exit and close menu preserve manual pause")
		await capture("paused")
		click(game,game._action_rect(0).get_center())
		verify(not game.paused and not game.pause_overlay.visible,"Battle button resumes without menu")
		game.code_panel._update_hud()
		verify(game.code_panel.summary.text == "进行中","Bottom playback status returns to running")
		key(KEY_P)
		verify(game.paused and not game.pause_overlay.visible,"P toggles manual pause")
		key(KEY_ESCAPE)
		verify(game.pause_overlay.visible,"Esc opens the menu from manual pause")
		key(KEY_ESCAPE)
		verify(game.paused and not game.pause_overlay.visible,"Esc closes menu without resuming manual pause")
		key(KEY_P)
		verify(not game.paused,"P resumes manual pause")
		click(game,game.BATTLE_MENU_RECT.get_center())
		game._resume_battle()
		verify(not game.paused,"Menu opened during running playback resumes running playback")
		game.speed = 1.0
		for expected in [1.5,2.0,2.0]:
			click(game,game._action_rect(1).get_center())
			verify(is_equal_approx(game.speed,expected),"Increase speed clamps at maximum " + str(expected))
		for expected in [1.5,1.0,0.5,0.5]:
			var down: Control = game.code_panel.speed_down
			click(game,(down.get_global_rect().get_center()-game.origin)/game.scale_factor)
			verify(is_equal_approx(game.speed,expected),"Decrease speed clamps at minimum " + str(expected))
		verify(is_equal_approx(game.code_panel.speed_control.size.x,game.code_panel.pause_control.size.x),"Speed group matches pause width")

		game.speed = 0.5
		before = game.elapsed
		game._process(1)
		verify(absf(game.elapsed-before-0.5) < 0.051,"Half speed advances half a simulation second")
		await capture("half-speed")
	game._toggle_manual_pause()
	game._open_pause()
	game._return_to_formation()
	verify(game.phase == "prepare" and not game.paused,"Reformation clears manual pause")
	game._start()
	game._toggle_manual_pause()
	game._open_pause()
	game._to_base()
	verify(game.screen == "base" and not game.paused, "Returning home clears battle-only manual pause")
	game.campaign_enabled = false
	game._new_run()
	for rate in game.PLAYBACK_SPEEDS:
		game.speed = rate
		var checkpoint = preload("res://game/run/run_checkpoint.gd").decode(game._pack_checkpoint())
		verify(not checkpoint.is_empty() and is_equal_approx(checkpoint.speed,rate), "Legacy run checkpoint preserves " + str(rate))
	print("PLAYBACK_CONTROLS_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
