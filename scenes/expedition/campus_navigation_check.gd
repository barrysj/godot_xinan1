extends Control
## Exercise the real controller with an isolated profile; combat progress is a fixture.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Presentation = preload("res://game/run/campus_presentation.gd")
const Regions = preload("res://game/run/campus_region.gd")
var checks := 0
var failures := 0
var game
const OUTPUT := "res://.godot/art-workflow/navigation-ui/"

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("NAVIGATION_UI: " + message)

func settle() -> void:
	for i in range(6): await get_tree().process_frame

func settle_map(board: Control) -> void:
	await settle()
	var deadline := Time.get_ticks_msec()+2000
	while board.view_is_moving() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame

func click(item: Control, local := Vector2.INF) -> void:
	var at := item.size / 2.0 if local == Vector2.INF else local
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = item.get_global_transform_with_canvas() * at
		get_viewport().push_input(event, true)
	await settle()

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		get_viewport().push_input(event, true)
	await settle()

func hover(item: Control) -> void:
	var event := InputEventMouseMotion.new()
	event.position = item.get_global_transform_with_canvas() * (item.size/2)
	get_viewport().push_input(event, true)
	await settle()

func leave_map() -> void:
	var event := InputEventMouseMotion.new()
	event.position = Vector2(3, 3)
	get_viewport().push_input(event, true)
	await settle()

func drag_node(item: Control) -> void:
	var start: Vector2 = item.get_global_transform_with_canvas() * Vector2(90,50)
	var down := InputEventMouseButton.new()
	down.position = start
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_viewport().push_input(down, true)
	var motion := InputEventMouseMotion.new()
	motion.position = start + Vector2(30,24)
	motion.relative = Vector2(30,24)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)
	down.position = motion.position
	down.pressed = false
	get_viewport().push_input(down, true)
	await settle()

func capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	# Native Windows resizing can round by one pixel after scene transitions.
	get_window().size = resolution
	await settle()
	await get_tree().create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	expect(shot.get_size() == resolution, "physical screenshot size " + label)
	expect(shot.save_png(OUTPUT+"%s-%dx%d.png" % [label, resolution.x, resolution.y]) == OK, "capture " + label)

func fits(item: Control, label: String) -> void:
	expect(Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).encloses(item.get_global_rect()), label + " fits viewport")

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game = Campaign.instantiate()
	game.progress.path = OUTPUT+"profile-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await settle()
	game.set_process(false)
	game.progress.campaign.routes_acquired = true
	get_window().mode = Window.MODE_WINDOWED
	var probe_flow := Regions.flow_for("region_b").duplicate(true)
	var probe_geometry = preload("res://game/run/expanded_campus_geometry.gd").new()
	probe_flow.stops.end_b.place_id = "basic_laboratory_building"
	probe_flow.stops.end_b.landmark = "pinxue"
	probe_flow.stops.end_b.offset = [0, -175]
	expect(Presentation.point("region_b", "end_b", probe_geometry, probe_flow) == Vector2(925,740), "saved legacy placeholder uses corrected live point")
	probe_flow.stops.end_b.offset = [20, 30]
	expect(Presentation.point("region_b", "end_b", probe_geometry, probe_flow) == probe_geometry.PLACES.pinxue.point+Vector2(20,30), "custom authored offset remains effective")
	var resolutions := [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200), Vector2i(1280,720)]
	for resolution in resolutions:
		get_window().size = resolution
		game.progress.active_run = {}
		game._home()
		await settle()
		game._open_map_region()
		await settle()
		var preview = game.get_node("CampaignMapRegionPreview")
		expect(get_viewport().gui_get_focus_owner() == preview.route_buttons[0], "map starts with a usable focus")
		await key(KEY_DOWN)
		await key(KEY_ENTER)
		expect(preview.board.selected_route == 1, "keyboard chooses the second route")
		for index in range(3):
			preview._back()
			await settle_map(preview.board)
			await click(preview.route_buttons[index])
			var region: String = preview.campaign_region_for_route(index)
			var flow := Regions.flow_for(region)
			var nodes: Array = preview.route_nodes.nodes
			expect(nodes.size() == preview.board.layout.ROUTES[index].places.size(), "region expands every geographic route place")
			expect(not preview.targets.visible and preview.selected_node == -1, "region selection precedes place selection")
			for i in range(nodes.size()):
				await click(preview.route_nodes.buttons[i], Vector2(90,50))
				expect(preview.selected_node == i and preview.route_nodes.buttons[i].button_pressed, "click selects individual place %s/%s at %s" % [region, nodes[i].title, preview.route_nodes.buttons[i].position])
				expect(preview.detail_title.text == nodes[i].title, "place details match selected node")
				expect(preview.picture.texture.resource_path == Presentation.background(region, nodes[i].stop, "anomaly", flow), "selected photo uses the canonical place")
				fits(preview.route_nodes.buttons[i], "route place")
			if index == 1:
				expect(nodes.back().point == preview.board.layout.PLACES.main.point, "main-building terminal uses editor coordinate")
			if index == 0:
				expect(nodes[0].title == "成电会堂" and nodes[1].title == "商业街", "compound stop has separate geographic nodes")
				expect(nodes[0].point == preview.board.layout.PLACES.hall.point and nodes[1].point == preview.board.layout.PLACES.shopping.point, "split nodes use actual map landmarks")
			expect(not visible_text_contains(preview,"南门"),"formal route has no South Gate node or stale instructional text")
			await capture("region-%d" % index, resolution)
			fits(preview.select_button, "map primary action")
		for state in ["day", "night", "anomaly"]:
			preview.board.set_state(state)
			await settle()
			expect(preview.shell.state == state and preview.board.selected_route == 2, "appearance preserves region")
			fits(preview.shell.rail, "map rail")
			fits(preview.shell.heading, "map heading")
		preview._back()
		await settle_map(preview.board)
		await click(preview.route_buttons[0])
		await click(preview.route_nodes.buttons[0], Vector2(90,50))
		preview.board.set_zoom(1.6)
		await settle_map(preview.board)
		var before_offset: Vector2 = preview.board.map_offset
		await drag_node(preview.route_nodes.buttons[0])
		expect(preview.board.map_offset.distance_to(before_offset) > 20 and preview.selected_node == 0, "node drag pans without changing place selection")
		preview.route_nodes.buttons[0].grab_focus()
		await key(KEY_DOWN)
		await key(KEY_ENTER)
		expect(preview.selected_node == 1, "keyboard chooses places after drag")
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.position = preview.route_nodes.buttons[1].get_global_transform_with_canvas() * Vector2(90,50)
		for down in [true, false]:
			wheel.pressed = down
			get_viewport().push_input(wheel, true)
		await settle()
		expect(preview.board.zoom > 1.6 and preview.selected_node == 1, "wheel zoom preserves selected node")
		preview.board.reset_view()
		await settle_map(preview.board)
		await hover(preview.route_nodes.buttons[2])
		expect(preview.selected_node == 1 and preview.detail_title.text == preview.route_nodes.nodes[1].title, "hover preserves click selected details")
		await leave_map()
		await capture("map-selection", resolution)
		expect(game.progress.active_run.is_empty(), "route preview does not start a run")
		await click(preview.select_button)
		expect(game.campaign_panel.action_button("strategy:library:region:keep") != null, "one confirmation reaches the original starting strategy")
		expect(game.progress.active_run.is_empty(), "strategy still precedes starting the journey")
		game._campaign_action("strategy:library:region:keep")
		await settle()
		var picker = game.campaign_panel.station_picker
		expect(picker != null and picker.destination_buttons.size() == 2, "initial compound stop exposes two places but one station")
		await click(picker.travel_button)
		expect(game.journey.visit.data.place == "gate", "travel uses the canonical enter action")
		expect(game.campaign_panel.station_picker == null and game.campaign_panel.action_button("enter:0") == null, "old navigation controls leave the tree")
		# Fixture only: guard/reward still belong to the existing combat/reward systems.
		game.journey.visit.data.guard_won = true
		game.journey.visit.data.reward_taken = true
		game._campaign_action("leave")
		await settle()
		picker = game.campaign_panel.station_picker
		var before := JSON.stringify(game.journey.snapshot())
		await key(KEY_DOWN)
		await key(KEY_ENTER)
		expect(picker.board.selected == 1 and picker.destination_buttons[1].button_pressed, "keyboard selects the graphical destination")
		await click(picker.board, picker.board.project(Presentation.point("library", "walk", picker.board.layout)))
		expect(picker.board.selected == 0 and picker.destination_buttons[0].button_pressed and not picker.destination_buttons[1].button_pressed, "clicking the map position selects its graphical node")
		await click(picker.destination_buttons[1])
		expect(picker.board.selected == 1 and picker.travel_button.get_meta("action_id") == "enter:1", "graphical node selects the correct destination")
		await hover(picker.destination_buttons[0])
		expect(picker.board.selected == 1 and not picker.travel_button.disabled and picker.detail_title.text == picker.destination_buttons[1].text, "hover keeps clicked destination and details")
		await leave_map()
		expect(not picker.travel_button.disabled and picker.travel_button.get_meta("action_id") == "enter:1", "leaving hover restores the committed travel action")
		await click(picker.targets.buttons.back(), Vector2(90,50))
		expect(picker.travel_button.disabled and picker.detail_title.text == "图书馆", "future node can be inspected but cannot travel")
		expect(picker.board.selected == 1, "future inspection preserves valid current choice")
		await click(picker.destination_buttons[1], Vector2(90,50))
		for item in picker.destination_buttons: fits(item, "graphical destination node")
		expect(JSON.stringify(game.journey.snapshot()) == before, "all preview inputs preserve the journey")
		fits(picker.travel_button, "travel action")
		fits(picker.base_button, "return action")
		fits(picker.shell.rail, "station rail")
		await capture("next-station", resolution)
		game.campaign_panel.route(game.journey, true)
		await settle()
		picker = game.campaign_panel.station_picker
		expect(picker.picture.texture.resource_path == Presentation.background("library", "walk", "daily", game.journey.data.flow), "restored thumbnail is daily")
		expect(picker.board.map_state == "day", "restored map is daily")
		await capture("next-station-day", resolution)
		await click(picker.base_button)
		expect(game.campaign_panel.station_picker == null and game.campaign_panel.action_button("enter:0") == null, "return clears route controls")
	# Compound destination fixture: two map places still enter the same final stop.
	game._begin_region("library", "region", "keep")
	game.journey.data.step = 0
	game.journey.data.visited = []
	game.campaign_panel.route(game.journey, false)
	await settle()
	var final_picker = game.campaign_panel.station_picker
	expect(final_picker.destination_buttons.size() == 2, "compound initial stop has two physical selectors")
	var final_before := JSON.stringify(game.journey.snapshot())
	for i in range(2):
		await click(final_picker.destination_buttons[i], Vector2(90,50))
		expect(final_picker.travel_button.get_meta("action_id") == "enter:0" and not final_picker.travel_button.disabled, "both components use original initial enter action")
		expect(final_picker.detail_title.text == ["成电会堂", "商业街"][i], "compound component keeps its own geographic name")
	expect(JSON.stringify(game.journey.snapshot()) == final_before, "compound inspection preserves the narrative journey")
	await capture("compound-next-station", Vector2i(1280,720))
	await click(final_picker.travel_button)
	expect(game.journey.visit.data.place == "gate", "compound travel enters original story stop")
	print("CAMPUS_NAVIGATION_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func visible_text_contains(root: Node, value: String) -> bool:
	if root is Label and root.is_visible_in_tree() and value in root.text: return true
	for child in root.get_children():
		if visible_text_contains(child,value): return true
	return false
