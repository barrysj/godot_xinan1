extends Node
var game: Control
var panel: Control
var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run_checks")

func mouse(point: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = panel.canvas.get_global_transform() * point
	get_viewport().push_input(event, true)
	await get_tree().process_frame

func click(point: Vector2) -> void:
	await mouse(point, true)
	await mouse(point, false)

func move(point: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.position = panel.canvas.get_global_transform() * point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if panel.pressed_role >= 0 else 0
	get_viewport().push_input(event, true)
	await get_tree().process_frame

func card_point(role: int) -> Vector2:
	return panel.hand.position + panel.cards[role].position + panel.cards[role].size / 2

func slot_point(slot: int) -> Vector2:
	return game._slot_rect(0, slot).get_center()

func run_checks() -> void:
	game = load("res://scenes/expedition/expedition.tscn").instantiate()
	add_child(game)
	game._new_run()
	game.run.generate(1)
	game._enter_node()
	panel = game.deployment
	await get_tree().process_frame
	await get_tree().process_frame
	if "--deployment-dismiss-capture" in OS.get_cmdline_user_args():
		await capture_action_dismissed()
		game.queue_free()
		get_tree().quit(failures)
		return
	check(game.formation.count(-1) == 6 and game._living(0).is_empty(), "New encounter starts empty")
	game._start()
	check(game.phase == "prepare", "Empty formation cannot start")
	await move(card_point(0))
	check(panel.hover_role == 0, "Hover identifies card")
	await click(card_point(0))
	check(panel.selected_role == 0 and not panel.dragging, "Click selects and raises card")
	await move(slot_point(0))
	check(panel.ghost.visible, "Hover previews click target")
	await move(Vector2(40,170))
	check(not panel.ghost.visible, "Hover leaves board without stale ghost")
	await click(card_point(0))
	check(panel.selected_role == -1 and not panel.ghost.visible, "Second card click deselects")
	await click(card_point(0))
	await click(slot_point(1))
	check(panel.selected_role == -1 and game.formation[1] == 0 and game._living(0).size() == 1, "Card then cell deploys immediately and clears selection")
	var restored = game.Checkpoint.decode(game.progress.active_run)
	check(not restored.is_empty() and restored.run.formation == game.formation, "Partial deployment checkpoint restores")
	game._to_base()
	game.progress.read_save()
	game._continue_run()
	await get_tree().process_frame
	check(game.phase == "prepare" and game.formation[1] == 0 and game._living(0).size() == 1, "Disk reload keeps confirmed deployment")
	await click(card_point(2))
	await move(slot_point(4))
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	get_viewport().push_input(escape, true)
	await get_tree().process_frame
	check(panel.selected_role == -1 and not game.paused and game.formation.count(-1) == 5, "Escape cancels preview before opening pause")
	await mouse(card_point(1), true)
	await move(slot_point(3))
	check(panel.dragging and panel.ghost.visible, "Drag shows target preview")
	await mouse(slot_point(3), false)
	check(game.formation[3] == 1 and panel.selected_role == -1, "Valid drop commits immediately")
	await check_deployed_actions()
	var before: Array = game.formation.duplicate()
	await mouse(card_point(2), true)
	await move(slot_point(1))
	check(panel.ghost.visible and panel.previews_unit(0), "Reserve card previews replacement on occupied cell")
	await mouse(slot_point(1), false)
	check(game.formation[1] == 2 and not game.formation.has(0), "Reserve card drop replaces deployed ally")
	await mouse(card_point(0), true)
	await move(slot_point(1))
	await mouse(slot_point(1), false)
	check(game.formation == before, "Card drop can restore replaced ally")
	await click(card_point(2))
	await click(slot_point(1))
	check(game.formation[1] == 2 and not game.formation.has(0), "Reserve card click replaces deployed ally immediately")
	await click(card_point(0))
	await click(slot_point(1))
	check(game.formation == before, "Click replacement remains reversible through cards")
	await click(card_point(0))
	await click(slot_point(3))
	check(panel.selected_role == -1 and game.formation[1] == 1 and game.formation[3] == 0, "Deployed card click swaps occupied cells immediately and clears selection")
	await click(card_point(0))
	await click(slot_point(1))
	check(game.formation == before, "Direct card swap can restore formation")
	await mouse(card_point(2), true)
	await move(Vector2(45, 170))
	await mouse(Vector2(45, 170), false)
	check(game.formation == before and panel.selected_role == -1, "Outside drop cancels")
	await mouse(card_point(2), true)
	await move(slot_point(4))
	panel._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await mouse(slot_point(4), false)
	check(game.formation == before, "Focus loss cancels drag without deployment")
	await mouse(card_point(2), true)
	await move(card_point(2) + Vector2(3, 2))
	await mouse(card_point(2) + Vector2(3, 2), false)
	check(not panel.dragging and panel.selected_role == 2, "Small hand movement stays click mode")
	await move(slot_point(4))
	check(panel.ghost.visible and game.formation == before, "Hover remains temporary before click")
	game._open_pause()
	check(panel.selected_role == -1 and game.formation == before, "Pause discards unconfirmed preview")
	game._resume_battle()
	await click(card_point(0))
	await click(slot_point(0))
	check(game.formation[0] == 0 and game.formation[1] == -1, "Click reposition commits immediately and clears original exactly once")
	await click(slot_point(0))
	await click(panel.withdraw_button.position + Vector2(32,15))
	check(not game.formation.has(0), "Withdraw returns card to undeployed")
	for item in [[0,1],[2,4],[3,2]]:
		panel.select(item[0])
		panel.candidate_slot = item[1]
		panel.commit()
	game.run.roster.append(4)
	panel.refresh()
	panel.select(4)
	check(not panel.can_place(0) and panel.can_place(1), "Fifth character can replace an ally but cannot fill a fifth slot")
	panel.cancel()
	game._start()
	check(game.phase == "battle" and game._living(0).size() == 4, "Four deployed units enter combat")
	var count = 0
	while game.screen == "battle" and count < 1800:
		game._process(0.05)
		count += 1
	check(game.screen == "report" and game.result_won, "Deployed party completes real encounter")
	check(not game.Checkpoint.decode(game.progress.active_run).is_empty(), "Battle report remains restorable")
	game._after_report()
	game._choose_reward(0)
	for index in range(game.run.stages[game.run.stage].size()):
		if game.run.stages[game.run.stage][index].kind != "event":
			game.chosen_node = index
			break
	game._enter_node()
	check(game.formation.count(-1) == 2 and game._living(0).size() == 4 and game.run.formation == game.formation,
		"Next encounter reuses confirmed deployment")
	print("DEPLOYMENT_CHECK ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	if "--deployment-capture" in OS.get_cmdline_user_args() and failures == 0:
		await capture()
	game.queue_free()
	get_tree().quit(failures)

func check_deployed_actions() -> void:
	var original: Array = game.formation.duplicate()
	await click(slot_point(1))
	check(panel.swap_button.visible and panel.withdraw_button.visible and not panel.ghost.visible, "Deployed unit opens action menu only")
	await click(Vector2(40,170))
	check(panel.selected_role == -1 and not panel.swap_button.visible and not panel.withdraw_button.visible and game.formation == original,
		"Clicking empty battlefield dismisses the action menu without changing formation")
	await click(slot_point(1))
	await move(slot_point(0))
	await click(slot_point(0))
	check(panel.selected_role == -1 and not panel.swap_button.visible and not panel.withdraw_button.visible and game.formation == original,
		"Clicking an empty friendly cell dismisses the action menu")
	await click(slot_point(1))
	await click(panel.swap_button.position + Vector2(32,15))
	check(panel.is_swap_source(game.formation[1]), "Swap mode exposes the selected source for its highlight")
	await click(slot_point(1))
	check(game.formation == original and panel.selected_role == -1, "Choosing the source cell cancels swap")
	await click(slot_point(1))
	await click(panel.swap_button.position + Vector2(32,15))
	await mouse(slot_point(1), true, MOUSE_BUTTON_RIGHT)
	await mouse(slot_point(1), false, MOUSE_BUTTON_RIGHT)
	check(game.formation == original and panel.selected_role == -1, "Right click cancels swap")
	await click(slot_point(1))
	await click(panel.swap_button.position + Vector2(32,15))
	await move(slot_point(3))
	check(panel.ghost.visible and panel.swap_ghost.visible, "Swap hover previews both destinations")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	check(panel.handle(escape), "Swap selection consumes Escape")
	await get_tree().process_frame
	check(game.formation == original and panel.selected_role == -1, "Escape cancels swap before choosing a target")
	await click(slot_point(1))
	await click(panel.swap_button.position + Vector2(32,15))
	await click(slot_point(3))
	check(panel.selected_role == -1 and game.formation[1] == 1 and game.formation[3] == 0, "Click swap exchanges occupied cells immediately, atomically, and clears selection")
	var restored = game.Checkpoint.decode(game.progress.active_run)
	check(not restored.is_empty() and restored.run.formation == game.formation, "Swapped formation persists")
	await mouse(slot_point(3), true)
	await move(slot_point(1))
	check(panel.dragging and panel.swap_ghost.visible, "Dragging deployed unit skips action selection")
	await mouse(slot_point(1), false)
	check(game.formation == original, "Drag swap commits without confirmation")
	await mouse(slot_point(1), true)
	await move(Vector2(40,170))
	await mouse(Vector2(40,170), false)
	check(game.formation == original, "Outside deployed drag cancels rather than withdraws")
	await mouse(slot_point(1), true)
	await move(slot_point(2))
	await mouse(slot_point(2), false)
	check(game.formation[2] == 0 and game.formation[1] == -1, "Deployed drag to empty cell moves")
	await mouse(slot_point(2), true)
	await move(card_point(0))
	check(panel.return_hint.visible, "Drag back shows withdraw hint")
	await mouse(card_point(0), false)
	check(not game.formation.has(0), "Drop in card area withdraws")
	panel.select(0)
	panel.candidate_slot = 1
	panel.commit()
	check(game.formation == original, "Withdrawn card can redeploy")
	await click(card_point(0))
	await mouse(card_point(0), true)
	await move(slot_point(2))
	await mouse(slot_point(2), false)
	check(game.formation[2] == 0, "Dragging selected card overrides second-click cancellation")
	var portrait_point: Vector2 = game._unit_center(game._inspection_unit(0)) + Vector2(0,-28)
	await mouse(portrait_point, true)
	await move(slot_point(1))
	await mouse(slot_point(1), false)
	check(game.formation == original, "Dragging visible portrait above cell hitbox works")
	await mouse(slot_point(1), true)
	await move(slot_point(1) + Vector2(12,0))
	await mouse(slot_point(1), false)
	check(game.formation == original and panel.selected_role == -1, "Drop on original cell is a safe no-op")

func capture() -> void:
	for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution
		game.formation = [-1,-1,-1,-1,-1,-1]
		game._build_units()
		panel.cancel()
		await get_tree().process_frame
		await get_tree().process_frame
		await screenshot("empty", resolution)
		await click(card_point(0))
		await move(slot_point(1))
		await screenshot("click-hover", resolution)
		await click(slot_point(1))
		await get_tree().create_timer(0.2).timeout
		await screenshot("click-deployed", resolution)
		panel.cancel()
		await mouse(card_point(1), true)
		await move(slot_point(4))
		await screenshot("drag", resolution)
		await mouse(slot_point(4), false)
		await screenshot("deployed", resolution)
		await click(slot_point(4))
		await screenshot("actions", resolution)
		await click(Vector2(40,170))
		await screenshot("actions-dismissed", resolution)
		await click(slot_point(4))
		await click(panel.swap_button.position + Vector2(32,15))
		await screenshot("swap-selected", resolution)
		await click(slot_point(4))
		panel.select(0)
		panel.candidate_slot = 1
		panel.commit()
		await click(card_point(0))
		await click(slot_point(4))
		panel.cancel()
		await screenshot("card-swap-committed", resolution)

func capture_action_dismissed() -> void:
	for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution
		game.formation = [-1,0,-1,-1,1,-1]
		game._build_units()
		panel.cancel()
		game.inspector.close_info()
		await get_tree().process_frame
		panel.select(1)
		await screenshot("actions", resolution)
		panel.cancel()
		game.inspector.close_info()
		await screenshot("actions-dismissed", resolution)

func screenshot(stage: String, resolution: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var picture = get_viewport().get_texture().get_image()
	check(picture.get_size() == resolution, "Screenshot resolution")
	picture.save_png("res://.godot/deployment-%s-%dx%d.png" % [stage, resolution.x, resolution.y])
	print("DEPLOYMENT_CAPTURE ", stage, " ", resolution)
