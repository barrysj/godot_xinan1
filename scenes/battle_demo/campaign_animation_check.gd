extends Node
## Exercises the actual campaign scene, where presentation overrides can hide authored animations.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/campaign-animation-check.json"
	add_child(game)
	await get_tree().process_frame
	game.progress.path = "res://.godot/campaign-animation-check.json"
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library", "prologue")
	game._guard()
	game.run.node.encounter_id = "encounter_classroom"
	game.run.node.name = "粉笔精灵动画检查"
	game.formation = [0, 1, 2, 3, -1, -1]
	var roster: Array[int] = [0, 1, 2, 3]
	game.run.roster = roster
	game._build_units()
	game.screen = "battle"
	game._start()
	var chalk: Array[Dictionary] = game.units.filter(func(unit): return unit.side == 1 and unit.content_id == "chalk")
	verify(chalk.size() == 2, "campaign encounter contains two chalk spirits")
	for actor in chalk:
		verify(actor.battle_animation != null and actor.battle_animation.presentation_scene != null,
			"chalk spirit retains its approved hybrid animation resource")
		verify(is_instance_valid(game.battle_presentations.get(actor.id)),
			"campaign creates the chalk spirit presentation node")
	var ranged_visible := false
	var ranged_driven := false
	var captured := false
	for frame in 600:
		if game.phase != "battle": break
		game._process(1.0 / 60.0)
		for actor in chalk:
			var rig: Node2D = game.battle_presentations.get(actor.id)
			if not is_instance_valid(rig) or actor.animation.state != &"ranged" or not rig.visible: continue
			ranged_visible = true
			ranged_driven = ranged_driven or rig.get("selected_clip") == &"ranged"
			if "--capture" in OS.get_cmdline_user_args() and not captured and actor.animation.age > 0.12:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://.godot/chalk-campaign-ranged.png")
				captured = true
			break
		if captured: break
	verify(ranged_visible, "campaign renders an authored chalk spirit ranged action")
	verify(ranged_driven, "campaign advances the chalk spirit hybrid animation controller")
	if "--capture" in OS.get_cmdline_user_args(): verify(captured, "campaign ranged frame captured from the real battle view")
	print("CAMPAIGN_ANIMATION_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
