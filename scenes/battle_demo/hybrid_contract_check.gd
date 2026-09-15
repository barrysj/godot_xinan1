extends Node
## Baseline contract: load the candidate directly, independently of its production binding.
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const Candidate = preload("res://design/concepts/chalk-spirit/chalk-spirit/006/battle_animation.tres")
const Chalk = preload("res://resources/content/enemies/chalk.tres")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	_check_shared_controller()
	for config in [Candidate, Chalk.battle_animation]:
		var rig: Node2D = config.presentation_scene.instantiate()
		add_child(rig)
		var clock = Animator.new(config, Chalk.resolved_attack_modes())
		check(config.display_size == Vector2(140, 140), "Approved display size")
		check(config.anchor == Vector2(0.5, 0.875), "Approved foot anchor")
		for action in [&"idle", &"move", &"ranged", &"cast", &"hurt", &"critical", &"death"]:
			check(clock._has_clip(action), "Sequence fallback exists: " + action)
			check(rig.handles_presentation_state(action) == (action != &"death"), "Backend allocation: " + action)
			for right in [true, false]:
				var context := {"state": action, "age": 0.2, "duration": clock._duration(action),
					"motion_time": 0.2, "center": Vector2(200, 300), "display_size": config.display_size,
					"facing_right": right, "tint": Color.WHITE}
				rig.apply_presentation(context)
				check(rig.visible == (action != &"death"), "Death hides skeleton")
				if action != &"death":
					check(rig.position == context.center, "Foot position remains authoritative")
					check((rig.scale.x > 0) == right, "Facing follows context")
					var before := rig.transform
					rig.apply_presentation(context)
					check(rig.transform == before, "Repeated context does not advance playback")
		clock.sync_health(0, 100)
		clock.advance(10)
		check(clock.texture() == config.frames.get_frame_texture(&"death", 7), "Approved death final frame")
		rig.free()
	print("HYBRID_CONTRACT_CHECK failures=", failures)
	get_tree().quit(failures)

func _check_shared_controller() -> void:
	var root := Node2D.new()
	root.set_script(preload("res://scenes/battle_demo/presentations/hybrid_presentation.gd"))
	var bone := Node2D.new()
	bone.name = "Pivot"
	root.add_child(bone)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root.add_child(player)
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = 2.0
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, ^"Pivot:position")
	clip.track_insert_key(track, 0.0, Vector2.ZERO)
	clip.track_insert_key(track, 2.0, Vector2(20, 0))
	library.add_animation(&"ranged", clip)
	player.add_animation_library(&"", library)
	add_child(root)
	var context := {"state": &"ranged", "age": 0.25, "duration": 0.5,
		"center": Vector2(100, 100), "display_size": Vector2(144, 144), "facing_right": false}
	root.apply_presentation(context)
	check(bone.position.is_equal_approx(Vector2(10, 0)), "Shared player seeks normalized authoritative time")
	check(not player.is_playing() and root.scale == Vector2(-0.5, 0.5), "Manual player stays paused and mirrors from context")
	root.apply_presentation(context)
	check(bone.position.is_equal_approx(Vector2(10, 0)), "Repeated context is idempotent")
	context.age = 0.0
	root.apply_presentation(context)
	check(bone.position == Vector2.ZERO, "Restart seeks beginning without hidden playback state")
	context.state = &"death"
	root.apply_presentation(context)
	check(not root.visible, "Unsupported skeleton action delegates to shared SpriteFrames renderer")
	root.free()
