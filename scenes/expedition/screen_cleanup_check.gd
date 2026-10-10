extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/screen-cleanup-"+label+".png")
func visible_reward_text(root: Node) -> bool:
	if root is Label and root.is_visible_in_tree() and root.text.begins_with("已获得 · "): return true
	for child in root.get_children():
		if visible_reward_text(child): return true
	return false
func no_actors(game, label: String) -> void:
	verify(not game.battle_actor_layer.is_visible_in_tree(), label+": battle actor layer hidden")
	for instance in game.battle_presentations.values():
		verify(not instance.is_visible_in_tree(), label+": actor hidden")
func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/screen-cleanup-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game.journey.data.id = "screen-cleanup-fixed"
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game._start()
	await get_tree().process_frame
	verify(game.battle_actor_layer.is_visible_in_tree(), "Battle shows actors")
	game.simulation.won = true
	game._finish_battle()
	game._process(0)
	verify(game.screen == "report", "Result reaches the real report")
	no_actors(game,"report")
	await capture("report")
	game._after_report()
	no_actors(game,"reward")
	verify(game.journey.data.screen == "reward", "Actual victory opens reward page")
	game._campaign_action("reward:0")
	if game.journey.data.screen == "reward_owner":
		no_actors(game,"reward_owner")
		game._campaign_action("reward_owner:"+game.Content.role_id(game.run.roster[0]))
	verify(game.journey.visit.data.reward_taken, "Reward chosen through campaign actions")
	verify(not visible_reward_text(game.campaign_panel), "Reward detail does not remain in the upper-left after taking it")
	no_actors(game,"visit")
	await capture("after-reward")
	game._home()
	no_actors(game,"home")
	await capture("home")
	game._begin_region("library","prologue")
	game._guard()
	verify(game.battle_actor_layer.visible, "Return to preparation restores actor layer")
	game._victory()
	var owner_offers: Array = game.RunModel.Rewards.for_build(game.run).filter(func(offer): return offer.operation == "combat" and offer.target == "training")
	verify(not owner_offers.is_empty(), "Use the existing owner reward definition")
	game.journey.data.offers = owner_offers
	game._show_journey()
	game._campaign_action("reward:0")
	verify(game.journey.data.screen == "reward_owner", "Existing training opens owner selection")
	no_actors(game,"reward_owner")
	game._campaign_action("reward_back")
	no_actors(game,"reward_back")
	game._campaign_action("reward:0")
	game._campaign_action("reward_owner:"+game.Content.role_id(game.run.roster[0]))
	verify(game.journey.visit.data.reward_taken, "Owner reward applied")
	verify(not visible_reward_text(game.campaign_panel), "Owner reward detail also disappears after taking it")
	game._campaign_action("leave")
	no_actors(game,"leave")
	for destination in ["map","event","reward","reward_owner","summary","growth","dispatch"]:
		game.screen = "battle"
		game.screen = destination
		no_actors(game,destination)
	print("SCREEN_CLEANUP_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
