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
		_check_animation_budget(config.animation_library)
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
		# Switching from every previous action must produce the same visible pose
		# as a fresh instance, including late cycle phases and restart to time zero.
		for previous in [&"cast", &"hurt", &"critical", &"death", &"ranged"]:
			for next in [&"idle", &"move", &"critical", &"cast", &"ranged"]:
				for time in [0.0, 0.81, 97.13, 600.123]:
					rig.apply_presentation({"state":previous,"age":0.8,"duration":2.0,"motion_time":0.8})
					var fresh: Node2D = config.presentation_scene.instantiate()
					add_child(fresh)
					var context := {"state":next,"age":fmod(time,2.0),"duration":2.0,"motion_time":time}
					rig.apply_presentation(context)
					fresh.apply_presentation(context)
					for node in fresh.find_children("*", "Node2D",true,false):
						var actual: Node2D = rig.get_node(fresh.get_path_to(node))
						check(node.visible == actual.visible and node.transform.is_equal_approx(actual.transform) and node.modulate.is_equal_approx(actual.modulate), "No stale pose after %s to %s: %s" % [previous,next,node.name])
					fresh.free()
		clock.sync_health(0, 100)
		clock.advance(10)
		check(clock.texture() == config.frames.get_frame_texture(&"death", 7), "Approved death final frame")
		rig.free()
	print("HYBRID_CONTRACT_CHECK failures=", failures)
	get_tree().quit(failures)

func _check_animation_budget(library: AnimationLibrary) -> void:
	var keys := 0
	for name in library.get_animation_list():
		var clip := library.get_animation(name)
		check(clip.length <= 4.0, "No battle-length animation: " + name)
		check(clip.get_track_count() <= 64, "Sparse channels per clip: " + name)
		for track in clip.get_track_count():
			keys += clip.track_get_key_count(track)
			if clip.track_get_key_count(track) > 1:
				var changed := false
				for index in range(1,clip.track_get_key_count(track)):
					if clip.track_get_key_value(track,index) != clip.track_get_key_value(track,0): changed = true
				check(changed,"Constant tracks must use one key: " + name)
	check(keys <= 6000, "Key budget <= 6000, actual " + str(keys))
	check(FileAccess.get_file_as_bytes(library.resource_path).size() <= 524288, "Library byte budget <= 512 KiB")
	check(library.get_animation(&"RESET").get_track_count() < 70, "Reset only animated properties")
	for state in library.get_meta(&"cycle_layers", {}):
		for layer in library.get_meta(&"cycle_layers")[state]:
			check(library.has_animation(layer), "Every declared cycle resolves")

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
