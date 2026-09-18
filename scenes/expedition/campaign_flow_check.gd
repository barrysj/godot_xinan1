extends RefCounted
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
var failures = 0
var checks = 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN_FLOW: "+label)

func fight(hub, choose: bool = true) -> void:
	hub._guard()
	hub.formation = [0,-1,3,2,1,-1]
	hub._build_units()
	hub._start()
	verify(hub.phase == "battle","battle starts")
	var elapsed_before = hub.elapsed
	hub._open_pause()
	hub._process(0.5)
	verify(hub.elapsed == elapsed_before,"pause freezes simulation")
	hub._resume_battle()
	for tick in range(8000):
		if hub.screen == "report": break
		hub._process(0.05)
	verify(hub.screen == "report" and hub.result_won,"simulation victory")
	var saved_report = JSON.stringify(hub.report)
	hub._continue_run()
	verify(hub.screen == "report" and JSON.stringify(hub.report) == saved_report,"report restored")
	if hub.result_won: hub._after_report()
	verify(hub.journey.data.screen == "reward","victory returns reward")
	var offers = hub.journey.data.offers.duplicate(true)
	hub._continue_run()
	verify(hub.journey.data.offers == offers,"reward restore stable")
	if choose:
		hub._campaign_action("reward:0")
		verify(hub.journey.visit.can_leave(),"reward and guard gate")

func run_checks(hub) -> void:
	hub.progress = hub.ProgressModel.new()
	hub.progress.path = "user://campaign-flow-test-profile.json" if OS.has_feature("web") else "res://.godot/campaign-flow-profile.json"
	hub.set_process(false)
	if "--exploration-preview" in OS.get_cmdline_user_args():
		hub.progress.complete_prologue()
		hub.progress.complete_tutorial_dispatch()
		hub.set_process(true)
		hub._home()
		return
	if "--library-environment-preview-capture" in OS.get_cmdline_user_args():
		await capture_library_environment_preview(hub)
		hub.get_tree().quit()
		return
	if "--readability-capture" in OS.get_cmdline_user_args():
		await capture_readability(hub)
		hub.get_tree().quit()
		return
	if "--exploration-capture" in OS.get_cmdline_user_args():
		await capture_exploration(hub)
		hub.get_tree().quit()
		return
	if "--library-environment-capture" in OS.get_cmdline_user_args():
		await capture_library_environment(hub)
		hub.get_tree().quit()
		return
	hub._begin_region("library","prologue")
	fight(hub)
	hub._campaign_action("leave")
	verify(hub.progress.campaign.prologue_done,"prologue settled")
	hub._campaign_action("tutorial")
	verify(hub.progress.campaign.routes_acquired,"tutorial settled")
	var order = ["library","region_b","region_c"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--order="):
			order = []
			for index in arg.trim_prefix("--order="): order.append(["library","region_b","region_c"][int(index)])
	for region in order:
		hub._begin_region(region)
		while not hub.campaign_mode.is_empty():
			if hub.journey.visit.data.is_empty(): hub._campaign_action("enter:0")
			var saved = hub.progress.active_run.duplicate(true)
			hub._continue_run()
			verify(saved == hub.progress.active_run,"visit reload stable")
			if hub.journey.visit.data.place == "library":
				hub._hotspot("person")
				verify(not hub.progress.campaign.characters.has("inventor"),"temporary before success")
				hub._show_journey()
				if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
					await RenderingServer.frame_post_draw
					hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-library-flow.png")
			fight(hub)
			if failures > 0:
				hub.get_tree().quit(1)
				return
			hub._campaign_action("leave")
		verify(hub.progress.campaign.terminals.has(region),"terminal earned")
	verify(hub.progress.campaign.characters.has("inventor"),"character permanent")
	verify(hub.progress.dispatch_unlocked("library") and hub.progress.dispatch_unlocked("gym"),"terminal dispatch unlocks")
	hub._begin_region("library","finale")
	for stage in range(3):
		hub._guard()
		hub.formation = [0,-1,3,2,1,-1]
		hub._build_units()
		hub._start()
		for tick in range(8000):
			if hub.screen == "report": break
			hub._process(0.05)
		verify(hub.screen == "report" and hub.result_won,"finale actual victory")
		hub._after_report()
		verify(hub.journey.data.screen == "operation","operation boundary")
		hub._continue_run()
		verify(hub.journey.data.screen == "operation","operation restored")
		hub._campaign_action("operation")
		verify(hub.progress.campaign.finale_stage == stage+1,"operation committed")
	verify(hub.progress.campaign.restored,"permanent campus restoration")
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
			hub.get_window().mode = Window.MODE_WINDOWED
			hub.get_window().size = resolution
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-ending-%dx%d.png" % [resolution.x,resolution.y])
			hub.campaign_mode = "region"
			hub.journey.visit.begin("library",3,[],1)
			hub.journey.data.screen = "visit"
			hub.campaign_panel.location(hub.journey)
			await RenderingServer.frame_post_draw
			hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-library-%dx%d.png" % [resolution.x,resolution.y])
			hub._ending()
	print("CAMPAIGN_FLOW checks=%d failures=%d" % [checks,failures])
	if not OS.has_feature("web"): hub.get_tree().quit(1 if failures else 0)

func capture_readability(hub) -> void:
	hub.get_window().mode = Window.MODE_WINDOWED
	await hub.get_tree().process_frame
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		hub.get_window().size = resolution
		hub._begin_region("library","prologue")
		hub._guard()
		hub.formation = [0,-1,3,2,1,-1]
		hub._build_units()
		hub.queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-readable-battle-%dx%d.png" % [resolution.x,resolution.y])
		hub._start()
		for tick in range(8000):
			if hub.screen == "report": break
			hub._process(0.05)
		hub.queue_redraw()
		await RenderingServer.frame_post_draw
		hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-readable-report-%dx%d.png" % [resolution.x,resolution.y])

func capture_exploration(hub) -> void:
	hub.get_window().mode = Window.MODE_WINDOWED
	await hub.get_tree().process_frame
	hub.progress.complete_prologue()
	hub.progress.complete_tutorial_dispatch()
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		hub.get_window().size = resolution
		await hub.get_tree().process_frame
		await hub.get_tree().process_frame
		hub._home()
		await capture_page(hub,"home",resolution)
		hub._begin_region("library")
		await capture_page(hub,"route",resolution)
		for step in range(3):
			hub._campaign_action("enter:0")
			fight(hub)
			hub._campaign_action("leave")
		hub._campaign_action("enter:0")
		await capture_page(hub,"library",resolution)
		verify(is_instance_valid(hub.campaign_panel.exploration_board),"library uses approved exploration board")
		verify(hub.campaign_panel.exploration_board.buttons.size() == 4,"library exposes four real hotspots")
		verify(hub.campaign_panel.exploration_board.find_children("*","Label",true,false).is_empty(),"hotspots keep names inside click detail only")
		var motion_button = hub.campaign_panel.exploration_board.buttons[0]
		verify(motion_button.tooltip_text.is_empty(),"hotspots do not reveal names through visual tooltips")
		var motion_a: Dictionary = motion_button.motion_sample(0.0)
		var motion_b: Dictionary = motion_button.motion_sample(0.55)
		verify(absf(float(motion_a.offset_y) - float(motion_b.offset_y)) > 0.5,"idle hotspot visibly floats over time")
		verify(absf(float(motion_a.scale) - float(motion_b.scale)) > 0.005,"idle hotspot visibly breathes over time")
		verify(hub.campaign_panel.exploration_board.buttons[0].motion_phase != hub.campaign_panel.exploration_board.buttons[1].motion_phase,"hotspot idle motion uses staggered phases")
		if resolution == Vector2i(1920,1080):
			var stable_hit_rect: Rect2 = motion_button.get_global_rect()
			await capture_page(hub,"library-motion-a",resolution)
			await hub.get_tree().create_timer(0.55).timeout
			await capture_page(hub,"library-motion-b",resolution)
			verify(motion_button.get_global_rect().is_equal_approx(stable_hit_rect),"hotspot animation leaves the click target stationary")
		var memory_index := -1
		for i in range(hub.journey.visit.data.hotspots.size()):
			if hub.journey.visit.data.hotspots[i].kind == "memory": memory_index = i
		verify(memory_index >= 0,"library memory hotspot available")
		await click_control(hub,hub.campaign_panel.exploration_board.hotspot_button(memory_index))
		verify(hub.campaign_panel.exploration_popup.visible,"hotspot click state opens compact detail")
		await capture_page(hub,"library-detail",resolution)
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		Input.parse_input_event(cancel)
		await hub.get_tree().process_frame
		verify(not hub.campaign_panel.exploration_popup.visible,"escape closes hotspot detail")
		verify(hub.campaign_panel.exploration_board.hotspot_button(memory_index).has_focus(),"detail close restores hotspot focus")
		hub._hotspot("person")
		verify(hub.journey.visit.data.viewed.has("person"),"person event uses real visit state")
		await capture_page(hub,"person",resolution)
		hub._show_journey()
		fight(hub,false)
		await capture_page(hub,"rewards",resolution)
		hub._campaign_action("reward:0")
		verify(hub.journey.visit.can_leave(),"reward and guard gate")
		var saved_opened: Dictionary = hub.progress.active_run.duplicate(true)
		hub._continue_run()
		verify(hub.progress.active_run == saved_opened and hub.journey.visit.can_leave(),"opened location restores from checkpoint")
		await capture_page(hub,"opened",resolution)
		hub._campaign_action("leave")
		await capture_page(hub,"settlement",resolution)
	print("EXPLORATION_CAPTURE checks=%d failures=%d" % [checks,failures])

func capture_library_environment(hub) -> void:
	hub.get_window().mode = Window.MODE_WINDOWED
	await hub.get_tree().process_frame
	hub.progress.complete_prologue()
	hub.progress.complete_tutorial_dispatch()
	hub._begin_region("library")
	for step in range(3):
		hub._campaign_action("enter:0")
		fight(hub)
		hub._campaign_action("leave")
	hub._campaign_action("enter:0")
	await hub.get_tree().process_frame
	var board = hub.campaign_panel.exploration_board
	verify(is_instance_valid(board),"environment capture uses real library board")
	verify(board.buttons.size() == 4,"environment capture retains four real hotspots")
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		hub.get_window().size = resolution
		await hub.get_tree().process_frame
		await hub.get_tree().process_frame
		for state in ExplorationSkin.LIBRARY_ENVIRONMENT_STATES:
			for viewpoint in ExplorationSkin.LIBRARY_ENVIRONMENT_VIEWPOINTS:
				verify(board.set_environment_variant(state,viewpoint),"environment variant loads %s/%s" % [state,viewpoint])
				var variant: Dictionary = board.environment_variant()
				verify(variant.get("state") == state and variant.get("viewpoint") == viewpoint,"environment variant reports %s/%s" % [state,viewpoint])
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				var picture = hub.get_viewport().get_texture().get_image()
				verify(picture.get_size() == resolution,"environment capture matches requested viewport")
				picture.save_png("res://.godot/m1-library-environment-%s-%s-%dx%d.png" % [state,viewpoint,resolution.x,resolution.y])
		board.set_environment_variant("anomaly","atrium-down")
	print("LIBRARY_ENVIRONMENT_CAPTURE checks=%d failures=%d" % [checks,failures])

func capture_library_environment_preview(hub) -> void:
	hub.get_window().mode = Window.MODE_WINDOWED
	await hub.get_tree().process_frame
	var panel = hub.campaign_panel
	var board = panel.environment_preview_board
	verify(is_instance_valid(board),"preview opens a real environment board")
	verify(panel.environment_preview_state_buttons.size() == 3,"preview exposes three state buttons")
	verify(panel.environment_preview_viewpoint_buttons.size() == 3,"preview exposes three viewpoint buttons")
	var before: Dictionary = hub.progress.active_run.duplicate(true)
	for state_index in range(panel.environment_preview_state_buttons.size()):
		panel.environment_preview_state_buttons[state_index].pressed.emit()
		for viewpoint_index in range(panel.environment_preview_viewpoint_buttons.size()):
			panel.environment_preview_viewpoint_buttons[viewpoint_index].pressed.emit()
			await RenderingServer.frame_post_draw
			var variant: Dictionary = board.environment_variant()
			verify(variant.get("state") == ExplorationSkin.LIBRARY_ENVIRONMENT_STATES[state_index],"preview switches state from in-game button")
			verify(variant.get("viewpoint") == ExplorationSkin.LIBRARY_ENVIRONMENT_VIEWPOINTS[viewpoint_index],"preview switches viewpoint from in-game button")
			var picture = hub.get_viewport().get_texture().get_image()
			verify(picture.get_size() == Vector2i(1920,1080),"preview capture matches viewport")
			picture.save_png("res://.godot/m1-library-preview-%s-%s-1920x1080.png" % [ExplorationSkin.LIBRARY_ENVIRONMENT_STATES[state_index],ExplorationSkin.LIBRARY_ENVIRONMENT_VIEWPOINTS[viewpoint_index]])
	verify(hub.progress.active_run == before,"preview leaves active run unchanged")
	print("LIBRARY_ENVIRONMENT_PREVIEW_CAPTURE checks=%d failures=%d" % [checks,failures])

func capture_page(hub, label: String, resolution: Vector2i) -> void:
	hub.queue_redraw()
	await hub.get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var picture = hub.get_viewport().get_texture().get_image()
	verify(picture.get_size() == resolution,"capture matches requested viewport")
	picture.save_png("res://.godot/m1-readable-%s-%dx%d.png" % [label,resolution.x,resolution.y])
	print("CAPTURE ",label," actual=",picture.get_size())

func click_control(hub, control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	hub.get_viewport().push_input(motion,true)
	await hub.get_tree().process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		hub.get_viewport().push_input(event,true)
		await hub.get_tree().process_frame
