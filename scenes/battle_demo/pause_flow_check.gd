extends Node
## Integration check: survives scene replacement to inspect the real menu flow.

func _ready() -> void:
	await get_tree().process_frame
	var battle = get_tree().current_scene
	battle._start()
	battle._open_pause()
	# Exercise the window-close event and cancel, without closing the test host.
	battle._notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert(battle.pending_exit == "quit" and battle.paused)
	battle._open_pause()
	battle._request_exit("menu")
	battle._confirm_exit()
	await GGT.scene_transition_finished
	assert(get_tree().current_scene.scene_file_path == "res://scenes/menu/menu.tscn")
	assert(not get_tree().paused and get_tree().auto_accept_quit)
	get_tree().current_scene._on_PlayButton_pressed()
	await GGT.scene_transition_finished
	battle = get_tree().current_scene
	assert(battle.scene_file_path == "res://scenes/expedition/expedition.tscn")
	assert(not battle.paused and not battle.pause_overlay.visible)
	assert(not get_tree().auto_accept_quit)
	battle._new_run()
	battle._enter_node()
	battle._start()
	battle._process(0.5)
	assert(battle.elapsed > 0)
	print("PAUSE_FLOW window-close/cancel, main menu, Play/reentry passed; quitting through exit action")
	battle._request_exit("quit")
	battle._confirm_exit()
