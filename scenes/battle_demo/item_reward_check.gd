extends Node
const Run = preload("res://game/run/short_run.gd")
const Journey = preload("res://game/run/campaign_journey.gd")
const Scene = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func full_build():
	var build = Run.new()
	build.roster.assign([0,1,2,3,4,5,6])
	build.inventory = {"shoe":0,"badge":1,"ribbon":2}
	for definition in preload("res://resources/combat/manifest.tres").rewards:
		var entry := {"id":"combat_"+definition.id,"title":definition.display_name,"description":definition.description,"operation":"combat","target":definition.id,"amount":1}
		var owner: String = {"lens":"striker","backup":"inventor","training":"analyst"}.get(definition.id,"")
		expect(build.apply_combat_reward(entry,owner),"complete legal growth fixture "+definition.id)
	for role in build.roster: build.training[role] = 1 if role == 6 else 2
	build.code_supplies = {"supply":3,"converter":3,"shield":0,"revive":0}
	return build

func _ready() -> void:
	expect(Run.Content.validate().is_empty(),"registered item reward resources validate")
	var supply: Dictionary = Run.Rewards.find("code_supply")
	var converter: Dictionary = Run.Rewards.find("code_converter")
	expect(Run.Rewards.valid_snapshot(supply) and Run.Rewards.valid_snapshot(converter),"both item snapshots reference original registered code items")
	var bad: Dictionary = supply.duplicate(true)
	bad.amount = 2
	expect(not Run.Rewards.valid_snapshot(bad),"bulk item grants are not accepted as frozen reward")
	bad = supply.duplicate(true)
	bad.target = "converter"
	expect(not Run.Rewards.valid_snapshot(bad),"item identity and target must match")
	var definition = Run.Content.MANIFEST.rewards.filter(func(entry): return entry.id == "code_supply")[0]
	var saved_id: String = definition.code_item_id
	definition.code_item_id = "unknown"
	expect(not Run.Content.validate().is_empty(),"unknown code item resource rejected")
	definition.code_item_id = saved_id
	var item = Run.CodeCatalog.item("supply")
	var saved_starting_count: int = item.starting_count
	item.starting_count = Run.CodeCatalog.STOCK_CAP+1
	expect(not Run.CodeCatalog.validate().is_empty(),"initial stock cannot exceed shared capacity")
	item.starting_count = saved_starting_count
	var rng = RandomNumberGenerator.new()
	var fresh = Run.new()
	var no_fallback := true
	var supply_seen := false
	for seed_value in 128:
		rng.seed = seed_value
		var offers: Array = fresh.draw_rewards(rng,false)
		no_fallback = no_fallback and not offers.any(func(entry): return entry.id == "code_converter")
		supply_seen = supply_seen or offers.any(func(entry): return entry.id == "code_supply")
	expect(no_fallback and supply_seen,"supply competes normally while converter remains depletion fallback")
	fresh.growth_rules = 1
	expect(not Run.Rewards.for_build(fresh).any(func(entry): return entry.operation == "item"),"legacy growth offers preserve old content")
	var build = full_build()
	expect(Run.Rewards.for_build(build).is_empty(),"complete growth and full stocks exhaust only legal content")
	build.code_supplies = {"supply":2,"converter":2,"shield":0,"revive":0}
	rng.seed = 19
	var offers: Array = build.draw_rewards(rng,false)
	expect(offers.size() == 2 and offers.map(func(entry): return entry.id).has("code_supply") and offers.map(func(entry): return entry.id).has("code_converter"),"depleted pool presents two distinct usable consumables")
	expect(build.apply_reward(supply) and build.code_supplies.supply == 3,"single item reward reaches capacity")
	var stock_before: Dictionary = build.code_supplies.duplicate()
	expect(not build.apply_reward(supply) and build.code_supplies == stock_before,"full inventory rejects reward without partial mutation")
	expect(build.apply_reward(converter) and build.code_supplies.converter == 3,"converter reuses original persisted stock")
	var clone = Run.new()
	expect(clone.restore(JSON.parse_string(JSON.stringify(build.to_dict()))) and clone.code_supplies == build.code_supplies,"reward stock survives real JSON codec")
	build.generate(122)
	expect(build.choose(0) and build.rewards_exhausted and build.offers().is_empty(),"original short route freezes legitimate exhaustion")
	var frozen: Dictionary = build.to_dict()
	expect(clone.restore(JSON.parse_string(JSON.stringify(frozen))) and clone.rewards_exhausted and clone.offers().is_empty(),"generated short-route empty page is restorable")
	bad = frozen.duplicate(true)
	bad.erase("rewards_exhausted")
	expect(not clone.restore(bad),"unmarked generated empty page remains invalid")
	bad = frozen.duplicate(true)
	bad.rewards_exhausted = "yes"
	expect(not clone.restore(bad),"nonboolean exhaustion rejected")
	expect(build.skip_exhausted_reward() and not build.skip_exhausted_reward(),"empty reward continuation is idempotent")
	expect(build.complete_node() and build.stage == 1 and not build.rewards_exhausted,"short continuation advances original route and clears exhaustion")
	expect(not fresh.skip_exhausted_reward(),"normal candidate pages cannot use empty continuation")
	var classic = full_build()
	expect(classic.choose(0) and classic.rewards_exhausted,"unseeded original route also freezes exhaustion")
	expect(clone.restore(JSON.parse_string(JSON.stringify(classic.to_dict()))) and clone.rewards_exhausted,"unseeded empty original route survives JSON checkpoint")
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/item-reward-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.run = full_build()
	game.run.code_supplies = {"supply":2,"converter":2,"shield":0,"revive":0}
	game.journey.data.erase("offers")
	game._victory()
	expect(game.journey.data.offers.size() == 2 and not game.journey.data.rewards_exhausted,"actual campaign displays only two consumable choices")
	game._campaign_action("reward_continue")
	expect(game.journey.data.screen == "reward" and not game.journey.visit.data.reward_taken,"nonempty original reward page cannot skip as exhausted")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"stock")
	var selected_target: String = game.journey.data.offers[0].target
	await choose(game,"reward:0")
	expect(game.run.code_supplies[selected_target] == 3 and game.journey.visit.data.reward_taken,"real original reward click grants exactly one stock")
	var original_stock: Dictionary = game.run.code_supplies.duplicate()
	game._campaign_action("reward:0")
	expect(game.run.code_supplies == original_stock,"same campaign reward cannot be taken twice")
	game.run.code_supplies = {"supply":3,"converter":3,"shield":0,"revive":0}
	game.journey.visit.data.reward_taken = false
	game.journey.data.erase("offers")
	game.journey.data.erase("rewards_exhausted")
	game._victory()
	expect(game.journey.data.offers.is_empty() and game.journey.data.rewards_exhausted,"actual campaign freezes empty legal page")
	game._continue_run()
	expect(game.journey.data.rewards_exhausted and game.journey.data.offers.is_empty(),"original campaign checkpoint reopens empty page")
	var journey_snapshot: Dictionary = game.journey.snapshot()
	var journey_clone = Journey.new()
	expect(journey_clone.restore(JSON.parse_string(JSON.stringify(journey_snapshot))),"empty journey is accepted only with explicit shape")
	bad = journey_snapshot.duplicate(true)
	bad.erase("rewards_exhausted")
	expect(not journey_clone.restore(bad),"old unmarked empty campaign page still rejected")
	bad = journey_snapshot.duplicate(true)
	bad.offers = [supply]
	expect(not journey_clone.restore(bad),"nonempty exhausted campaign shape rejected")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"empty")
	await choose(game,"reward_continue")
	expect(game.journey.visit.can_leave() and game.journey.data.screen == "visit","actual empty continuation unlocks original exit")
	original_stock = game.run.code_supplies.duplicate()
	game._campaign_action("reward_continue")
	expect(game.run.code_supplies == original_stock and game.journey.visit.data.reward_taken,"repeated empty action adds no stock")
	game.campaign_mode = ""
	game.campaign_panel.hide()
	game.run = full_build()
	game.run.generate(122)
	game.run.choose(0)
	game.screen = "reward"
	game.queue_redraw()
	await get_tree().process_frame
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"short-empty")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.origin+Vector2(640,519)*game.scale_factor
	game._gui_input(event)
	expect(game.screen == "map" and game.run.stage == 1,"original short-page continue click advances without phantom reward")
	game.queue_free()
	print("ITEM_REWARD checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func choose(game, action: String) -> void:
	var buttons = game.campaign_panel.find_children("*","Button",true,false).filter(func(button): return button.get_meta("action_id","") == action)
	expect(buttons.size() == 1 and not buttons[0].disabled,"real item button "+action)
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
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		expect(game.get_viewport_rect().encloses(game.get_global_rect()),"original reward frame fits "+str(size))
		get_viewport().get_texture().get_image().save_png("res://.godot/item-reward-%s-%dx%d.png" % [page,size.x,size.y])
