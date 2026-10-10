extends Node
## Original offer generation, owner UI and checkpoint continuity; isolated save only.
const Run = preload("res://game/run/short_run.gd")
const Scene = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func has_offer(pool: Array, target: String) -> bool:
	return pool.any(func(offer): return offer.operation == "combat" and offer.target == target)

func _ready() -> void:
	var build = Run.new()
	build.roster.assign([0,1,2,3,4,5,6])
	build.code_programs = ["disconnect","repair"]
	var pool: Array = Run.Rewards.for_build(build)
	expect(not has_offer(pool,"buffer") and not has_offer(pool,"isolation"), "pursuit loadout cannot offer absent recoil modifiers")
	build.code_programs = ["redirect","repair"]
	pool = Run.Rewards.for_build(build)
	expect(has_offer(pool,"buffer") and has_offer(pool,"isolation"), "equipped recoil opens both modifiers")
	var historical: Dictionary = pool.filter(func(offer): return offer.get("target") == "buffer")[0].duplicate(true)
	build.inventory = {"shoe":0,"badge":1,"ribbon":2}
	build.combat_rewards.assign([{"target":"lens","owner":"striker"},{"target":"backup","owner":"inventor"}])
	build.roster.assign([0,1,2,3,4])
	pool = Run.Rewards.for_build(build)
	expect(not has_offer(pool,"lens") and not has_offer(pool,"backup"), "all occupied equipment slots exclude unusable equipment rewards")
	for role in build.roster: expect(not build.combat_gear_available(role), "shared owner legality for occupied role "+str(role))
	build.combat_rewards.clear()
	pool = Run.Rewards.for_build(build)
	expect(has_offer(pool,"lens") and has_offer(pool,"backup"), "one free candidate permits equipment selection")
	build.roster.assign([0])
	build.inventory = {"shoe":0}
	pool = Run.Rewards.for_build(build)
	expect(not has_offer(pool,"cover") and not has_offer(pool,"verify") and not has_offer(pool,"pierce"), "missing partners and dedicated characters do not offer inert upgrades")
	build.roster.assign([0,0])
	expect(Run.Rewards.tag_count(build.roster,"protect") == 1, "duplicate identity cannot activate a tag requirement")
	build.roster.assign([0,2])
	pool = Run.Rewards.for_build(build)
	expect(has_offer(pool,"cover"), "reserve partner counts as an available construction option")
	build.roster.assign([6])
	pool = Run.Rewards.for_build(build)
	expect(not has_offer(pool,"verify"), "analyst alone has no enhanced synergy verification")
	build.roster.assign([6,1])
	pool = Run.Rewards.for_build(build)
	expect(has_offer(pool,"verify") and has_offer(pool,"pierce"), "available analysis pair and archer allow dedicated options")
	build.roster.assign([])
	pool = Run.Rewards.for_build(build)
	expect(not pool.any(func(offer): return offer.operation == "combat"), "empty roster has no combat upgrade candidates")
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/reward-eligibility-%d.json" % Time.get_ticks_usec()
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
	var offers: Array = game.journey.data.offers.duplicate(true)
	expect(offers.size() == 3 and not has_offer(offers,"buffer") and not has_offer(offers,"isolation"), "actual campaign victory draws three current-build legal candidates")
	expect(offers.all(func(offer): return Run.Rewards.for_build(game.run).any(func(candidate): return candidate.id == offer.id)), "actual campaign offers belong to filtered pool")
	var saved = game.CampaignSave.decode(game.progress.active_run)
	expect(not saved.is_empty() and saved.journey.data.offers == offers, "original checkpoint preserves candidates")
	game._victory()
	expect(game.journey.data.offers == offers, "reopening victory cannot reroll")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game)
	# A prior checkpoint's already offered program reward remains reviewable after a loadout change.
	game.journey.data.offers = [historical]
	game.journey.data.screen = "reward"
	game.journey.visit.data.reward_taken = false
	expect(game._save_campaign(), "historical candidate checkpoint saves")
	saved = game.CampaignSave.decode(game.progress.active_run)
	expect(not saved.is_empty() and saved.journey.data.offers[0] == historical, "restore does not retroactively filter frozen candidate")
	game.run = saved.build
	game.journey = saved.journey
	game._show_journey()
	await get_tree().process_frame
	await choose(game,"reward:0")
	expect(game.run.combat_rewards.any(func(reward): return reward.target == "buffer") and game.journey.visit.data.reward_taken, "actual button can claim an already frozen program reward")
	print("REWARD_ELIGIBILITY checks=%d failures=%d" % [checks,failures])
	game.queue_free()
	get_tree().quit(0 if failures == 0 else 1)

func choose(game, action: String) -> void:
	var buttons = game.campaign_panel.find_children("*","Button",true,false).filter(func(button): return button.get_meta("action_id","") == action)
	expect(buttons.size() == 1, "actual reward button")
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

func capture(game) -> void:
	get_window().mode = Window.MODE_WINDOWED
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		expect(game.campaign_panel.get_viewport_rect().encloses(game.campaign_panel.get_global_rect()), "reward panel fits "+str(size))
		get_viewport().get_texture().get_image().save_png("res://.godot/reward-eligibility-%dx%d.png" % [size.x,size.y])
