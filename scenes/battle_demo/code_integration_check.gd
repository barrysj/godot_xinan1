extends Node
const Scene = preload("res://scenes/expedition/expedition.tscn")
var failures := 0
var checks := 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _ready() -> void:
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/code-main-check-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.progress.path = "res://.godot/code-main-check-%d.json" % Time.get_ticks_usec()
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,1,2,6,-1,-1]
	var test_roster: Array[int] = [0,1,2,3,6]
	game.run.roster = test_roster
	game._build_units()
	verify(game.simulation.get_script().resource_path == "res://game/combat/code_battle_simulation.gd", "original controller uses canonical code simulation")
	verify(game.simulation.tags.size() >= 2, "original roster activates synergies by stable identity")
	var eligible = game.RunModel.Rewards.eligible(false,game.run.roster,game.run.inventory,"campus_rewards",game.run.training,game.run.combat_rewards)
	var combat_ids: Array = eligible.filter(func(entry): return entry.operation == "combat").map(func(entry): return entry.target)
	verify(["cover","lens","training","verify","pierce","backup"].all(func(id): return combat_ids.has(id)), "all six trial upgrades enter the original reward pool")
	game.campaign_panel.show()
	game.screen = "campaign"
	var displayed_offers: Array = eligible.filter(func(entry): return entry.operation != "combat").slice(0,2)
	displayed_offers.append(eligible.filter(func(entry): return entry.get("target", "") == "training")[0])
	game.campaign_panel.rewards(displayed_offers)
	await get_tree().process_frame
	verify(game.campaign_panel.column.get_child_count() > 1, "original campaign reward panel renders mixed reward cards")
	verify(displayed_offers.any(func(entry): return entry.operation == "combat"), "original reward panel includes an integrated combat upgrade")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/main-code-rewards.png")
		var training_offer: Dictionary = eligible.filter(func(entry): return entry.get("target", "") == "training")[0]
		game.campaign_panel.reward_owner(training_offer,game.run.roster,game.run)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/main-code-reward-owner.png")
	game.campaign_panel.hide()
	game.screen = "battle"
	for entry in eligible:
		if entry.operation != "combat": continue
		var owner := ""
		if game.RunModel.Rewards.combat_needs_owner(entry.target): owner = "archer"
		if entry.target == "backup": owner = "analyst"
		verify(game.run.apply_reward(entry,owner), "campaign reward can be claimed: "+entry.target)
	verify(game.run.combat_rewards.size() == 6, "six combat rewards persist as this run build")
	verify(game.RunModel.Rewards.eligible(false,game.run.roster,game.run.inventory,"campus_rewards",game.run.training,game.run.combat_rewards).filter(func(entry): return entry.operation == "combat").is_empty(), "claimed combat rewards cannot be duplicated this run")
	game._build_units()
	verify(game.simulation.bindings.any(func(binding): return binding.source == "reward/cover") and game.simulation.bindings.any(func(binding): return binding.source == "reward/pierce") and game.simulation.upgrades.has("verify"), "synergy and character exclusive rewards bind into original combat")
	verify(game.units.any(func(unit): return unit.get("content_id", "") == "archer" and unit.max_hp >= roundi(game.Content.character(1).health * 1.15)), "training and equipped passive apply to selected main roster member")
	for actor in game.simulation.units:
		if actor.get("content_id", "") == "analyst" and actor.side == 0:
			var proc = load("res://resources/combat/synergies/analysis.tres").effects[0]
			game.simulation._apply_proc({"proc":proc,"label":"解析"},actor,{})
			verify(game.simulation.blocks.blue == 1, "analysis proc uses main roster identity instead of trial index")
	var panel = game.code_panel
	await get_tree().process_frame
	panel._select_program(0,2)
	verify(game.run.code_programs[0] == "repair", "preparation stores program")
	panel._select_program(0,0)
	game._start()
	for tick in range(100): game._tick()
	await get_tree().process_frame
	game.paused = false
	panel._process(0)
	panel._open_console()
	await get_tree().process_frame
	verify(game.paused and panel.paused, "original combat pauses for terminal")
	verify(panel.program_controls.has("disconnect"), "terminal uses current preparation")
	game._request_exit("quit")
	verify(game.paused and not panel.paused and not panel.console.visible and game.confirm_actions.visible, "window exit replaces terminal with original confirmation")
	game._open_pause()
	game._resume_battle()
	verify(not game.paused and game.pending_exit.is_empty(), "cancel exit resumes original battle")
	panel._open_console()
	await get_tree().process_frame
	var before: Dictionary = game.simulation.blocks.duplicate()
	panel.item_controls.supply.destination.select(3)
	panel._update_hud()
	await click(panel.item_controls.supply.button)
	verify(game.simulation.items.supply == 0 and game.simulation.blocks.purple == before.purple+3, "original UI supply changes actual simulation")
	verify(game.run.code_supplies.supply == 1, "inflight item spend preserves retry checkpoint")
	var retry_state = game.CampaignSave.decode(game.progress.active_run)
	verify(not retry_state.is_empty() and retry_state.build.code_supplies.supply == 1, "interrupted battle reload retains unspent checkpoint inventory")
	var conversion: Dictionary = panel.item_controls.converter
	conversion.source.select(3)
	conversion.destination.select(1)
	panel._update_hud()
	await click(conversion.button)
	await click(panel.program_controls.takeover.button)
	verify(game.simulation.system_taken and game.simulation.casts == 1, "real mouse conversion and takeover execute in main battle")
	verify(not panel.paused and not panel.console.visible,"successful program returns to the battle for its visual feedback")
	var saved: Dictionary = game.run.to_dict()
	var restored = game.RunModel.new()
	verify(restored.restore(saved) and restored.code_programs == game.run.code_programs and restored.combat_rewards.size() == 6, "schema7 restores programs and combat rewards")
	var invalid_owner: Dictionary = saved.duplicate(true)
	invalid_owner.combat_rewards[1].owner = "missing_character"
	verify(not restored.restore(invalid_owner), "invalid combat reward owner rejected")
	saved.code_supplies.supply = -1
	verify(not restored.restore(saved), "invalid inventory rejected")
	saved = game.run.to_dict()
	saved.schema = 5
	saved.erase("code_programs")
	saved.erase("code_supplies")
	verify(restored.restore(saved) and restored.code_supplies.supply == 1 and restored.combat_rewards.is_empty(), "schema5 gains default kit and no fabricated rewards")
	var journey = load("res://game/run/campaign_journey.gd").new()
	journey.begin("library",1)
	journey.enter(0,[])
	journey.visit.data.guard_won = true
	journey.data.screen = "reward_owner"
	journey.data.offers = [eligible.filter(func(entry): return entry.get("target", "") == "training")[0]]
	journey.data.pending_offer = journey.data.offers[0].duplicate(true)
	var journey_copy = load("res://game/run/campaign_journey.gd").new()
	verify(journey_copy.restore(journey.snapshot()) and journey_copy.data.screen == "reward_owner", "campaign owner selection resumes from saved checkpoint")
	if "--capture" in OS.get_cmdline_user_args():
		get_window().mode = Window.MODE_WINDOWED
		panel._open_console()
		var capture_size := Vector2i(1920,1080)
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--size="):
				var parts = arg.trim_prefix("--size=").split("x")
				capture_size = Vector2i(int(parts[0]),int(parts[1]))
		get_window().size = capture_size
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		verify(get_viewport().get_texture().get_image().get_size() == capture_size, "actual capture size")
		verify(panel.get_viewport_rect().encloses(panel.console.get_global_rect()), "terminal fits viewport")
		get_viewport().get_texture().get_image().save_png("res://.godot/main-code-terminal-%dx%d.png" % [capture_size.x,capture_size.y])
	panel._close_console()
	verify(not game.paused, "resume returns original battle")
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/main-code-battle.png")
	for tick in range(5000):
		if game.screen == "report": break
		game._process(0.05)
	verify(game.result_won and game.screen == "report", "integrated battle reaches real victory report")
	verify(game.run.code_supplies.supply == 0 and game.run.code_supplies.converter == 0, "victory commits item spending")
	var checkpoint: Dictionary = game.progress.active_run.duplicate(true)
	var decoded = game.CampaignSave.decode(checkpoint)
	verify(not decoded.is_empty() and decoded.build.code_supplies.supply == 0, "campaign checkpoint persists spent inventory")
	game._continue_run()
	verify(game.screen == "report" and game.run.code_supplies.supply == 0, "resume report does not refill supplies")
	print("MAIN_CODE_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)


func click(button: Button) -> void:
	await get_tree().process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
	await get_tree().process_frame
