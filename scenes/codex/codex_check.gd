extends Node
func _ready() -> void:
	await get_tree().process_frame
	var menu = get_tree().current_scene
	menu.codex_button.pressed.emit()
	var guide = menu.codex_panel
	var count = 0
	for category in range(5):
		guide.tabs[category].pressed.emit()
		for index in range(guide.listing.get_child_count()):
			guide.listing.get_child(index).pressed.emit()
			assert(not guide.heading.text.is_empty() and not guide.detail.text.is_empty())
			count += 1
	guide.select_category(2)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/codex_items.png")
	guide.exit_button.pressed.emit()
	await get_tree().process_frame
	assert(not is_instance_valid(menu.codex_panel))
	menu._on_PlayButton_pressed()
	await GGT.scene_transition_finished
	var game = get_tree().current_scene
	game._new_run()
	game._enter_node()
	game._start()
	game._process(0.5)
	game._open_pause()
	for button in game.pause_actions.get_children():
		if button.text == "图鉴": button.pressed.emit()
	assert(is_instance_valid(game.codex_panel))
	var snapshot = [game.elapsed,game.units.duplicate(true),game.run.to_dict()]
	game._process(5.0)
	assert(snapshot == [game.elapsed,game.units,game.run.to_dict()])
	game.codex_panel.select_category(0)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/codex_people.png")
	var escape = InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	Input.parse_input_event(escape)
	await get_tree().process_frame
	assert(not is_instance_valid(game.codex_panel) and game.paused and game.pause_overlay.visible)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/codex_pause.png")
	game._resume_battle()
	game._process(0.1)
	assert(game.elapsed > snapshot[0])
	print("CODEX_CHECK entries=",count," menu/pause entry, category selection, close/Esc, frozen battle and resume passed")
	get_tree().quit()
