extends Node

const MENU_SCENE := preload("res://scenes/menu/menu.tscn")

func _ready() -> void:
	var requested_size := Vector2i(1920, 1080)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--test-size="):
			var parts := argument.trim_prefix("--test-size=").split("x")
			if parts.size() == 2:
				requested_size = Vector2i(int(parts[0]), int(parts[1]))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(requested_size)
	call_deferred("_check_menu")

func _check_menu() -> void:
	var failures: Array[String] = []
	for state in ["anomaly", "normal"]:
		var menu = MENU_SCENE.instantiate()
		add_child(menu)
		await get_tree().process_frame
		await get_tree().process_frame
		menu.normal_backgrounds_unlocked = state == "normal"
		menu._update_state_label()
		var expected_label := "校园已恢复 · 日常影像已解锁" if state == "normal" else "异常校园 · 完整通关后恢复日常影像"
		if menu.state_label.text != expected_label:
			failures.append("label:%s" % state)
		for index in range(3):
			menu._set_background(index, true)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			if menu.background.texture == null:
				failures.append("texture:%s:%d" % [state, index])
			var image := menu.get_viewport().get_texture().get_image()
			var output := "res://.godot/m1-main-menu-%s-%d.png" % [state, index]
			var error := image.save_png(output)
			if error != OK:
				failures.append("capture:%s:%d:%s" % [state, index, error])
			else:
				print("MENU_CAPTURE state=%s index=%d size=%s path=%s" % [state, index, image.get_size(), output])
			menu.background_elapsed = 8.0
			menu._process(0.01)
			if menu.background_index != posmod(index + 1, 3):
				failures.append("rotation:%s:%d" % [state, index])
		menu.queue_free()
		await get_tree().process_frame
	if failures.is_empty():
		print("MENU_CHECK passed states=2 backgrounds=6 rotations=6 window=%s viewport=%s texture=%s" % [DisplayServer.window_get_size(), get_viewport().get_visible_rect().size, get_viewport().get_texture().get_size()])
	else:
		push_error("MENU_CHECK failed %s" % str(failures))
		get_tree().quit(1)
