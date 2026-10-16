extends Node
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Run = preload("res://game/run/short_run.gd")
const Checkpoint = preload("res://game/run/campaign_checkpoint.gd")
var checks := 0
var failures := 0
var samples: Array = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PARTY: "+label)

func _ready() -> void:
	for chain in ["analysis","protect"]:
		var game = Scene.instantiate()
		game.progress.path = "res://.godot/party-%s.json" % chain
		game.progress.campaign.prologue_done = true
		game.progress.campaign.routes_acquired = true
		game.progress.commission_unlocks = ["departure"]
		game.progress.points = 30
		game.progress.write_save()
		add_child(game)
		await get_tree().process_frame
		game.set_process(false)
		game._campaign_action("strategy:library:region:"+chain)
		expect(game.screen == "departure","preparation shown "+chain)
		var selected: Array = game.departure_party.duplicate()
		await get_tree().process_frame
		var starter: Button = game.tutorial_guide.action(game.campaign_panel,"starter:"+selected[0])
		expect(starter.button_pressed,"Selected departure card is highlighted")
		await click_card(starter,true)
		expect(not game.departure_party.has(selected[0]),"Portrait click removes selected character")
		starter = game.tutorial_guide.action(game.campaign_panel,"starter:"+selected[0])
		expect(not starter.button_pressed,"Removed character loses selection highlight")
		await click_card(starter,false)
		expect(game.departure_party.has(selected[0]) and game.departure_party.size() == 2,"Card click adds character back once")
		starter = game.tutorial_guide.action(game.campaign_panel,"starter:"+selected[0])
		expect(starter.button_pressed,"Added character restores whole-card highlight")
		selected = game.departure_party.duplicate()
		game._campaign_action("starter:inventor")
		expect(game.departure_party == selected,"locked character excluded from starting pool")
		game._campaign_action("starter:"+selected[0])
		game._campaign_action("depart")
		expect(game.screen == "departure" and game.progress.active_run.is_empty(),"one actor cannot depart")
		game._campaign_action("starter:"+selected[0])
		if "--capture" in OS.get_cmdline_user_args(): await capture("party-departure-"+chain)
		game._campaign_action("depart")
		expect(game.run.expedition_party and game.run.roster.size() == 2 and game.formation.count(-1) == 4,"actual run owns exactly two actors")
		expect(game._deployment_roster() == game.run.roster and game._deployment_limit() == 2,"no hidden reserves")
		var saved: Dictionary = JSON.parse_string(JSON.stringify(game.progress.active_run))
		expect(not Checkpoint.decode(saved).is_empty(),"two-actor checkpoint survives JSON")
		var broken: Dictionary = saved.duplicate(true)
		broken.build.roster.append("inventor")
		expect(Checkpoint.decode(broken).is_empty(),"reject locked or over-count saved roster")
		expect(game.progress.execute_commission("inventor_contact","liaison"),"permanent character unlock")
		game.progress.acknowledge_dispatch_result(game.progress.pending_dispatch_result.id)
		game._continue_run()
		expect(not game.run.eligible_characters.has("inventor"),"active run keeps frozen eligibility after base unlock")
		for step in range(4):
			game._campaign_action("enter:0")
			if step in [1,2]:
				expect(game.screen == "recruit","guaranteed meeting before battle "+str(step))
				game._guard()
				expect(game.screen == "recruit","guard cannot bypass meeting")
				var count: int = game.run.roster.size()
				game._campaign_action("join:inventor")
				game._campaign_action("join:"+Run.Content.role_id(game.run.roster[0]))
				expect(game.run.roster.size() == count,"locked and duplicate join rejected")
				game._continue_run()
				expect(game.screen == "recruit" and game.run.roster.size() == count,"pending meeting resumes")
				var recruit: String = (["guard","archer"] if chain == "analysis" else ["striker","archer"])[step-1]
				if "--capture" in OS.get_cmdline_user_args(): await capture("party-meeting-%s-%d" % [chain,step])
				var path: String = game.progress.path
				game.progress.path = "res://.godot/missing-party-folder/profile.json"
				game._campaign_action("join:"+recruit)
				expect(not game.last_save_ok and game.run.roster.size() == count,"failed join save rolls back")
				game.progress.path = path
				game._continue_run()
				game._campaign_action("join:"+recruit)
				expect(game.run.roster.size() == count+1 and game.screen == "campaign","chosen companion joins once")
				game._campaign_action("join:"+recruit)
				expect(game.run.roster.size() == count+1,"repeated join action cannot add another")
			expect(game.run.roster.size() == mini(4,step+2),"party progression 2,3,4,4")
			expect(not Run.Rewards.for_build(game.run).any(func(offer): return offer.operation == "recruit"),"battle rewards do not bypass meetings")
			game._guard()
			if step == 0:
				var valid_formation: Array = game.formation.duplicate()
				game.formation[game.formation.find(game.run.roster[0])] = Run.Content.role_index("inventor")
				game._start()
				expect(game.phase == "prepare","undeclared actor cannot start battle")
				game.formation = valid_formation
				game._guard()
			if "--capture" in OS.get_cmdline_user_args(): await capture("party-formation-%s-%d" % [chain,step])
			game._start()
			expect(game.phase == "battle" and game._living(0).size() == mini(4,step+2),"real combat uses current team")
			var core: String = "disconnect" if chain == "analysis" else "redirect"
			for tick in range(2400):
				if game.screen == "report": break
				game.code_panel.pointer = Vector2(-10000,-10000)
				game._process(0.05)
				if game.screen != "battle": break
				var sim = game.simulation
				if sim.program_error(core).is_empty(): sim.cast_program(core)
				elif sim.program_error("repair").is_empty() and sim.program_targets("repair").any(func(actor): return actor.hp < actor.max_hp*0.4): sim.cast_program("repair")
			samples.append({"chain":chain,"step":step,"team":game.run.roster.size(),"won":game.result_won,"seconds":game.elapsed,"power":game.run.node.power})
			expect(game.screen == "report" and game.result_won,"real battle victory "+chain+str(step))
			expect(game.report_details.rows.filter(func(row): return row.side == 0).size() == mini(4,step+2),"detailed report follows current party size")
			expect(not Checkpoint.decode(JSON.parse_string(JSON.stringify(game.progress.active_run))).is_empty(),"variable-party detailed report survives campaign checkpoint")
			if "--capture" in OS.get_cmdline_user_args() and step == 0: await capture("party-report-"+chain)
			if not game.result_won: break
			game._after_report()
			game._campaign_action("reward:0")
			if game.journey.data.screen == "reward_owner":
				var target: String = game.journey.data.pending_offer.target
				var owners: Array = game.run.roster.filter(func(role): return game.run.reward_owner_available(target,role))
				expect(not owners.is_empty(),"offered enhancement has an owner")
				if not owners.is_empty(): game._campaign_action("reward_owner:"+Run.Content.role_id(owners[0]))
			expect(game.journey.visit.can_leave(),"normal victory and reward unlock exit")
			game._campaign_action("leave")
		expect(game.progress.campaign.terminals.has("library"),"region completes through all four actual battles")
		game._campaign_action("strategy:library:region:protect")
		game._campaign_action("starter:healer")
		game._campaign_action("starter:inventor")
		game._campaign_action("depart")
		expect(game.run.eligible_characters.has("inventor") and game.run.roster.has(Run.Content.role_index("inventor")),"next run can select dispatch-unlocked actor")
		game.progress.campaign.terminals = ["library","region_b","region_c"]
		game._begin_region("library","finale","analysis")
		expect(game.campaign_mode == "finale" and not game.run.expedition_party and game.formation.count(-1) == 2 and game._deployment_limit() == 4,"finale remains a four-actor start")
		game.queue_free()
		await get_tree().process_frame
	print("PARTY_SAMPLES ",JSON.stringify(samples))
	print("PARTY checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture(id: String) -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920,1080)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/"+id+".png")

func click_card(button: Button, portrait: bool) -> void:
	var bounds := button.get_global_rect()
	var at := bounds.position+Vector2(bounds.size.x/2,bounds.size.y*(0.25 if portrait else 0.75))
	get_viewport().warp_mouse(at)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
	await get_tree().process_frame
	await get_tree().process_frame
