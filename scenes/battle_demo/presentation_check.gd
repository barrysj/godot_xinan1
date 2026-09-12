extends Node
const Presenter = preload("res://scenes/battle_demo/unit_presentation.gd")
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const AnimationSet = preload("res://game/content/battle_animation_set.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	var config = AnimationSet.new()
	config.frames = SpriteFrames.new()
	var image = load("res://assets/pixel/kenney/tiny-town.png")
	for clip in [&"idle", &"move", &"attack", &"cast", &"death"]:
		config.frames.add_animation(clip)
		config.frames.set_animation_speed(clip, 4)
		for i in 4: config.frames.add_frame(clip, image)
	var animator = Animator.new(config)
	animator.sync_motion(true, {})
	check(animator.state == &"move", "Move clip is selected")
	var action = {"age": 0.2, "windup": 0.2, "duration": 0.45, "casts": false}
	animator.sync_motion(false, action)
	check(is_equal_approx(animator.age, config.impact_ratio), "Release aligns to configured frame ratio")
	animator.advance(0.3)
	check(is_equal_approx(animator.age, config.impact_ratio), "Action clip cannot outrun simulation")
	animator.sync_motion(false, {})
	check(animator.state == &"idle" and not animator.action_driven, "Completed action releases playback lock")
	animator.sync_health(0, 100)
	animator.sync_motion(false, action)
	animator.advance(2)
	check(animator.state == &"death", "Death overrides driven action and reaches final frame")
	var unit = {"position": Vector2(2, 2), "previous_position": Vector2(1, 2), "hp": 100,
		"slot": 0, "moving": true, "facing": Vector2.LEFT}
	check(Presenter.position(unit, 0.5) == Vector2(1.5, 2), "Render interpolates between fixed positions")
	var presenter = Presenter.new()
	presenter.consume({"kind": "action_started", "windup": 0.2, "duration": 0.45,
		"from": Vector2.ZERO, "to": Vector2.RIGHT, "casts": false})
	presenter.consume({"kind": "impact", "effect": "damage", "actual": 10,
		"from": Vector2.ZERO, "to": Vector2.RIGHT})
	presenter.advance(0.05, unit)
	check(not presenter.action.is_empty(), "Recoil preserves active attack")
	check(presenter.pose(unit, true).tint.r > 1, "Animated assets also receive hit tint")
	unit.hp = 0
	presenter.advance(0.5, unit)
	check(presenter.action.is_empty() and presenter.pose(unit, true).tint.a < 0.3, "Death also fades animated assets")
	var battle = load("res://scenes/battle_demo/battle_demo.tscn").instantiate()
	add_child(battle)
	battle.set_process(false)
	battle.formation = [0, -1, 3, 2, 1, -1]
	var outcomes = []
	for rate in [30, 60, 144]:
		for multiplier in [1, 2]:
			battle._start()
			battle.speed = multiplier
			var budget = 0
			while battle.phase == "battle" and budget < rate * 100:
				battle._process(1.0 / rate)
				budget += 1
			var stats = []
			for u in battle.units: stats.append([u.damage, u.healing])
			outcomes.append([battle.result_won, battle.elapsed, stats])
	for result in outcomes: check(result == outcomes[0], "30/60/144 fps and 1x/2x preserve outcome and statistics")
	battle._start()
	for i in 150: battle._process(1.0 / 60)
	battle.paused = true
	var frozen = [battle.elapsed, battle.accumulator, battle.visual_time, battle.effects.duplicate(true),
		battle.simulation.projectiles.size(), battle.units[0].presentation.motion_time]
	battle._process(1)
	check(frozen == [battle.elapsed, battle.accumulator, battle.visual_time, battle.effects,
		battle.simulation.projectiles.size(), battle.units[0].presentation.motion_time], "Pause freezes complete presentation")
	battle._start()
	check(battle.effects.is_empty() and battle.simulation.projectiles.is_empty(), "Restart removes projectiles and feedback")
	battle.free()
	print("PRESENTATION_CHECK ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	get_tree().quit(failures)
