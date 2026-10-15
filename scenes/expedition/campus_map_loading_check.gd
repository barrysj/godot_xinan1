extends Control
## Real map construction and region selection, also runnable in the Web export.
var failures := 0
var checks := 0

func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("MAP_LOADING: " + label)

func _ready() -> void:
	var start := Time.get_ticks_msec()
	var packed = load("res://scenes/expedition/expanded_campus_preview.tscn")
	print("MAP_LOADING script_ms=", Time.get_ticks_msec()-start)
	var view = packed.instantiate()
	add_child(view)
	print("MAP_LOADING ready_ms=", Time.get_ticks_msec()-start)
	for i in range(3): await get_tree().process_frame
	print("MAP_LOADING open_ms=", Time.get_ticks_msec()-start)
	for index in range(3):
		view._back()
		for i in range(30): await get_tree().process_frame
		start = Time.get_ticks_msec()
		view.route_buttons[index].pressed.emit()
		var elapsed := Time.get_ticks_msec()-start
		print("MAP_LOADING region=", view.campaign_region_for_route(index), " click_ms=", elapsed)
		expect(elapsed < 250, "region selection blocks the main thread")
		expect(view.board.zoom > 1.0 and view.board.view_is_moving(), "region starts animated focus")
		for i in range(45): await get_tree().process_frame
		expect(view.board.route_area_focus and view.board.focus_material.get_shader_parameter("focused"), "selected area stays lit")
		expect(view.route_nodes.buttons.size() > 0, "region contains visible nodes")
		for button in view.route_nodes.buttons:
			expect(button.is_visible_in_tree() and button.photo.texture != null, "node thumbnail is visible")
			expect(button.photo.texture.get_size() == Vector2(128,128), "node loads a small derivative")
		view.board.preview((index+1)%3)
		expect(view.board.active_route() == index, "hover cannot replace selected light area")
		view._choose_node(view.route_nodes.buttons.size()-1)
		expect(view.picture.texture != null, "full detail background loads on demand")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.godot/art-workflow/map-performance/region-%d.png" % index)
	view.queue_free()
	await get_tree().process_frame
	var game = load("res://scenes/expedition/expedition.tscn").instantiate()
	game.progress.path = "user://map-loading-check-%d.json" % Time.get_ticks_usec() if OS.has_feature("web") else "res://.godot/art-workflow/map-performance/profile-%d.json" % Time.get_ticks_usec()
	add_child(game)
	game.set_process(false)
	game.progress.campaign.routes_acquired = true
	game.progress.commission_unlocks.append("departure")
	game._home()
	for i in range(60): await get_tree().process_frame
	start = Time.get_ticks_msec()
	game._open_map_region()
	view = game.get_node("CampaignMapRegionPreview")
	print("MAP_LOADING main_open_handler_ms=", Time.get_ticks_msec()-start)
	expect(Time.get_ticks_msec()-start < 250, "main map opens without blocking on the atlas")
	for i in range(60): await get_tree().process_frame
	expect(view.board.surface.texture != null, "main map atlas finishes loading")
	view.route_buttons[0].pressed.emit()
	for i in range(45): await get_tree().process_frame
	expect(view.route_nodes.buttons.size() == 6, "real main library region expands all six places")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/art-workflow/map-performance/main-library.png")
	view._close()
	await get_tree().process_frame
	game._begin_region("library", "region", "protect", [])
	expect(not game.journey.data.is_empty(), "main can start the library journey")
	game.journey.data.step = 3
	game.journey.data.visited = ["gate","walk","hall"]
	expect(game.journey.enter(0,[]), "library interior enters through the existing journey")
	for scene_id in ["atrium","shelves","corridor","entrance"]:
		expect(game.journey.switch_scene(scene_id) or game.journey.current_scene().id == scene_id, "library scene switches: " + scene_id)
		var path: String = preload("res://game/run/place_scenes.gd").path(game.journey.current_scene())
		expect(load(path) is Texture2D, "library scene platform texture loads: " + scene_id)
	print("MAP_LOADING checks=", checks, " failures=", failures)
	if "--map-loading-hold" in OS.get_cmdline_user_args():
		game._open_map_region()
		game.get_node("CampaignMapRegionPreview").route_buttons[0].pressed.emit()
		return
	get_tree().quit(failures)
