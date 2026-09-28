extends RefCounted
var failures = 0
var checks = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func settle(view: Control) -> void:
	for i in range(4): await view.get_tree().process_frame
	await RenderingServer.frame_post_draw

func motion(view: Control, local: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.position = view.board.get_global_transform_with_canvas() * local
	view.get_viewport().push_input(event, true)
	await settle(view)

func click(view: Control, at: Vector2) -> void:
	for down in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		view.get_viewport().push_input(event, true)
	await settle(view)

func pixel(view: Control, picture: Image, source: Vector2) -> Color:
	var at = view.get_viewport().get_final_transform() * (view.board.get_global_transform_with_canvas() * view.board.project(source))
	return picture.get_pixelv(Vector2i(at))

func luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722

func walk_checks(view: Control, route: int, state: String, dimensions: Vector2i) -> void:
	await click(view, view.route_buttons[route].get_global_rect().get_center())
	await click(view, view.primary.get_global_rect().get_center())
	var ids = view.board.Geometry.ROUTES[route].places
	check(view.walk.route == route and view.walk.current_place() == ids[0], "start at first station")
	check(view.board.current_place == ids[0], "map current-position marker")
	check(view.board.next_place == ids[1] and view.detail.text.contains("下一站 · " + view.board.Geometry.PLACES[ids[1]].title), "first next station is explicit")
	await click(view, view.place_buttons[2].get_global_rect().get_center())
	check(view.inspected == ids[2] and view.walk.step == 0, "detail browsing does not skip stations")
	await click(view, view.board.get_global_transform_with_canvas() * view.board.project(view.board.Geometry.PLACES[ids[1]].anchor))
	check(view.inspected == ids[1] and view.walk.step == 0, "map click only inspects")
	await motion(view, view.board.project(view.board.Geometry.PLACES[view.board.Geometry.ROUTES[1-route].places[0]].anchor))
	check(view.board.active_route() == route, "walking retains route focus")
	await click(view, view.route_buttons[1-route].get_global_rect().get_center())
	check(view.walk.route == route and view.board.selected_route == route, "disabled route cannot replace active walk")
	await click(view, view.primary.get_global_rect().get_center())
	check(view.walk.step == 1 and view.inspected == ids[1], "advance to second station")
	check(view.board.next_place == ids[2] and view.detail.text.contains("下一站 · " + view.board.Geometry.PLACES[ids[2]].title), "next station follows progress")
	view.board.set_state("night" if state != "night" else "day")
	view._refresh()
	check(view.walk.step == 1 and view.board.current_place == ids[1], "lighting switch retains station")
	view.board.set_state(state)
	view._refresh()
	await settle(view)
	var shot = view.get_viewport().get_texture().get_image()
	shot.save_png("res://.godot/route-walk-%s-%d-%dx%d.png" % [state, route+1, dimensions.x, dimensions.y])
	check(view.get_global_rect().encloses(view.primary.get_global_rect()), "walk action fits viewport")
	await click(view, view.primary.get_global_rect().get_center())
	check(view.walk.step == 2 and not view.walk.complete, "third station before completion")
	check(view.board.next_place.is_empty(), "final station has no next marker")
	await click(view, view.primary.get_global_rect().get_center())
	check(view.walk.complete and view.primary.text == "返回选路", "completion feedback")
	check(view.board.current_place == ids[2] and view.detail.text.contains(view.board.Geometry.PLACES[ids[2]].title), "destination remains clearly marked after completion")
	check(view.board.next_place.is_empty() and view.detail.text.contains("路线预览完成"), "completion removes next marker")
	if state == "anomaly" and route == 1 and dimensions == Vector2i(1920,1080):
		view.get_viewport().get_texture().get_image().save_png("res://.godot/route-walk-complete.png")
	await click(view, view.primary.get_global_rect().get_center())
	check(view.walk.route == -1 and view.board.locked_route == -1 and view.board.selected_route == route, "return to route selection")
	await click(view, view.primary.get_global_rect().get_center())
	await click(view, view.secondary.get_global_rect().get_center())
	check(view.walk.route == -1 and view.board.current_place.is_empty(), "cancel early resets transient progress")
	await click(view, view.secondary.get_global_rect().get_center())
	check(view.board.selected_route == -1, "clear after walk")

func run(view: Control) -> void:
	await settle(view)
	var model = view.Walk.new()
	check(not model.start(-1) and not model.start(2) and not model.advance(), "reject invalid or unstarted walk")
	check(model.start(0) and not model.start(1), "no restart while active")
	for i in range(3): check(model.advance(), "advance model")
	check(model.complete and not model.advance(), "no advance beyond completion")
	model.reset()
	check(model.route == -1 and model.current_place().is_empty(), "model reset")
	var board = view.board
	for dimensions in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		view.get_window().size = dimensions
		await settle(view)
		check(view.get_global_rect().encloses(view.route_buttons[1].get_global_rect()), "route buttons fit")
		for state in ["day", "night", "anomaly"]:
			board.set_state(state)
			board.select_route(-1)
			await motion(view, Vector2(3,3))
			check(board.active_route() == -1, "blank area clears hover")
			for route in range(2):
				await settle(view)
				var neutral = view.get_viewport().get_texture().get_image()
				var grass = [Vector2(740,876), Vector2(778,584)][route]
				await motion(view, board.project(grass))
				check(board.hovered_route == route, "continuous grass area receives hover")
				await motion(view, Vector2(3,3))
				for place in board.Geometry.ROUTES[route].places:
					check(board.route_at(board.project(board.Geometry.PLACES[place].anchor)) == route, "anchor hit: " + place)
				var place = board.Geometry.ROUTES[route].places[0]
				await motion(view, board.project(board.Geometry.PLACES[place].anchor))
				check(board.hovered_route == route, "real mouse hover activates route")
				check(board.selected_route == -1, "hover does not select")
				await click(view, board.get_global_transform_with_canvas() * board.project(board.Geometry.PLACES[place].anchor))
				check(board.selected_route == route, "map click selects")
				board.select_route(-1)
				await motion(view, Vector2(3,3))
				await click(view, view.route_buttons[route].get_global_rect().get_center())
				check(board.selected_route == route, "mouse button selects")
				board.select_route(-1)
				view.route_buttons[route].grab_focus()
				var key = InputEventAction.new()
				key.action = "ui_accept"
				key.pressed = true
				Input.parse_input_event(key)
				key = InputEventAction.new()
				key.action = "ui_accept"
				key.pressed = false
				Input.parse_input_event(key)
				await settle(view)
				check(board.selected_route == route, "keyboard button selects route")
				var shot = view.get_viewport().get_texture().get_image()
				check(luminance(pixel(view,shot,Vector2(1290,600))) < luminance(pixel(view,neutral,Vector2(1290,600))) * 0.65, "outside area visibly dims")
				check(luminance(pixel(view,shot,grass)) > luminance(pixel(view,neutral,grass)), "grass inside region brightens")
				check(shot.get_size() == dimensions, "capture pixel dimensions")
				shot.save_png("res://.godot/route-preview-%s-%d-%dx%d.png" % [state,route+1,dimensions.x,dimensions.y])
				var other = 1 - route
				await motion(view, board.project(board.Geometry.PLACES[board.Geometry.ROUTES[other].places[0]].anchor))
				check(board.active_route() == other and board.selected_route == route, "hover temporarily overrides selection")
				await motion(view, Vector2(3,3))
				check(board.active_route() == route, "leaving restores selection")
				var point_before = board.project(board.Geometry.PLACES[place].anchor)
				board.set_state("night" if state != "night" else "day")
				check(board.selected_route == route and board.project(board.Geometry.PLACES[place].anchor) == point_before, "state switch preserves selection and coordinates")
				board.set_state(state)
				board.select_route(-1)
				check(board.active_route() == -1, "clear selection")
				await settle(view)
				var cleared = view.get_viewport().get_texture().get_image()
				check(pixel(view,cleared,grass).is_equal_approx(pixel(view,neutral,grass)), "clear restores original texture pixels")
				await walk_checks(view, route, state, dimensions)
	var entry: Button = null
	for candidate in view.find_children("*", "Button", true, false):
		if candidate.text == "全图": entry = candidate
	check(entry != null, "expanded map entry exists")
	if entry != null:
		await click(view, entry.get_global_rect().get_center())
		var expanded = view.get_parent().get_node_or_null("ExpandedCampusPreview")
		check(expanded != null and not view.visible, "expanded map opens as separate preview")
		if expanded != null:
			expanded._close()
			await settle(view)
			check(view.visible, "return restores core preview")
	print("ROUTE PREVIEW: %d checks / %d failures" % [checks, failures])
	view.get_tree().quit(1 if failures else 0)
