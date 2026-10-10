extends Node
const Run = preload("res://game/run/short_run.gd")
const Scene = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func _ready() -> void:
	var build = Run.new()
	build.roster.assign([0,1,2,3,6])
	build.formation = [0,3,-1,6,1,-1]
	build.code_programs = ["disconnect","repair"]
	var first_legal := true
	var second_recruit := true
	var pierce_seen := false
	for seed_value in 128:
		var rng = RandomNumberGenerator.new()
		rng.seed = seed_value
		var offers: Array = Run.Rewards.draw_for_build(build,rng,1)
		first_legal = first_legal and offers.size() == 3 and offers[0].target in ["lens","verify"] and offers[1].offer_slot == "general" and offers.all(func(entry): return entry.target not in ["pierce","buffer","isolation"]) and unique(offers) and offers.all(func(entry): return Run.Rewards.valid_snapshot(entry))
		rng.seed = seed_value
		offers = Run.Rewards.draw_for_build(build,rng,2)
		second_recruit = second_recruit and offers[2].operation == "recruit" and offers[2].target == "morning"
		pierce_seen = pierce_seen or offers[0].target == "pierce"
	expect(first_legal, "first pursuit offers preserve chain/general/alternative and gate advanced modifiers")
	expect(second_recruit and pierce_seen, "second eligible choice guarantees adaptive reserve presentation and opens pierce")
	var rng = RandomNumberGenerator.new()
	rng.seed = 31
	var a: Array = Run.Rewards.draw_for_build(build,rng,2)
	rng.seed = 31
	var b: Array = Run.Rewards.draw_for_build(build,rng,2)
	expect(a == b, "fixed seed reproduces weighted offer snapshots")
	rng.seed = 9
	build.draw_rewards(rng)
	expect(build.reward_offer_count == 1, "counter advances only when a new offer page is generated")
	build.candidate_recruit_shown = false
	var second: Array = build.draw_rewards(rng)
	expect(build.reward_offer_count == 2 and build.candidate_recruit_shown and second[2].target == "morning", "reserve presentation flag is saved without forcing acceptance")
	expect(not build.roster.has(Run.Content.role_index("morning")), "showing reserve does not recruit or permanently unlock it")
	var clone = Run.new()
	var restore_ok: bool = clone.restore(JSON.parse_string(JSON.stringify(build.to_dict())))
	expect(restore_ok and clone.reward_offer_count == 2 and clone.candidate_recruit_shown, "counter and presentation flag survive original codec")
	var broken: Dictionary = build.to_dict()
	broken.reward_offer_count = 1.5
	expect(not clone.restore(broken), "fractional counter rejected")
	broken = build.to_dict()
	broken.candidate_recruit_shown = 1
	expect(not clone.restore(broken), "nonboolean presentation flag rejected")
	broken = build.to_dict()
	broken.erase("reward_offer_count")
	broken.erase("candidate_recruit_shown")
	expect(clone.restore(broken) and clone.reward_offer_count == 0 and not clone.candidate_recruit_shown, "earlier schema-eight snapshot gets safe defaults")
	# Strongly unequal within-chain weights must not change which chain gets the A slot.
	build.roster.assign([0,1,2,3,4,5,6])
	build.formation = [0,2,-1,6,1,-1]
	build.code_programs = ["disconnect","redirect"]
	var cover = Run.Rewards.find_combat("cover")
	var previous: int = cover.reward_weight
	cover.reward_weight = 99
	var counts := {"analysis":0,"protect":0}
	var valid_general := true
	for seed_value in 1024:
		rng.seed = seed_value
		var offers: Array = Run.Rewards.draw_for_build(build,rng,2,false)
		counts[Run.Rewards.entry_chain(offers[0])] += 1
		valid_general = valid_general and Run.Rewards.entry_chain(offers[1]) == "general" and not offers.any(func(entry): return entry.operation == "recruit") and unique(offers)
	cover.reward_weight = previous
	expect(counts.analysis > 400 and counts.analysis < 624 and counts.protect > 400 and counts.protect < 624, "chain-first selection stays balanced despite unequal content weights")
	expect(valid_general, "dual-chain general slot remains general and campaign excludes story recruits")
	print("REWARD_SLOT_CHAIN_COUNTS ",counts," seeds=1024 weights=analysis_normal/protect_cover99")
	build.formation = [0,-1,-1,-1,-1,-1]
	rng.seed = 11
	var unformed: Array = Run.Rewards.draw_for_build(build,rng,1,false)
	expect(unformed[0].offer_slot == "general", "unformed squad does not claim a chain slot")
	build.roster.assign([0])
	build.formation = [0,-1,-1,-1,-1,-1]
	build.inventory = {"shoe":0,"badge":-1,"ribbon":-1}
	build.training = {0:2}
	build.code_supplies = {"supply":3,"converter":3}
	build.code_programs = ["disconnect","repair"]
	build.combat_rewards.clear()
	var exhausted: Array = build.draw_rewards(rng,false)
	expect(exhausted.is_empty() and build.reward_offer_count == 2, "empty legal pool is not filled with unusable choices or counted")
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/reward-slots-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.run.roster.assign([0,1,2,3,4,5,6])
	game.formation = [0,3,-1,6,1,-1]
	game.run.formation = game.formation.duplicate()
	game.run.code_programs = ["disconnect","repair"]
	game.journey.data.erase("offers")
	game._victory()
	var frozen: Array = game.journey.data.offers.duplicate(true)
	expect(frozen.size() == 3 and frozen[0].offer_slot == "chain" and game.run.reward_offer_count == 1, "actual original victory generates first directional offer page")
	expect(frozen.all(func(entry): return entry.target not in ["pierce","buffer"]), "actual first campaign offer respects advanced gate")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"first")
	game._continue_run()
	expect(game.journey.data.offers == frozen and game.run.reward_offer_count == 1, "reloading existing campaign page neither rerolls nor advances counter")
	game._victory()
	expect(game.journey.data.offers == frozen and game.run.reward_offer_count == 1, "reopening same victory preserves frozen choice")
	await choose(game,"reward:1")
	if game.journey.data.screen == "reward_owner":
		var pending: Dictionary = game.journey.data.pending_offer
		var owner: int = game.run.roster.filter(func(role): return game.run.reward_owner_available(pending.target,role))[0]
		await choose(game,"reward_owner:"+Run.Content.role_id(owner))
	expect(game.journey.visit.data.reward_taken, "actual general choice is claimable through original UI")
	game.journey.data.erase("offers")
	game.journey.visit.data.reward_taken = false
	game._victory()
	expect(game.run.reward_offer_count == 2 and game.journey.data.offers.size() == 3, "next original reward page uses second-offer rules")
	expect(not game.journey.data.offers.any(func(entry): return entry.operation == "recruit"), "campaign reward preserves narrative recruitment boundary")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"second")
	print("REWARD_SLOTS checks=%d failures=%d" % [checks,failures])
	game.queue_free()
	get_tree().quit(0 if failures == 0 else 1)

func unique(offers: Array) -> bool:
	var ids: Array = []
	for entry in offers:
		if ids.has(entry.id): return false
		ids.append(entry.id)
	return true

func choose(game, action: String) -> void:
	var buttons = game.campaign_panel.find_children("*","Button",true,false).filter(func(button): return button.get_meta("action_id","") == action)
	expect(buttons.size() == 1 and not buttons[0].disabled, "real reward button "+action)
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
	else:
		buttons[0].pressed.emit()
		await get_tree().process_frame

func capture(game, page: String) -> void:
	get_window().mode = Window.MODE_WINDOWED
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		expect(game.campaign_panel.get_viewport_rect().encloses(game.campaign_panel.get_global_rect()), "reward page fits "+str(size))
		get_viewport().get_texture().get_image().save_png("res://.godot/reward-slots-%s-%dx%d.png" % [page,size.x,size.y])
