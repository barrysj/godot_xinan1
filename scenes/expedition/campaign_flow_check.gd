extends RefCounted
var failures = 0
var checks = 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN_FLOW: "+label)

func fight(hub) -> void:
	hub._guard()
	hub.formation = [0,-1,3,2,1,-1]
	hub._build_units()
	hub._start()
	verify(hub.phase == "battle","battle starts")
	for tick in range(8000):
		if hub.screen == "report": break
		hub._process(0.05)
	verify(hub.screen == "report" and hub.result_won,"simulation victory")
	if hub.result_won: hub._after_report()
	verify(hub.journey.data.screen == "reward","victory returns reward")
	hub._campaign_action("reward:0")
	verify(hub.journey.visit.can_leave(),"reward and guard gate")

func run_checks(hub) -> void:
	hub.progress = hub.ProgressModel.new()
	hub.progress.path = "res://.godot/campaign-flow-profile.json"
	hub.set_process(false)
	hub._begin_region("library","prologue")
	fight(hub)
	hub._campaign_action("leave")
	verify(hub.progress.campaign.prologue_done,"prologue settled")
	hub._campaign_action("tutorial")
	verify(hub.progress.campaign.routes_acquired,"tutorial settled")
	for region in ["library","region_b","region_c"]:
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
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-library-flow.png")
			fight(hub)
			if failures > 0:
				hub.get_tree().quit(1)
				return
			hub._campaign_action("leave")
		verify(hub.progress.campaign.terminals.has(region),"terminal earned")
	verify(hub.progress.campaign.characters.has("inventor"),"character permanent")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		hub.get_viewport().get_texture().get_image().save_png("res://.godot/m1-campaign-home.png")
	print("CAMPAIGN_FLOW checks=%d failures=%d" % [checks,failures])
	hub.get_tree().quit(1 if failures else 0)
