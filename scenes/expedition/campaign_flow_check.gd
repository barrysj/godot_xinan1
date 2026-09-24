extends RefCounted
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
const CampusLocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")
const CampaignBoard = preload("res://scenes/expedition/campaign_board.gd")
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
		if hub.journey.data.screen == "reward_owner":
			var owner: int = hub.run.roster[0]
			if hub.journey.data.pending_offer.target in ["lens", "backup"]:
				owner = hub.run.roster.filter(func(role): return hub.run.combat_gear_available(role))[0]
			hub._campaign_action("reward_owner:"+hub.RunModel.Content.role_id(owner))
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
	if "--hub-icon-capture" in OS.get_cmdline_user_args():
		await capture_hub_icons(hub)
		hub.get_tree().quit(1 if failures else 0)
		return
	if "--campus-environment-preview-capture" in OS.get_cmdline_user_args():
		await capture_campus_environment_preview(hub)
		hub.get_tree().quit(1 if failures else 0)
		return
	if "--readability-capture" in OS.get_cmdline_user_args():
		await capture_readability(hub)
		hub.get_tree().quit()
		return
	if "--exploration-capture" in OS.get_cmdline_user_args():
		await capture_exploration(hub)
		hub.get_tree().quit()
		return
	if "--memory-terminal-capture" in OS.get_cmdline_user_args():
		await capture_memory_terminals(hub)
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

func verify_hub_icons(hub) -> void:
	var expected := {
		"memories": "res://assets/art/ui/m1_campus_hub/runtime/icon_memory.png",
		"growth": "res://assets/art/ui/m1_campus_hub/runtime/icon_growth.png",
		"dispatch": "res://assets/art/ui/m1_campus_hub/runtime/icon_dispatch.png",
		"codex": "res://assets/art/ui/m1_campus_hub/runtime/icon_codex.png",
	}
	for id in expected:
		var item: Button = hub.campaign_panel.action_button(id)
		verify(is_instance_valid(item),"hub exposes %s action button" % id)
		if is_instance_valid(item):
			verify(item.icon != null and item.icon.get_size() == Vector2(64,64),"hub %s loads approved icon pixels" % id)
			verify(item.get_meta("icon_asset_path","") == expected[id],"hub %s maps approved icon path" % id)
			verify(item.get_theme_constant("icon_max_width") == 36,"hub %s icon stays at UI scale" % id)
	var resource_status: Node = hub.campaign_panel.find_child("ResourceStatus",true,false)
	verify(is_instance_valid(resource_status),"hub exposes resource status card")
	if is_instance_valid(resource_status):
		var icons: Array[Node] = resource_status.find_children("*","TextureRect",true,false)
		var resource_icon: TextureRect = null
		if icons.size() == 1: resource_icon = icons[0] as TextureRect
		verify(resource_icon != null and resource_icon.texture != null and resource_icon.texture.get_size() == Vector2(64,64),"resource status loads approved icon pixels")
		verify(resource_icon != null and resource_icon.get_meta("icon_asset_path","") == "res://assets/art/ui/m1_campus_hub/runtime/icon_resource.png","resource status maps approved icon path")

func capture_hub_icons(hub) -> void:
	hub.get_window().mode = Window.MODE_WINDOWED
	await hub.get_tree().process_frame
	hub.progress.complete_prologue()
	hub.progress.complete_tutorial_dispatch()
	hub.progress.points = 42
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200),Vector2i(1280,720)]:
		hub.get_window().size = resolution
		await hub.get_tree().process_frame
		hub._home()
		verify_hub_icons(hub)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		verify_hub_layout(hub)
		var picture: Image = hub.get_viewport().get_texture().get_image()
		verify(picture.get_size() == resolution,"hub icon capture matches requested viewport")
		picture.save_png("res://.godot/m1-campus-hub-icons-%dx%d.png" % [resolution.x,resolution.y])
		if resolution == Vector2i(1920,1080):
			var growth: Button = hub.campaign_panel.action_button("growth")
			growth.grab_focus()
			await RenderingServer.frame_post_draw
			hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-campus-hub-icons-focus-1920x1080.png")
			growth.release_focus()
	await verify_hub_overlays(hub)
	hub._campaign_action("codex")
	verify(is_instance_valid(hub.codex_panel),"hub codex icon opens existing codex")
	if is_instance_valid(hub.codex_panel): hub.codex_panel.close_guide()
	print("HUB_ICON_CAPTURE checks=%d failures=%d" % [checks,failures])

func verify_hub_layout(hub) -> void:
	var panel = hub.campaign_panel
	var background: TextureRect = panel.find_child("HomeBackground",true,false)
	verify(background != null and background.texture != null and background.texture.get_size() == Vector2(3840,2160),"home loads approved 4K background at full resolution")
	verify(panel.action_button("reset_profile") == null,"reset is absent from home")
	var mission: Control = panel.find_child("HomeMission",true,false)
	verify(mission.size.y < 320,"default mission remains compact")
	var rects: Array[Rect2] = []
	for id in ["choose_region","growth","dispatch","memories","codex","hub_menu"]:
		var item: Button = panel.action_button(id)
		var rect := item.get_global_rect()
		verify(panel.get_global_rect().encloses(rect),"home button in bounds: "+id)
		for previous in rects: verify(not previous.intersects(rect),"home buttons do not overlap")
		rects.append(rect)
		verify(item.get_theme_stylebox("normal") is StyleBoxFlat,"home uses native matte geometry")
	verify(is_equal_approx(rects[1].position.y,rects[4].position.y),"four facility cards share one row")
	var version = hub.get_node_or_null("/root/GGT_Transitions/Version")
	verify(version == null or not version.visible,"debug version does not cover mission")

func verify_hub_overlays(hub) -> void:
	var panel = hub.campaign_panel
	var explore: Button = panel.action_button("choose_region")
	explore.grab_focus()
	explore.pressed.emit()
	await hub.get_tree().process_frame
	verify(is_instance_valid(panel.home_overlay),"explore opens region overlay")
	verify(panel.action_button("region:library") != null,"region choice reachable")
	verify(explore.focus_mode == Control.FOCUS_NONE,"background excluded from modal focus")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	hub._input(cancel)
	await hub.get_tree().process_frame
	verify(not is_instance_valid(panel.home_overlay) and explore.has_focus(),"cancel restores explore focus")
	var menu: Button = panel.action_button("hub_menu")
	menu.grab_focus()
	menu.pressed.emit()
	await hub.get_tree().process_frame
	verify(panel.action_button("reset_profile") != null,"reset available only inside menu")
	await RenderingServer.frame_post_draw
	hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-campus-hub-menu.png")
	panel.action_button("reset_profile").pressed.emit()
	verify(hub.reset_pending and panel.action_button("reset_confirm") != null,"menu reset requires confirmation")
	hub._input(cancel)
	verify(not hub.reset_pending and panel.home_root.visible,"cancel reset returns home")

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

func capture_memory_terminals(hub) -> void:
	hub.get_window().mode = Window.MODE_WINDOWED
	await hub.get_tree().process_frame
	hub.progress.complete_prologue()
	hub.progress.complete_tutorial_dispatch()
	hub.progress.campaign.terminals = ["library","region_b","region_c"]
	hub.progress.campaign.finale_stage = 0
	hub.progress.campaign.restored = false
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		hub.get_window().size = resolution
		await hub.get_tree().process_frame
		hub._home()
		await capture_page(hub,"memory-terminal-home",resolution)
		hub._begin_region("library","finale")
		verify(hub.campaign_mode == "finale","finale terminal display enters finale mode")
		verify(count_memory_terminal_views(hub.campaign_panel) == 3,"finale terminal display has three terminal views")
		await capture_page(hub,"memory-terminal-finale",resolution)
	print("MEMORY_TERMINAL_CAPTURE checks=%d failures=%d" % [checks,failures])

func count_memory_terminal_views(node: Node) -> int:
	var result := 1 if node is MemoryTerminalView else 0
	for child in node.get_children():
		result += count_memory_terminal_views(child)
	return result

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

func capture_campus_environment_preview(hub) -> void:
	hub.get_window().mode = Window.MODE_WINDOWED
	await hub.get_tree().process_frame
	var panel = hub.campaign_panel
	verify(is_instance_valid(panel.campus_preview_image),"campus preview opens in game")
	verify(panel.campus_preview_state_buttons.size() == 2,"campus preview has two state buttons")
	var before: Dictionary = hub.progress.active_run.duplicate(true)
	for location in CampusLocationSkin.LOCATIONS:
		for state in CampusLocationSkin.STATES:
			var path := CampusLocationSkin.path(location.id,state)
			verify(FileAccess.file_exists(path),"approved campus background exists %s/%s" % [location.id,state])
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			verify(image != null and image.get_size() == Vector2i(3840,2160),"approved campus background is 4K %s/%s" % [location.id,state])
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		hub.get_window().size = resolution
		await hub.get_tree().process_frame
		for location_index in range(CampusLocationSkin.LOCATIONS.size()):
			panel.campus_preview_selector.select(location_index)
			panel.campus_preview_selector.item_selected.emit(location_index)
			for state_index in range(CampusLocationSkin.STATES.size()):
				panel.campus_preview_state_buttons[state_index].pressed.emit()
				verify(panel.campus_preview_image.texture != null,"campus preview loads selected texture")
				await RenderingServer.frame_post_draw
				if location_index in [0,5,10,11]:
					var picture = hub.get_viewport().get_texture().get_image()
					verify(picture.get_size() == resolution,"campus preview matches viewport")
					picture.save_png("res://.godot/m1-campus-preview-%s-%s-%dx%d.png" % [CampusLocationSkin.LOCATIONS[location_index].id,CampusLocationSkin.STATES[state_index],resolution.x,resolution.y])
	verify(hub.progress.active_run == before,"campus preview leaves active run unchanged")
	hub._campaign_action("campus_preview_base")
	verify(hub.progress.active_run == before,"leaving campus preview does not checkpoint")
	hub.journey.begin("library",0)
	hub.journey.enter(0,[])
	hub.campaign_panel.location(hub.journey,true)
	await RenderingServer.frame_post_draw
	var gate_board: Control
	for child in hub.campaign_panel.column.get_children():
		if child is CampaignBoard: gate_board = child
	verify(gate_board != null and gate_board.location_background != null,"south gate gameplay uses approved anomaly background")
	var gate_picture = hub.get_viewport().get_texture().get_image()
	gate_picture.save_png("res://.godot/m1-campus-gate-gameplay-1920x1200.png")
	print("CAMPUS_ENVIRONMENT_PREVIEW_CAPTURE checks=%d failures=%d" % [checks,failures])

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
