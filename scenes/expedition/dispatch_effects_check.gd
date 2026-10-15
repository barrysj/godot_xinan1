extends Node
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Run = preload("res://game/run/short_run.gd")
const Checkpoint = preload("res://game/run/campaign_checkpoint.gd")
var failures := 0
var checks := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DISPATCH_EFFECTS: "+label)

func _ready() -> void:
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/dispatch-effects-profile.json"
	game.progress.campaign.prologue_done = true
	game.progress.points = 25
	expect(game.progress.execute_commission("departure","archivist"),"tutorial unlock")
	game.progress.acknowledge_dispatch_result(game.progress.pending_dispatch_result.id)
	add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	game._begin_region("library","region","analysis")
	expect(game.run.dispatch_items.is_empty() and game.run.dispatch_buffs.is_empty(),"locked run has no paid dispatch effects")
	expect(not Run.Rewards.for_build(game.run).any(func(entry): return entry.id == "code_shield"),"locked shield excluded from rewards")
	expect(not game.run.apply_reward(Run.Rewards.find("code_shield")),"locked reward cannot be directly granted")
	for id in ["field_supplies","second_opinion"]:
		expect(game.progress.execute_commission(id,"technician"),"real dispatch effect unlock "+id)
		game.progress.acknowledge_dispatch_result(game.progress.pending_dispatch_result.id)
	game._continue_run()
	expect(game.run.dispatch_items.is_empty() and game.run.dispatch_buffs.is_empty(),"active run does not retroactively gain effects")
	game._begin_region("library","region","analysis")
	expect(game.run.dispatch_items == ["shield"] and game.run.dispatch_buffs == ["reward_refresh"],"next run snapshots both effects")
	expect(not game.progress.Commissions.preparation_reason(game.progress.commission_unlocks,["shield"]).is_empty(),"loot unlock does not silently unlock departure pool")
	var shield: Dictionary = Run.Rewards.find("code_shield")
	expect(Run.Rewards.valid_snapshot(shield) and Run.Rewards.for_build(game.run).any(func(entry): return entry.id == "code_shield"),"registered shield enters actual legal pool")
	var found := false
	for seed_value in range(100):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		if Run.Rewards.draw_for_build(game.run,rng,1,false).any(func(entry): return entry.id == "code_shield"): found = true
	expect(found,"weighted production draw can offer shield")
	expect(game.run.apply_reward(shield) and game.run.code_supplies.shield == 1,"taking shield changes original combat stock")
	game.run.code_supplies.shield = Run.CodeCatalog.STOCK_CAP
	expect(not Run.Rewards.for_build(game.run).any(func(entry): return entry.id == "code_shield") and not game.run.apply_reward(shield),"full shield stock cannot overflow")
	game.run.code_supplies.shield = 1
	game._campaign_action("enter:0")
	game._victory()
	expect(game.journey.data.screen == "reward" and game.run.can_refresh_rewards(game.journey.data.offers),"real reward page enables rule buff")
	var original: Array = game.journey.data.offers.duplicate(true)
	var count: int = game.run.reward_offer_count
	var path: String = game.progress.path
	game.progress.path = "res://.godot/missing-effects-folder/profile.json"
	game._campaign_action("reward_refresh")
	expect(not game.last_save_ok and not game.run.reward_refresh_used and game.journey.data.offers == original,"failed refresh save restores offers and allowance")
	game.progress.path = path
	game._continue_run()
	if "--capture" in OS.get_cmdline_user_args(): await capture("dispatch-reward-refresh")
	var button: Button = game.campaign_panel.action_button("reward_refresh")
	expect(button != null and not button.disabled,"refresh is an actual enabled UI action")
	if button != null: button.pressed.emit()
	expect(game.run.reward_refresh_used and game.journey.data.offers != original,"refresh spends allowance and changes candidates")
	expect(game.run.reward_offer_count == count,"refresh does not advance reward progression")
	var refreshed: Array = game.journey.data.offers.duplicate(true)
	game._campaign_action("reward_refresh")
	expect(game.journey.data.offers == refreshed,"second refresh rejected")
	game._continue_run()
	expect(game.run.reward_refresh_used and game.journey.data.offers == refreshed and not game.run.can_refresh_rewards(refreshed),"reload cannot refresh again or reroll")
	expect(game.run.code_supplies.shield == 1,"rewarded stock survives checkpoint")
	if "--capture" in OS.get_cmdline_user_args(): await capture("dispatch-reward-refreshed")
	var bad: Dictionary = game.run.to_dict()
	bad.dispatch_buffs = []
	expect(not Run.new().restore(bad),"used refresh without its buff is invalid")
	bad = game.run.to_dict()
	bad.dispatch_items = ["unknown"]
	expect(not Run.new().restore(bad),"unknown frozen item rejected")
	var old: Dictionary = game.run.to_dict()
	old.schema = 9
	old.erase("dispatch_items")
	old.erase("dispatch_buffs")
	old.erase("reward_refresh_used")
	var legacy = Run.new()
	expect(legacy.restore(JSON.parse_string(JSON.stringify(old))) and legacy.dispatch_buffs.is_empty() and legacy.dispatch_items.is_empty(),"schema9 migration grants no new active effects")
	game._begin_region("library","region","analysis")
	expect(not game.run.reward_refresh_used and game.run.dispatch_buffs.has("reward_refresh"),"new run restores one allowance")
	print("DISPATCH_EFFECTS checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture(id: String) -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920,1080)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/"+id+".png")
