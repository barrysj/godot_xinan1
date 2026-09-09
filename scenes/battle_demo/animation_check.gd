extends Node
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const AnimationSet = preload("res://game/content/battle_animation_set.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	# In-memory existing texture fixtures only; no production art is created.
	var config = AnimationSet.new()
	config.frames = SpriteFrames.new()
	var first = load("res://assets/pixel/kenney/tiny-town.png")
	var second = load("res://assets/pixel/kenney/tiny-dungeon.png")
	for clip in [&"idle", &"attack", &"hurt", &"cast", &"critical", &"death"]:
		config.frames.add_animation(clip)
		config.frames.set_animation_speed(clip, 10)
		config.frames.add_frame(clip, first, 1)
		config.frames.add_frame(clip, second, 2)
	var a = Animator.new(config)
	a.play(&"attack")
	a.advance(0.11)
	check(a.texture() == second, "Relative frame duration playback")
	a.play(&"cast")
	a.play(&"hurt")
	check(a.state == &"cast", "Hurt must not interrupt cast")
	a.sync_health(20, 100)
	a.advance(0.31)
	check(a.state == &"critical", "Action returns to critical idle")
	a.sync_health(80, 100)
	check(a.state == &"idle", "Healing exits critical")
	a.sync_health(0, 100)
	a.play(&"attack")
	a.advance(3)
	check(a.state == &"death" and a.texture() == second, "Death holds last frame")
	a.sync_health(100, 100)
	check(a.state == &"idle" and a.age == 0, "Revive resets death")
	var missing = Animator.new()
	missing.play(&"attack")
	missing.sync_health(0, 100)
	check(missing.texture() == null, "Missing asset falls back")
	var battle = load("res://scenes/battle_demo/battle_demo.tscn").instantiate()
	add_child(battle)
	battle.set_process(false)
	battle._start()
	var actor: Dictionary = battle.units[0]
	actor.animation = Animator.new(config)
	battle._present_action(actor, true)
	check(actor.animation.state == &"cast", "Battle skill hook")
	battle.paused = true
	battle._process(0.1)
	check(actor.animation.age == 0, "Pause freezes playback")
	battle.paused = false
	battle.speed = 2
	battle._process(0.05)
	check(is_equal_approx(actor.animation.age, 0.1), "Double speed playback")
	battle._start()
	check(battle.units[0].animation.state == &"idle", "Restart clears playback")
	battle.free()
	print("ANIMATION CHECK: ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(failures)
