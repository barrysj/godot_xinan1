extends Node
## Original campaign UI, isolated profile. Visual fixtures do not simulate victories.
const RouteMap = preload("res://scenes/expedition/campaign_route_map.gd")
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Presentation = preload("res://game/run/campus_presentation.gd")
var checks := 0
var failures := 0
var game
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPUS_PLAY: "+label)
func settle() -> void:
	for i in range(4): await get_tree().process_frame
func click(control: Control, local: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = control.get_global_transform_with_canvas() * local
		get_viewport().push_input(event,true)
	await settle()
func capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	expect(get_viewport().get_texture().get_image().save_png("res://.godot/campus-play-%s-%dx%d.png" % [label,resolution.x,resolution.y]) == OK,"capture "+label)
func _ready() -> void:
	game = Scene.instantiate()
	game.progress.path = "res://.godot/campus-play-profile-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await settle()
	game.set_process(false)
	game.progress.campaign.routes_acquired = true
	get_window().mode = Window.MODE_WINDOWED
	var capture_mode := "--capture" in OS.get_cmdline_user_args()
	var resolutions := [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)] if capture_mode else [Vector2i(1920,1080)]
	for resolution in resolutions:
		get_window().size = resolution
		await settle()
		game._begin_region("library")
		await settle()
		var panel = game.campaign_panel
		var board = panel.find_child("RouteMap",true,false)
		expect(board != null and board is RouteMap,"main journey uses full atlas")
		expect(board.texture_cache.has("anomaly"),"formal atlas is loaded")
		var future := Presentation.point("library","library",board.layout)
		expect(board.place_at(board.project(future)).is_empty(),"future stops cannot be selected")
		await capture("route",resolution)
		var before := JSON.stringify(game.journey.snapshot())
		await click(board,board.project(Presentation.point("library","gate",board.layout)))
		expect(JSON.stringify(game.journey.snapshot()) == before,"preview does not enter or mutate save")
		panel.action_button("enter:0").pressed.emit()
		await settle()
		expect(game.journey.visit.data.place == "gate" and panel.exploration_board.location_title == "南门","travel enters canonical gate with formal background")
		expect(panel.exploration_board.environment_variant().path == Presentation.background("library","gate"),"gate uses approved backdrop")
		expect(not game.journey.visit.can_leave() and panel.action_button("leave").disabled,"guard and reward still lock exit")
		var mem_index := -1
		for i in range(game.journey.visit.data.hotspots.size()):
			if game.journey.visit.data.hotspots[i].kind == "memory": mem_index = i
		await click(panel.exploration_board.hotspot_button(mem_index),Vector2(59,59))
		expect(panel.exploration_popup.visible,"real hotspot opens shared details")
		expect(panel.action_button("photo") == null,"non-library memory cannot open library photo")
		await capture("gate-detail",resolution)
		var memory_id: String = game.journey.visit.data.hotspots[mem_index].id
		panel.action_button("spot:"+memory_id).pressed.emit()
		await settle()
		expect(game.progress.campaign.memories.has(memory_id),"memory action persists through main controller")
		panel.action_button("visit").pressed.emit()
		game._continue_run()
		await settle()
		expect(game.journey.visit.data.viewed.has(memory_id),"main checkpoint restores investigation")
		# Set up the next-route visual fixture without claiming an actual combat victory.
		game.journey.visit.data.guard_won = true
		game.journey.visit.data.reward_taken = true
		game._campaign_action("leave")
		await settle()
		board = panel.find_child("RouteMap",true,false)
		var snapshot := JSON.stringify(game.journey.snapshot())
		await click(board,board.project(Presentation.point("library","court",board.layout)))
		expect(board.selected == 1 and JSON.stringify(game.journey.snapshot()) == snapshot,"branch map selects second candidate without advancing")
		await capture("branch",resolution)
		panel.action_button("enter:1").pressed.emit()
		await settle()
		expect(game.journey.visit.data.place == "court" and panel.exploration_board.location_title == "品学楼庭院","second branch uses canonical ID and new visual binding")
		await capture("courtyard",resolution)
		var rect: Rect2 = panel.exploration_stage.get_global_rect()
		expect(Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).encloses(rect),"location stage fits viewport")
		await click(panel.exploration_board.hotspot_button(0),Vector2(59,59))
		await settle()
		expect(panel.exploration_stage.get_global_rect().encloses(panel.exploration_popup.get_global_rect()),"details stay inside location stage")
	# Every region/place resolves and restores using the existing checkpoint schema.
	var used := {}
	for region in game.Journey.Regions.IDS:
		for layer in game.Journey.Regions.map_for(region):
			for place in layer:
				game.journey = game.Journey.new()
				game.journey.begin(region,2)
				var step: int = game.Journey.Regions.map_for(region).find(layer)
				game.journey.data.step = step
				for i in range(step): game.journey.data.visited.append(game.journey.data.map[i][0])
				expect(game.journey.enter(layer.find(place),[]),"fixture enters "+region+"/"+place)
				var restored = game.Journey.new()
				expect(restored.restore(game.journey.snapshot()),"original schema restores "+region+"/"+place)
				game.campaign_panel.location(game.journey)
				await settle()
				var environment = game.campaign_panel.exploration_board
				expect(environment.environment_texture != null,"formal location texture "+region+"/"+place)
				used[Presentation.binding(region,place)[0]] = true
				if region == "region_b" and place == "end_b": await capture("laboratory",Vector2i(get_window().size))
				if region == "library" and place == "library": await capture("library",Vector2i(get_window().size))
	expect(used.size() == 12,"all twelve exteriors used by route previews or exploration")
	print("CAMPUS_PLAY checks=%d failures=%d" % [checks,failures])
	game.queue_free()
	get_tree().quit(0 if failures == 0 else 1)
