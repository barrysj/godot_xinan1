extends Node
const Run = preload("res://game/run/short_run.gd")
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Campaign = preload("res://game/meta/campaign_state.gd")
var checks := 0
var failures := 0
var samples: Array = []
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func _ready() -> void:
	var build = Run.new()
	var before: Dictionary = build.to_dict()
	expect(not build.configure_starting_strategy("unknown") and build.to_dict() == before,"unknown starting style is atomic")
	expect(build.configure_starting_strategy("analysis") and Run.Rewards.active_chains(build) == ["analysis"] and build.code_programs == ["disconnect","repair"],"pursuit preset has a real scanner and core plus rescue")
	var clone = Run.new()
	expect(clone.restore(JSON.parse_string(JSON.stringify(build.to_dict()))) and clone.formation == build.formation,"starter preset reuses existing JSON build")
	expect(Campaign.formation_valid(build.formation.map(func(role): return "" if role == -1 else Run.Content.role_id(role)),[]),"existing base analyst is accepted in persistent formation")
	build.training = {0:1}
	before = build.to_dict()
	expect(not build.configure_starting_strategy("protect") and build.to_dict() == before,"preset cannot reset a grown active build")
	for chain in ["analysis","protect"]:
		var game = Scene.instantiate()
		game.progress.path = "res://.godot/starting-%s-%d.json" % [chain,Time.get_ticks_usec()]
		add_child(game)
		await get_tree().process_frame
		game.storage_ready = false
		game.set_process(false)
		game._home()
		before = game.progress.to_dict()
		game._request_campaign_start("library","prologue")
		expect(game.progress.to_dict() == before,"opening starting choice changes no progress "+chain)
		if "--capture" in OS.get_cmdline_user_args(): await capture(game,"choice-"+chain)
		await choose(game,"strategy:library:prologue:"+chain)
		expect(game.campaign_mode == "prologue" and game.formation.count(-1) == 2,"real first choice prepares four editable actors "+chain)
		expect(game.run.code_programs == (["disconnect","repair"] if chain == "analysis" else ["redirect","repair"]),"actual program loadout matches chosen chain "+chain)
		var frozen: Dictionary = game.progress.active_run.duplicate(true)
		game._continue_run()
		expect(game.progress.active_run == frozen and game.formation == game.run.formation,"starter checkpoint reopens without replacing formation "+chain)
		await fight(game,chain,"prologue",false)
		if failures > 0: break
		await take_first_reward(game)
		game._campaign_action("leave")
		expect(game.progress.campaign.prologue_done,"chosen starter finishes original prologue "+chain)
		expect(game.progress.execute_commission("departure","archivist"),"tutorial unlock transaction")
		game.progress.acknowledge_dispatch_result(game.progress.pending_dispatch_result.id)
		before = game.progress.to_dict()
		expect(not game.progress.settle_region("invalid-duplicate-"+chain,"library",["inventor"],7,["guard","guard","","archer","healer",""]) and game.progress.to_dict() == before,"invalid settlement formation cannot partially unlock "+chain)
		expect(not game.progress.settle_region("invalid-locked-"+chain,"library",[],7,["striker","guard","","inventor","healer",""]) and game.progress.to_dict() == before,"locked settlement owner rejected without mutation "+chain)
		game._request_campaign_start("library","region")
		await choose(game,"strategy:library:region:"+chain)
		await choose(game,"depart")
		expect(game.campaign_mode == "region" and game.journey.visit.data.is_empty(),"actual region choice begins new original journey "+chain)
		if failures > 0: break
		for stage in range(4):
			game._campaign_action("enter:0")
			if stage in [1,2]:
				var recruit: String = (["guard","archer"] if chain == "analysis" else ["striker","archer"])[stage-1]
				expect(game.screen == "recruit","guaranteed recruitment before next battle")
				await choose(game,"join:"+recruit)
			expect(game.run.roster.size() == mini(4,stage+2),"actual starting flow grows two to four")
			expect(Run.Rewards.active_chains(game.run).has(chain),"original expedition has active chosen chain "+chain+str(stage))
			await fight(game,chain,str(stage),true)
			if failures > 0: break
			await take_first_reward(game)
			expect(game.journey.visit.can_leave(),"real reward opens original location exit "+chain+str(stage))
			game._campaign_action("leave")
		if failures > 0: break
		expect(game.progress.campaign.terminals.has("library"),"four real location battles settle original region "+chain)
		if chain == "protect":
			expect(not game.progress.campaign.characters.has("inventor"),"region does not bypass dispatch character unlock")
			expect(game.progress.campaign.formation == game.formation.map(func(role): return "" if role == -1 else Run.Content.role_id(role)),"successful region saves now-permanent full reference formation")
		else:
			expect(game.progress.campaign.formation.has("analyst") and not game.progress.campaign.characters.has("inventor"),"base scanner formation persists without fake story unlock")
		var profile = game.ProgressModel.new()
		profile.path = game.progress.path
		expect(profile.read_save(),"settled profile reads from original disk path "+chain)
		expect(profile.campaign.formation == game.progress.campaign.formation and not profile.load_blocked,"settled reference formation survives original profile on disk "+chain)
		game.queue_free()
		await get_tree().process_frame
	var evidence = FileAccess.open("res://.godot/starting-flow-evidence.json",FileAccess.WRITE)
	if evidence != null:
		evidence.store_string(JSON.stringify({"schema":1,"engine":Engine.get_version_info().string,"growth_rules":2,"policy":"core immediately when legal; repair at hp<=40% and missing>=60; no items; first legal reward; first route branch; original prologue and four library-region locations","samples":samples},"\t"))
	print("STARTING_STRATEGY_SAMPLES ",JSON.stringify(samples))
	print("STARTING_STRATEGY checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func fight(game, chain: String, stage: String, require_core: bool) -> void:
	game._guard()
	var expected: String = "encounter_classroom" if stage == "2" else "encounter_final" if stage == "3" else "encounter_patrol"
	expect(game.run.node.encounter_id == expected,"original location follows escalating pressure "+chain+stage)
	if stage == "2":
		var original: Dictionary = JSON.parse_string(JSON.stringify(game.progress.active_run))
		var saved_node: Dictionary = game.run.node.duplicate(true)
		game.progress.active_run = original
		game._continue_run()
		expect(game.run.node == saved_node,"configured third-stage encounter survives original JSON checkpoint "+chain)
		var bad: Dictionary = original.journey.duplicate(true)
		bad.flow.stops[game.journey.visit.data.place].encounter_id = "missing"
		expect(not preload("res://game/run/campaign_journey.gd").new().restore(bad),"reject unregistered configured encounter "+chain)
		bad = game.journey.snapshot().duplicate(true)
		bad.schema = 1
		expect(not preload("res://game/run/campaign_journey.gd").new().restore(bad),"old development journey requires restart "+chain)
	var pressure_events: Array = []
	var track: Callable = func(event: Dictionary):
		if event.kind in ["enemy_warning","enemy_release"]: pressure_events.append(event.duplicate(true))
	game.presentation_cue.connect(track)
	game._start()
	expect(game.phase == "battle","original prepared starter begins real battle "+chain+stage)
	var core: String = "disconnect" if chain == "analysis" else "redirect"
	var first_core := -1.0
	var warning_captured := false
	var warning_intercepted := false
	for tick in range(1600):
		if game.screen == "report": break
		game.code_panel.pointer = Vector2(-10000,-10000)
		game._process(0.05)
		var sim = game.simulation
		for event in pressure_events:
			if event.kind == "enemy_warning" and sim.elapsed <= float(event.fire_at) and sim.units.any(func(actor): return actor.id == event.actor_id and actor.hp <= 0): warning_intercepted = true
		if game.screen != "battle": break
		if stage == "2" and not warning_captured and not sim.warnings.is_empty():
			warning_captured = true
			if "--capture" in OS.get_cmdline_user_args(): await capture(game,"classroom-warning-"+chain)
		if sim.program_error(core).is_empty():
			game.code_panel._process(0)
			game.code_panel._show_program_preview(core,true)
			game.code_panel._update_hud()
			game.code_panel.preview_release.pressed.emit()
			if first_core < 0 and sim.program_uses.get(core,0) > 0:
				first_core = sim.elapsed
				if "--capture" in OS.get_cmdline_user_args() and stage == "0": await capture(game,"battle-"+chain)
		elif sim.program_error("repair").is_empty() and sim.program_targets("repair").any(func(unit): return unit.hp <= unit.max_hp*0.4 and unit.max_hp-unit.hp >= 60):
			game.code_panel._process(0)
			game.code_panel._show_program_preview("repair",true)
			game.code_panel._update_hud()
			game.code_panel.preview_release.pressed.emit()
	game.presentation_cue.disconnect(track)
	if stage == "2":
		expect(pressure_events.any(func(event): return event.kind == "enemy_warning"),"classroom exposes actual warning "+chain)
		expect(pressure_events.any(func(event): return event.kind == "enemy_release") or warning_intercepted,"classroom releases row attack or dies before its deadline "+chain)
	expect(game.screen == "report" and game.result_won,"real original battle wins without item or code injection "+chain+stage)
	expect(not require_core or first_core >= 0,"main region naturally activates selected core "+chain+stage)
	expect(game.simulation.items.supply == 1 and game.simulation.items.converter == 1,"starter test does not use code items "+chain+stage)
	samples.append({"chain":chain,"stage":stage,"journey_id":game.journey.data.id,"encounter_id":game.run.node.get("encounter_id",""),"power":game.run.node.power,"formation":game.formation.map(func(role): return "" if role == -1 else Run.Content.role_id(role)),"flow_revision":game.journey.data.flow.revision,"first_core":first_core,"elapsed":game.elapsed,"core_casts":game.simulation.program_uses.get(core,0),"repair_casts":game.simulation.program_uses.get("repair",0),"pressure_events":pressure_events})
	game._after_report()
	samples[-1].offered_rewards = game.journey.data.offers.map(func(offer): return offer.id)

func take_first_reward(game) -> void:
	await choose(game,"reward:0")
	if game.journey.data.screen == "reward_owner":
		var pending: Dictionary = game.journey.data.pending_offer
		var owner: int = game.run.roster.filter(func(role): return game.run.reward_owner_available(pending.target,role))[0]
		await choose(game,"reward_owner:"+Run.Content.role_id(owner))

func choose(game, action: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var buttons = game.campaign_panel.find_children("*","Button",true,false).filter(func(button): return button.get_meta("action_id","") == action)
	expect(buttons.size() == 1 and not buttons[0].disabled,"real starting button "+action)
	if buttons.size() != 1: return
	if "--capture" in OS.get_cmdline_user_args():
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = buttons[0].get_global_rect().get_center()
			event.global_position = event.position
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			get_viewport().push_input(event,true)
		await get_tree().process_frame
	else: buttons[0].pressed.emit()

func capture(game, page: String) -> void:
	get_window().mode = Window.MODE_WINDOWED
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		game.queue_redraw()
		game.code_panel._process(0)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		expect(game.get_viewport_rect().encloses(game.get_global_rect()),"starting page fits "+str(size))
		get_viewport().get_texture().get_image().save_png("res://.godot/starting-%s-%dx%d.png" % [page,size.x,size.y])
