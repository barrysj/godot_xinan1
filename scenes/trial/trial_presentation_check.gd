extends Node
const Board = preload("res://scenes/trial/trial_board.gd")
const Simulation = preload("res://game/trial/trial_simulation.gd")
var failures := 0
var checks := 0
var board
var sim

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	sim = Simulation.new()
	sim.start([0, -1, 3, 2, 1, -1], 0, [], {}, -1)
	board = Board.new()
	board.size = Vector2(1500, 480)
	board.position = Vector2(100, 180)
	board.simulation = sim
	add_child(board)
	var before = sim.units.duplicate(true)
	board.advance_presentation(0.2, 0.5)
	check(before == sim.units, "Presentation does not mutate simulation dictionaries")
	check(board.actors.size() == sim.units.size(), "One presentation per runtime combatant")
	for unit in sim.units:
		check(not unit.has("animation") and not unit.has("presentation"), "Simulation owns no view clocks")
	var trace: Array[Dictionary] = []
	for i in 140:
		var events = sim.advance(0.05)
		trace.append_array(events)
		board.consume_events(events)
		board.advance_presentation(0.05, 1)
		if sim.awaiting_choice: break
	check(trace.any(func(event): return event.kind == "action_started"), "Real combat emits anticipation")
	check(trace.any(func(event): return event.kind == "action_released"), "Real combat emits release")
	check(trace.any(func(event): return event.kind == "impact"), "Real combat emits impact")
	check(not board.effects.is_empty(), "Real combat yields transient feedback")
	var clock: float = board.visual_time
	var effects: Array = board.effects.duplicate(true)
	before = sim.units.duplicate(true)
	board.advance_presentation(0, 1)
	check(board.visual_time == clock and effects == board.effects, "Zero-time refresh freezes effects and presentation clock")
	check(before == sim.units, "Combat rendering remains read-only")
	var unit: Dictionary = sim.units[0]
	var actor = board.actors[unit.id]
	check(actor.position == board.point(unit.position), "Unit projection follows actual simulated position")
	var health: float = unit.hp
	var cue = {"kind": "impact", "actor_id": unit.id, "target_id": unit.id,
		"from": unit.position, "to": unit.position, "effect": "damage", "actual": 9, "special": true}
	board.consume_events([cue])
	check(unit.hp == health, "Impact cues cannot apply additional damage")
	check(actor.presenter.hurt_age == 0, "Impact triggers recoil without clearing action")
	for kind in ["mark_applied", "mark_verified", "hack_progress", "trait_triggered", "hack_completed"]:
		var special = cue.duplicate(true)
		special.kind = kind
		special.label = "协作"
		special.choice = "takeover"
		board.consume_events([special])
	check(board.effects.any(func(fx): return fx.kind == "verify"), "Verification has distinct link feedback")
	check(board.effects.any(func(fx): return fx.kind == "packet"), "Progress contributions have moving packets")
	check(board.effects.any(func(fx): return fx.kind == "system"), "Hack choice has system feedback")
	board.effects = board.effects.filter(func(fx): return fx.kind == "damage")
	board._banner_age = 9
	var inspect: Array[String] = []
	board.inspected.connect(func(text): inspect.append(text))
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = actor.position - Vector2(0,30)
	board._gui_input(click)
	check(not inspect.is_empty() and inspect[0].contains(unit.name), "Click selects actual combatant details")
	# Backend coverage uses the exact shared authored resource, including death fallback.
	var chalk = load("res://resources/content/enemies/chalk.tres")
	var fixture = unit.duplicate(true)
	fixture.battle_animation = chalk.battle_animation
	fixture.attack_modes = chalk.attack_modes
	fixture.action = {}
	var authored = preload("res://scenes/trial/trial_actor.gd").new()
	add_child(authored)
	authored.configure(fixture)
	authored.synchronize(fixture, 0, 1, Vector2.ZERO, 1, false, false)
	check(is_instance_valid(authored.hybrid) and authored.hybrid.visible, "Hybrid animation backend accepts shared asset")
	fixture.hp = 0
	authored.synchronize(fixture, 0.5, 1, Vector2.ZERO, 1, false, false)
	check(not authored.hybrid.visible and authored.animator.texture() != null, "Authored death falls back to SpriteFrames")
	authored.free()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/trial-presentation-combat.png")
		while not sim.awaiting_choice and not sim.finished:
			board.consume_events(sim.advance(0.05))
			board.advance_presentation(0.05, 1)
		check(sim.awaiting_choice, "Capture reaches real hacking choice")
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/trial-presentation-hack.png")
	board.advance_presentation(4, 1)
	check(board.effects.is_empty() and board.skill_effects.is_empty(), "Transient effects expire")
	board.reset_presentation()
	check(board.effects.is_empty() and board.visual_time == 0, "Restart resets presentation")
	# Different render frequencies and speed multipliers see identical combat traces.
	var expected: Array = []
	for fps in [30, 60, 144]:
		for speed in [0.25, 1.0, 2.0]:
			sim.start([0, -1, 3, 2, 1, -1], 0, [], {}, -1)
			board.reset_presentation()
			var steps := 0
			var accumulator := 0.0
			var events_seen: Array = []
			while steps < 180:
				accumulator += speed / fps
				var elapsed_frame := 0.0
				while accumulator + 0.000001 >= 0.05 and steps < 180:
					accumulator -= 0.05
					elapsed_frame += 0.05
					steps += 1
					var events = sim.advance(0.05)
					events_seen.append_array(events)
					board.consume_events(events)
				board.advance_presentation(elapsed_frame, accumulator / 0.05)
			if expected.is_empty(): expected = events_seen
			check(expected == events_seen, "Render frequency and speed preserve event stream %d / %.2f" % [fps, speed])
	print("TRIAL_PRESENTATION_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
