extends Node
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Journey = preload("res://game/run/campaign_journey.gd")
const Scenes = preload("res://game/run/place_scenes.gd")
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
var checks := 0
var failures := 0
var game

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PLACE_SCENES: "+label)

func settle() -> void:
	for i in range(5): await get_tree().process_frame

func click(control: Control, local_point := Vector2(-1,-1)) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = control.get_global_transform_with_canvas()*(control.size/2 if local_point.x < 0 else local_point)
		get_viewport().push_input(event,true)
	await settle()

func capture(label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await get_tree().create_timer(0.40).timeout
	await RenderingServer.frame_post_draw
	var resolution := get_window().size
	expect(get_viewport().get_texture().get_image().save_png("res://.godot/art-workflow/place-scenes/%s-%dx%d.png" % [label,resolution.x,resolution.y]) == OK,"screenshot "+label)

func library_fixture() -> void:
	game._begin_region("library")
	# This fixture isolates scene navigation from the newer mid-route recruitment UI.
	for id in ["archer", "analyst"]:
		var role: int = game.Content.role_index(id)
		if not game.run.roster.has(role): game.run.roster.append(role)
	game.journey.data.step = 3
	game.journey.data.visited = ["gate","walk","hall"]
	expect(game.journey.enter(0,[]),"enter library via original journey")
	expect(game._save_campaign(),"save original campaign fixture")
	game._show_journey()
	await settle()

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/art-workflow/place-scenes"))
	var flow := Catalog.snapshot("library")
	expect(not flow.is_empty(),"flow authoring validation")
	if flow.is_empty(): get_tree().quit(1); return
	var configured: Array = flow.stops.library.scenes
	expect(configured.size() == 4,"library four distinct scenes")
	var paths := {}
	for entry in configured: paths[entry.background] = true
	expect(paths.size() == 4,"backgrounds are distinct")
	var native_layout = load("res://resources/campaign/layouts/library/atrium.tscn").instantiate()
	native_layout.get_node("person").position = Vector2(480,540)
	expect(native_layout.snapshot().person == [0.25,0.5],"native Marker2D drag becomes frozen normalized coordinates")
	native_layout.free()
	var missing_guard: Array = configured.duplicate(true)
	missing_guard[3].layout.erase("battle")
	expect(not Scenes.validate(missing_guard).is_empty(),"reject unreachable guardian in authored rooms")
	var invalid_layout: Array = configured.duplicate(true)
	invalid_layout[0].layout.passage = [2,0.5]
	expect(not Scenes.validate(invalid_layout).is_empty(),"reject out of bounds authored marker")
	for key in ["id","title","floor","position","background"]:
		var bad: Array = configured.duplicate(true)
		bad[0][key] = {"id":"BAD ID","title":"", "floor":1.5,"position":[-1,0],"background":"res://absent.png"}[key]
		expect(not Scenes.validate(bad).is_empty(),"reject malformed "+key)
	var duplicates: Array = configured.duplicate(true)
	duplicates[1].id = duplicates[0].id
	expect(not Scenes.validate(duplicates).is_empty(),"reject duplicate scene ID")
	for region in Journey.Regions.IDS:
		var journey = Journey.new()
		expect(journey.begin(region,2),"begin "+region)
		for stop in journey.data.flow.stops.values():
			expect(not Scenes.entries(stop).is_empty(),"every place supports scenes "+stop.place_id)
	var journey = Journey.new()
	journey.begin("library",2)
	journey.enter(0,[])
	var legacy := journey.snapshot()
	legacy.visit.erase("scene_id")
	for stop in legacy.flow.stops.values(): stop.erase("scenes")
	var restored = Journey.new()
	expect(restored.restore(JSON.parse_string(JSON.stringify(legacy))),"schema 2 legacy without scene fields")
	expect(restored.current_scene().id == "default","legacy falls back to original background")
	var generic = Catalog.definition("region_b").duplicate(true)
	# External .tres references can stay shared during Resource.duplicate(true).
	# Isolate the complete edited chain so the fixture never changes the real gate.
	generic.stages[0] = generic.stages[0].duplicate(true)
	generic.stages[0].choices[0] = generic.stages[0].choices[0].duplicate(true)
	generic.stages[0].choices[0].place = generic.stages[0].choices[0].place.duplicate(true)
	generic.stages[0].choices[0].place.scenes = Catalog.definition("library").stages[3].choices[0].place.scenes.duplicate()
	expect(journey.begin("region_b",2,generic) and journey.enter(0,[]),"multi-scene configuration works outside library")
	expect(journey.switch_scene("corridor"),"non-library place can switch authored scenes")
	var frozen := journey.snapshot()
	var generic_restored = Journey.new()
	expect(generic_restored.restore(JSON.parse_string(JSON.stringify(frozen))) and JSON.stringify(generic_restored.snapshot()) == JSON.stringify(frozen),"scene configuration and visit survive JSON exactly")
	game = Scene.instantiate()
	game.progress.path = "res://.godot/art-workflow/place-scenes/profile-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await settle()
	game.set_process(false)
	game.progress.campaign.routes_acquired = true
	game.progress.commission_unlocks.append("departure")
	get_window().mode = Window.MODE_WINDOWED
	var resolutions := [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)] if "--capture" in OS.get_cmdline_user_args() else [Vector2i(1920,1080)]
	for resolution in resolutions:
		get_window().size = resolution
		await library_fixture()
		var panel = game.campaign_panel
		var board = panel.exploration_board
		expect(board.scene_navigation != null,"original exploration has scene navigation")
		expect(game.journey.current_scene().id == "atrium","default scene preserved")
		expect(board.buttons.filter(func(item): return item.visible).size() == 1 and board.buttons[2].visible,"atrium shows only the partner hotspot")
		var original_board = board
		await capture("atrium")
		expect(board.scene_navigation.strip_heading.text == "探索场景","scene strip begins with requested title")
		for item in board.scene_navigation.strip.find_children("*","Button",true,false):
			expect(item.text not in ["上一处","下一处"],"old previous/next controls removed")
		expect(board.scene_navigation.strip.size.x < board.size.x*0.65,"scene strip hugs actual content")
		expect(board.passage_hotspot.destination == "书架区" and not board.passage_hotspot.disabled,"passage names its destination")
		await click(board.passage_hotspot,Vector2(64,136))
		expect(game.journey.current_scene().id == "shelves","passage hotspot switches scene")
		expect(panel.exploration_board == original_board,"scene switch preserves board instance")
		expect(board.buttons[1].visible and not board.buttons[2].visible,"shelves show memory instead of partner")
		expect(board.passage_hotspot.has_focus(),"passage keeps keyboard focus after scene switch")
		var transition_before: float = board.transition_alpha
		await click(board.scene_navigation.scene_buttons.shelves)
		expect(board.transition_alpha <= transition_before,"current scene click does not restart transition")
		await click(panel.exploration_board.scene_navigation.scene_buttons.atrium)
		expect(game.journey.current_scene().id == "atrium","scene selector returns to earlier scene")
		board = panel.exploration_board
		var memory_id: String = game.journey.visit.data.hotspots.filter(func(spot): return spot.kind != "battle")[0].id
		game.journey.visit.view(memory_id)
		expect(game._save_campaign(),"save investigation before switching")
		var visit_before: Dictionary = game.journey.visit.data.duplicate(true)
		visit_before.erase("scene_id")
		var stage_before: int = game.journey.data.step
		await click(board.scene_navigation.map_buttons.corridor)
		expect(game.journey.current_scene().id == "corridor","real minimap click changes scene")
		expect(panel.exploration_board.environment_path.ends_with("window-corridor.png"),"scene changes actual backdrop")
		await capture("corridor")
		game._continue_run()
		await settle()
		expect(game.journey.current_scene().id == "corridor","checkpoint resume restores scene")
		await click(panel.exploration_board.scene_navigation.scene_buttons.shelves)
		expect(game.journey.current_scene().id == "shelves","real scene button changes floor")
		expect(panel.exploration_board.scene_navigation.floor_color(1) != panel.exploration_board.scene_navigation.floor_color(2),"floors have different stable colors")
		await capture("shelves")
		await click(panel.exploration_board.scene_navigation.scene_buttons.entrance)
		expect(game.journey.current_scene().id == "entrance","exterior scene supported")
		await capture("entrance")
		var visit_after: Dictionary = game.journey.visit.data.duplicate(true)
		visit_after.erase("scene_id")
		expect(visit_before == visit_after and game.journey.data.step == stage_before,"switching never rerolls visit or advances route")
		expect(not game.journey.visit.can_leave() and panel.action_button("leave").disabled,"switch cannot bypass guardian")
		expect(panel.exploration_board.passage_hotspot.disabled,"locked exit hotspot is disabled")
		var locked_snapshot: Dictionary = game.journey.snapshot()
		await click(panel.exploration_board.passage_hotspot)
		game._campaign_action("passage")
		expect(game.journey.snapshot() == locked_snapshot,"locked exit rejects mouse and direct action")
		var saved: Dictionary = game.journey.snapshot()
		expect(not game.journey.switch_scene("missing") and game.journey.snapshot() == saved,"invalid scene is atomic")
		game.journey.data.screen = "event"
		game._campaign_action("scene:atrium")
		game._campaign_action("passage")
		expect(game.journey.current_scene().id == "entrance","modal event prevents scene changes")
		game.journey.data.screen = "visit"
		var invalid: Dictionary = game.journey.snapshot()
		invalid.visit.scene_id = "missing"
		expect(not restored.restore(invalid),"invalid checkpoint scene rejected")
		board = panel.exploration_board
		var nav = board.scene_navigation
		nav.floor_picker.select(2)
		nav.floor_picker.item_selected.emit(2)
		await settle()
		expect(nav.map_buttons.shelves.visible and not nav.map_buttons.atrium.visible,"floor filter separates stacked scenes")
		expect(game.journey.current_scene().id == "entrance","viewing a floor does not move player")
		await click(nav.scene_buttons.shelves)
		expect(board.scene_navigation == nav and nav.floor_index == 1,"scene switch retains floor selection")
		await click(nav.scene_buttons.entrance)
		nav.floor_picker.select(0)
		nav.floor_picker.item_selected.emit(0)
		var rect: Rect2 = board.get_global_rect()
		expect(Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).encloses(rect),"board fits resolution")
		expect(rect.encloses(board.scene_navigation.strip.get_global_rect()),"scene strip fits resolution")
		expect(rect.encloses(board.scene_navigation.minimap.get_global_rect()),"minimap fits resolution")
		expect(rect.encloses(board.passage_hotspot.get_global_rect()),"passage hotspot fits resolution")
		expect(not board.passage_hotspot.get_global_rect().intersects(board.scene_navigation.minimap.get_global_rect()),"passage is outside minimap")
		expect(not board.passage_hotspot.get_global_rect().intersects(board.scene_navigation.strip.get_global_rect()),"passage is outside scene strip")
		for button in board.buttons:
			if not button.visible: continue
			expect(not button.get_global_rect().intersects(board.scene_navigation.minimap.get_global_rect()),"hotspot not hidden by map")
			expect(not button.get_global_rect().intersects(board.passage_hotspot.get_global_rect()),"passage does not hide existing hotspots")
		await click(board.hotspot_button(0))
		expect(panel.exploration_popup.visible,"existing hotspot still opens")
		panel._close_library_detail()
		board.hotspot_button(0).grab_focus()
		var right := InputEventAction.new()
		right.action = "ui_right"
		right.pressed = true
		get_viewport().push_input(right,true)
		await settle()
		expect(nav.floor_picker.has_focus(),"direction navigation skips locked exit and reaches HUD")
		var profile_path: String = game.progress.path
		game.progress.path = "res://.godot/art-workflow/place-scenes/missing-%d/profile.json" % Time.get_ticks_usec()
		game._campaign_action("scene:atrium")
		await settle()
		expect(not game.last_save_ok and game.journey.current_scene().id == "entrance","failed save rolls back scene change")
		game.progress.path = profile_path
		game._continue_run()
		await settle()
		expect(game.journey.current_scene().id == "entrance" and game.journey.visit.data.viewed.has(memory_id),"resume after failed save keeps scene and investigation")
		# Re-enter through the regular leave flow; fixture victory is not a combat test.
		game.journey.visit.data.guard_won = true
		game.journey.visit.data.reward_taken = true
		game._show_journey()
		await settle()
		expect(not panel.exploration_board.passage_hotspot.disabled,"reward unlocks final exit hotspot")
		await click(panel.exploration_board.passage_hotspot)
		await settle()
		expect(game.journey.data.finished,"last visit leaves through original completion")
		# A single-scene ordinary place exits to the original route map.
		game._begin_region("library")
		game._campaign_action("enter:0")
		await settle()
		expect(panel.exploration_board.passage_hotspot.destination == "路线图","single scene offers route exit")
		expect(panel.exploration_board.scene_navigation.strip.size.x < 400,"single-scene strip is compact")
		game.journey.visit.data.guard_won = true
		game._show_journey()
		await settle()
		expect(panel.exploration_board.passage_hotspot.disabled,"guard victory alone does not unlock exit")
		game.journey.visit.data.reward_taken = true
		game._show_journey()
		await settle()
		await capture("route-exit")
		await click(panel.exploration_board.passage_hotspot)
		expect(game.journey.data.screen == "route" and game.journey.data.step == 1,"exit hotspot returns to next route selection")
		expect(is_instance_valid(panel.station_picker) and panel.station_picker.journey == game.journey,"exit opens latest main's next-station navigation")
		await capture("route-return")
	var layout_probe := Control.new()
	game._begin_region("library","prologue")
	await settle()
	expect(game.campaign_panel.exploration_board.passage_hotspot.destination == "基地","tutorial exit names its actual destination")
	layout_probe.size = Vector2(820,680)
	layout_probe.hide()
	add_child(layout_probe)
	var long_nav := preload("res://scenes/expedition/place_scene_navigation.gd").new()
	for i in range(12):
		long_nav.scenes.append({"id":"scene_%d" % i,"title":"探索场景%d" % (i+1),"position":[0.5,0.5],"floor":i})
	long_nav.current = "scene_11"
	layout_probe.add_child(long_nav)
	await settle()
	expect(long_nav.strip.size.x <= 780,"long scene list is capped to board width")
	expect(long_nav.scene_scroll.get_h_scroll_bar().max_value > long_nav.scene_scroll.get_h_scroll_bar().page,"long list remains horizontally scrollable")
	layout_probe.queue_free()
	print("PLACE_SCENES checks=%d failures=%d" % [checks,failures])
	game.queue_free()
	get_tree().quit(0 if failures == 0 else 1)
