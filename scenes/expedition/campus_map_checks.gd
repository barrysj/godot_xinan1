extends RefCounted
var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func mouse(map: Control, at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.pressed = pressed
	map._gui_input(event)

func run_checks(game: Control) -> void:
	game.progress.path = "res://.godot/campus-map-test.json"
	game.progress.points = 20
	game.screen = "dispatch"
	var map: Control = game.campus_map
	var initial: Dictionary = game.progress.to_dict().duplicate(true)
	await game.get_tree().process_frame
	for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
		game.get_window().mode = Window.MODE_WINDOWED
		game.get_window().size = resolution
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		map.reset_view()
		var at: Vector2 = map._offset() + map.point(0) * map._fit()
		check(map.location_at(at) == 0, "Map hit test at " + str(resolution))
		var motion := InputEventMouseMotion.new()
		motion.position = at
		map._gui_input(motion)
		check(map.hovered == 0, "Hover reveals location")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("res://.godot/campus-map-hover-%dx%d.png" % [resolution.x,resolution.y])
		mouse(map, at, true)
		mouse(map, at, false)
		check(is_instance_valid(game.location_panel) and game.selected_location == 0, "Locked location opens details")
		check(game.location_panel.find_child("Details", true, false).text.contains("派遣事务所"), "Unlock condition displayed")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("res://.godot/campus-map-details-%dx%d.png" % [resolution.x,resolution.y])
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		game._input(escape)
		check(not is_instance_valid(game.location_panel) and not game.paused, "Escape closes details without pause")
		map.zoom_at(at, 2)
		var shifted: Vector2 = map._offset() + map.point(0) * map._fit() * map.zoom
		check(map.location_at(shifted) == 0, "Zoomed hit test")
		mouse(map, shifted, true)
		motion.position = shifted + Vector2(120, 70)
		map._gui_input(motion)
		mouse(map, motion.position, false)
		check(not is_instance_valid(game.location_panel), "Dragging cannot click a location")
		map.reset_view()
		check(map.zoom == 1 and map.pan == Vector2.ZERO, "Reset restores overview")
	check(game.progress.to_dict() == initial, "Navigation never mutates profile or charges resources")
	game.progress.upgrades["dispatch"] = 1
	game._open_location_details(0)
	check(game.location_panel.find_child("Details", true, false).text.contains("已解锁"), "Unlocked location details")
	game._close_location_details()
	game._open_location_details(1)
	check(game.location_panel.find_child("Details", true, false).text.contains("体育馆通行证"), "Each location uses its own details")
	game._close_location_details()
	print("CAMPUS MAP CHECK: ", "PASS" if failures == 0 else "FAIL")
	game.get_tree().quit(failures)
