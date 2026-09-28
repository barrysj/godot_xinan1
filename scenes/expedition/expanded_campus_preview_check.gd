extends RefCounted
var checks = 0
var failures = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func settle(view: Control) -> void:
	for i in range(5): await view.get_tree().process_frame
	var deadline = Time.get_ticks_msec() + 2000
	while view.board.view_is_moving() and Time.get_ticks_msec() < deadline:
		await view.get_tree().process_frame
	await RenderingServer.frame_post_draw

func click(view: Control, at: Vector2) -> void:
	for down in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		view.get_viewport().push_input(event, true)
	await settle(view)

func motion(view: Control, local: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.position = view.board.get_global_transform_with_canvas() * local
	view.get_viewport().push_input(event, true)
	await settle(view)

func run(view: Control) -> void:
	await settle(view)
	var anchor = view.board.size / 2.0 + Vector2(0, 80)
	var source = view.board.unproject(anchor)
	view.board.set_zoom(2.0, anchor)
	check(is_equal_approx(view.board.displayed_zoom, 1.0), "zoom does not jump on input")
	view.board._advance_view(1.0 / 60.0)
	check(view.board.displayed_zoom > 1.0 and view.board.displayed_zoom < 2.0, "zoom has intermediate frames")
	check(view.board.unproject(anchor).distance_to(source) < 0.01, "zoom pivot stays fixed during interpolation")
	await settle(view)
	var start_offset: Vector2 = view.board.displayed_offset
	view.board.pan(Vector2(0, -100))
	check(view.board.displayed_offset == start_offset, "pan does not jump on input")
	view.board._advance_view(1.0 / 60.0)
	check(view.board.displayed_offset.y < start_offset.y and view.board.displayed_offset.y > view.board.map_offset.y, "pan has intermediate frames")
	view.board.reset_view()
	await settle(view)
	check(not view.board.view_is_moving(), "interrupted motion settles exactly")
	view.board.set_zoom(2.0, anchor)
	for i in range(6): view.board._advance_view(1.0 / 30.0)
	var slow_zoom: float = view.board.displayed_zoom
	var slow_offset: Vector2 = view.board.displayed_offset
	view.board.displayed_zoom = 1.0
	view.board.displayed_offset = Vector2.ZERO
	for i in range(24): view.board._advance_view(1.0 / 120.0)
	check(absf(slow_zoom - view.board.displayed_zoom) < 0.00001 and slow_offset.distance_to(view.board.displayed_offset) < 0.001, "30 and 120 fps have matching response")
	view.board.set_zoom(view.board.zoom * view.board.ZOOM_STEP, anchor)
	view.board.set_zoom(view.board.zoom * view.board.ZOOM_STEP, anchor)
	check(is_equal_approx(view.board.zoom, 3.0), "rapid inputs accumulate and respect zoom limit")
	view.board.reset_view()
	await settle(view)
	for dimensions in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1920, 1200)]:
		view.get_window().size = dimensions
		await settle(view)
		check(view.board.map_rect().size.x > 0, "map has visible width")
		check(view.get_global_rect().encloses(view.route_buttons[0].get_global_rect()), "route button fits screen")
		for state in ["day", "night", "anomaly"]:
			view.board.select_route(-1)
			view.board.set_state(state)
			await settle(view)
			var no_focus_shot = view.get_viewport().get_texture().get_image()
			var no_focus_edge = int(view.board.map_rect().position.x)
			var no_focus_mid = int(view.board.size.y / 2.0)
			var no_focus_backdrop = no_focus_shot.get_pixel(no_focus_edge - 6, no_focus_mid)
			var no_focus_atlas = no_focus_shot.get_pixel(no_focus_edge + 6, no_focus_mid)
			check(Vector3(no_focus_backdrop.r, no_focus_backdrop.g, no_focus_backdrop.b).distance_to(Vector3(no_focus_atlas.r, no_focus_atlas.g, no_focus_atlas.b)) < 0.06, "unfocused atlas edge blends into backdrop")
			no_focus_shot.save_png("res://.godot/expanded-map-unselected-%s-%dx%d.png" % [state, dimensions.x, dimensions.y])
			if dimensions == Vector2i(1920, 1080) and state == "day":
				var probe = Vector2i(view.board.get_global_transform_with_canvas() * view.board.project(Vector2(300, 200)))
				var dimmed = no_focus_shot.get_pixelv(probe).get_luminance()
				var full_map = PackedVector2Array([Vector2.ZERO, Vector2(1800, 0), Vector2(1800, 1500), Vector2(0, 1500)])
				full_map.resize(32)
				view.board.focus_material.set_shader_parameter("light_boundary", full_map)
				view.board.focus_material.set_shader_parameter("light_boundary_count", 4)
				await settle(view)
				var bright = view.get_viewport().get_texture().get_image().get_pixelv(probe).get_luminance()
				check(bright > dimmed + 0.08, "dragging light boundary can restore outside pixels")
				var original = PackedVector2Array(view.board.layout.LIGHT_BOUNDARY)
				view.board.focus_material.set_shader_parameter("light_boundary_count", original.size())
				original.resize(32)
				view.board.focus_material.set_shader_parameter("light_boundary", original)
				await settle(view)
				check(absf(view.get_viewport().get_texture().get_image().get_pixelv(probe).get_luminance() - dimmed) < 0.02, "restoring light boundary restores dimming")
			for route in range(3):
				var unique_place = ["west", "north", "stadium"][route]
				await motion(view, view.board.project(view.board.layout.PLACES[unique_place].point))
				check(view.board.hovered_route == route, "map hover selects exploration region")
				await motion(view, Vector2(3, 3))
				await click(view, view.state_buttons[["day", "night", "anomaly"].find(state)].get_global_rect().get_center())
				await click(view, view.route_buttons[route].get_global_rect().get_center())
				check(view.board.map_state == state and view.board.selected_route == route, "state and route selected: expected %s/%d got %s/%d" % [state, route, view.board.map_state, view.board.selected_route])
				check(view.board.active_route() == route, "area focused")
				var shot = view.get_viewport().get_texture().get_image()
				check(shot.get_width() == dimensions.x and shot.get_height() == dimensions.y, "screenshot dimensions")
				var seam_x = int(view.board.map_rect().position.x)
				var seam_y = int(view.board.size.y / 2.0)
				var backdrop = shot.get_pixel(seam_x - 6, seam_y)
				var atlas_edge = shot.get_pixel(seam_x + 6, seam_y)
				check(Vector3(backdrop.r, backdrop.g, backdrop.b).distance_to(Vector3(atlas_edge.r, atlas_edge.g, atlas_edge.b)) < 0.06, "wide-screen atlas edge blends into backdrop")
				shot.save_png("res://.godot/expanded-map-%s-%d-%dx%d.png" % [state, route + 1, dimensions.x, dimensions.y])
		var place_at = view.board.get_global_transform_with_canvas() * view.board.project(view.board.layout.PLACES["north"].point)
		await click(view, place_at)
		check(view.board.selected_place == "north", "map marker can be inspected")
		view.board.reset_view()
		var library_point: Vector2 = view.board.layout.PLACES["library"].point
		var screen_anchor: Vector2 = view.board.project(library_point)
		await click(view, view.zoom_in_button.get_global_rect().get_center())
		check(view.board.zoom > 1.0, "zoom button enlarges map")
		check(view.board.unproject(view.board.project(library_point)).distance_to(library_point) < 0.01, "zoom projection round trip")
		check(view.board.place_at(view.board.project(library_point)) == "library", "zoomed marker stays clickable")
		var wheel = InputEventMouseButton.new()
		wheel.position = view.board.get_global_transform_with_canvas() * screen_anchor
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		view.get_viewport().push_input(wheel, true)
		wheel.pressed = false
		view.get_viewport().push_input(wheel, true)
		await settle(view)
		check(view.board.zoom > 1.25, "wheel enlarges map")
		var before_pan: Vector2 = view.board.map_rect().position
		view.board.pan(Vector2(-45, -30))
		await settle(view)
		check(view.board.map_rect().position.distance_to(before_pan) > 1.0, "zoomed map pans")
		var drag_from: Vector2 = view.board.get_global_transform_with_canvas() * (view.board.size / 2.0)
		var drag_down = InputEventMouseButton.new()
		drag_down.position = drag_from
		drag_down.button_index = MOUSE_BUTTON_LEFT
		drag_down.pressed = true
		view.get_viewport().push_input(drag_down, true)
		var drag_move = InputEventMouseMotion.new()
		drag_move.position = drag_from + Vector2(-36, 24)
		drag_move.relative = Vector2(-36, 24)
		drag_move.button_mask = MOUSE_BUTTON_MASK_LEFT
		view.get_viewport().push_input(drag_move, true)
		drag_down.position = drag_move.position
		drag_down.pressed = false
		view.get_viewport().push_input(drag_down, true)
		await settle(view)
		check(view.board.map_rect().position.distance_to(before_pan) > 20.0, "mouse drag pans instead of selecting")
		check(view.board.route_at(view.board.project(view.board.layout.PLACES["west"].point)) == 0, "route hit remains aligned after pan")
		view.board.set_state("anomaly")
		check(view.board.place_at(view.board.project(library_point)) == "library", "state switch keeps zoomed anchors")
		await settle(view)
		view.get_viewport().get_texture().get_image().save_png("res://.godot/expanded-map-zoom-%dx%d.png" % [dimensions.x, dimensions.y])
		await click(view, view.zoom_reset_button.get_global_rect().get_center())
		check(is_equal_approx(view.board.zoom, 1.0) and view.board.map_offset.length() < 0.01, "reset restores full map: zoom %f offset %s" % [view.board.zoom, view.board.map_offset])
		view.board.select_route(-1)
		var route_point = view.board.get_global_transform_with_canvas() * view.board.project(Vector2(360, 650))
		await click(view, route_point)
		check(view.board.selected_route == 0 and view.select_button.visible, "clicking map area opens select action")
		await click(view, view.select_button.get_global_rect().get_center())
		check(view.focused_route == 0 and view.board.zoom > 1.0, "select focuses route area")
		check(view.explore_button.visible and view.back_button.visible and not view.controls_panel.visible, "focused area shows explore and back")
		view.get_viewport().get_texture().get_image().save_png("res://.godot/expanded-map-focused-%dx%d.png" % [dimensions.x, dimensions.y])
		await click(view, view.back_button.get_global_rect().get_center())
		check(view.focused_route == -1 and view.board.selected_route == -1 and is_equal_approx(view.board.zoom, 1.0), "back restores full map")
		view.board.select_route(-1)
	await settle(view)
	print("EXPANDED_MAP_CHECK %d checks, %d failures" % [checks, failures])
	if failures == 0: view.get_tree().quit(0)
	else: view.get_tree().quit(1)
