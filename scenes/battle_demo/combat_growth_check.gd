extends Node
## Exercise the original reward UI, build codec and simulation, with isolated fixtures.
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Fixture = preload("res://game/combat/combat_check_fixture.gd")
const Rewards = preload("res://game/run/reward_catalog.gd")
const Codes = preload("res://game/combat/code_catalog.gd")
var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func flush(sim) -> void:
	var due: Array[Dictionary] = []
	sim._resolve(due)

func recoil_sample(upgrades: Array) -> Dictionary:
	var sim = Fixture.build([0,5,-1,4,2,-1], upgrades, {}, ["redirect","repair"])
	var ally: Dictionary = sim._living(0)[0]
	var foe: Dictionary = sim._living(1)[0]
	ally.shield = 0.0
	ally.shield_layers.clear()
	ally.position = foe.position
	for enemy in sim._living(1):
		enemy.position = Vector2(20,20)
		enemy.def = 0
	foe.position = ally.position
	sim.blocks.purple = 2
	sim.blocks.green = 1
	expect(sim.cast_program("redirect"), "legal recoil with upgrades")
	var layer: Dictionary = ally.shield_layers.filter(func(entry): return entry.source == "recoil")[0]
	var expires_at: float = layer.expires_at
	expect(layer.amount == 30 and sim.blocks.purple == 0 and sim.blocks.green == 0, "upgrade does not raise shield or refund its payment")
	sim.elapsed = 5.0
	sim._expire_shields(ally)
	var survives_at_five: bool = ally.shield_layers.any(func(entry): return entry.source == "recoil")
	flush(sim)
	var before: float = foe.hp
	# If expiry already happened, use the emitted impact to read its effective damage.
	var damage := 0.0
	if survives_at_five:
		sim.elapsed = expires_at
		sim._expire_shields(ally)
		flush(sim)
		damage = before - foe.hp
	else:
		for event in sim.events:
			if event.kind == "impact" and event.target_id == foe.id and event.get("effect") == "damage":
				damage += event.actual
	expect(sim.events.filter(func(event): return event.kind == "recoil_burst" and event.actor_id == ally.id).size() == 1, "expiry bursts once")
	expect(sim.generated.get("purple",0) == 0 and sim.absorbed == 0, "unabsorbed expiry cannot produce permission code")
	return {"expiry":expires_at,"survives":survives_at_five,"damage":damage}

func _ready() -> void:
	var baseline := recoil_sample([])
	var buffered := recoil_sample(["buffer"])
	var isolated := recoil_sample(["isolation"])
	var combined := recoil_sample(["buffer","isolation"])
	print("GROWTH_RECOIL ", baseline, buffered, isolated, combined)
	expect(baseline.expiry == 5 and baseline.damage == 30, "baseline expiry and blast")
	expect(buffered.expiry == 6.5 and buffered.survives and buffered.damage == 30, "buffer preserves damage and delays expiry")
	expect(isolated.expiry == 5 and isolated.damage == 36, "isolation preserves lifetime and raises blast")
	expect(combined.expiry == 6.5 and combined.damage == 36, "distinct modifiers compose without multiplying each other")
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/combat-growth-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game.run.growth_rules = 1 # Explicit legacy budget fixture.
	game._guard()
	var roster: Array[int] = [0,1,2,3,4,5,6]
	game.run.roster = roster
	game.formation = [0,3,-1,4,2,-1]
	game.run.formation = game.formation.duplicate()
	var eligible: Array = Rewards.eligible(false,roster,game.run.inventory,"campus_rewards",game.run.training,game.run.combat_rewards)
	expect(eligible.filter(func(entry): return entry.operation == "combat").size() == 8, "all eight registered combat upgrades reach original rewards")
	var buffer_offer: Dictionary = eligible.filter(func(entry): return entry.get("target") == "buffer")[0]
	var isolation_offer: Dictionary = eligible.filter(func(entry): return entry.get("target") == "isolation")[0]
	var training_offer: Dictionary = eligible.filter(func(entry): return entry.get("target") == "training" and entry.operation == "combat")[0]
	# Deterministic reward-page fixtures, not a second game flow or a claimed combat victory.
	game.journey.visit.data.guard_won = true
	game.journey.data.screen = "reward"
	game.journey.data.offers = [buffer_offer,isolation_offer,training_offer]
	game._show_journey()
	await get_tree().process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await capture(game,"rewards")
	await choose(game,"reward:0")
	expect(game.run.combat_rewards.any(func(entry): return entry.target == "buffer") and game.journey.visit.data.reward_taken, "real reward button grants buffer once")
	expect(not game.run.apply_reward(buffer_offer), "claimed upgrade cannot be duplicated")
	expect(game.run.apply_reward(isolation_offer), "other registered modifier can be granted by original build")
	game.journey.visit.data.reward_taken = false
	game.journey.data.screen = "reward"
	game.journey.data.offers = [training_offer]
	game._show_journey()
	await choose(game,"reward:0")
	expect(game.journey.data.screen == "reward_owner" and game.run.combat_rewards.size() == 2, "training waits for owner without granting prematurely")
	var pending = game.CampaignSave.decode(game.progress.active_run)
	expect(not pending.is_empty() and pending.journey.data.pending_offer.target == "training", "owner selection survives original campaign checkpoint")
	if "--capture" in OS.get_cmdline_user_args(): await capture(game,"owner")
	await choose(game,"reward_owner:archer")
	expect(game.journey.visit.data.reward_taken and game.run.combat_rewards.size() == 3, "actual owner button grants training")
	var archer: Dictionary = game._ally_unit(1,4)
	var guard: Dictionary = game._ally_unit(0,0)
	expect(archer.max_hp == 226 and archer.atk == 37 and archer.hp == 226, "training applies ten and eight percent to reserve owner")
	expect(guard.max_hp == 360 and guard.atk == 22, "training does not leak to another character")
	game.run.training[1] = 2
	game.run.grant_gear("badge")
	game.run.equip_gear("badge",1)
	game.run.permanent_hp = 40
	archer = game._ally_unit(1,4)
	expect(archer.max_hp == 464 and archer.atk == 48, "legacy fixed training and gear order remain, meta health added once")
	expect(game._save_campaign(), "growth persists through original campaign storage")
	var restored = game.CampaignSave.decode(game.progress.active_run)
	expect(not restored.is_empty() and restored.build.combat_rewards.size() == 3 and restored.build.training[1] == 2, "registered rewards and legacy training restore")
	game.run = restored.build
	var rebuilt: Dictionary = game._ally_unit(1,4)
	expect(rebuilt.max_hp == 464 and rebuilt.atk == 48, "reload/rebuild does not stack growth twice")
	var remaining: Array = Rewards.eligible(false,game.run.roster,game.run.inventory,"campus_rewards",game.run.training,game.run.combat_rewards)
	expect(not remaining.any(func(entry): return entry.get("target") in ["buffer","isolation"] and entry.operation == "combat"), "claimed program modifiers leave the pool")
	game._build_units()
	expect(game.simulation.upgrades.has("buffer") and game.simulation.upgrades.has("isolation"), "restored build attaches modifiers to next original battle")
	print("COMBAT_GROWTH checks=%d failures=%d" % [checks,failures])
	game.queue_free()
	get_tree().quit(0 if failures == 0 else 1)

func choose(game, action_id: String) -> void:
	var buttons = game.campaign_panel.find_children("*","Button",true,false).filter(func(button): return button.get_meta("action_id","") == action_id)
	expect(buttons.size() == 1, "one actual button for "+action_id)
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

func capture(game, label: String) -> void:
	get_window().mode = Window.MODE_WINDOWED
	for size in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = size
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		expect(game.campaign_panel.get_viewport_rect().encloses(game.campaign_panel.get_global_rect()), "reward panel fits "+str(size))
		get_viewport().get_texture().get_image().save_png("res://.godot/combat-growth-%s-%dx%d.png" % [label,size.x,size.y])
