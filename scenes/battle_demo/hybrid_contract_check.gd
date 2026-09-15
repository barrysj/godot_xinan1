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
	for config in [Candidate, Chalk.battle_animation]:
		var rig: Node2D = config.presentation_scene.instantiate()
		add_child(rig)
		var clock = Animator.new(config)
		check(config.display_size == Vector2(140, 140), "Approved display size")
		check(config.anchor == Vector2(0.5, 0.875), "Approved foot anchor")
		for action in [&"idle", &"move", &"attack", &"cast", &"hurt", &"critical", &"death"]:
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
