extends Node
## Candidate contract validation using the real shared presentation controller.
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const PngLoader = preload("res://tools/art/animation/preview_png_loader.gd")
var failures := 0
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var version := "asset_001"
	var production := "--production" in OS.get_cmdline_user_args()
	if not production:
		ResourceLoader.add_resource_format_loader(PngLoader.new(), true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--candidate-version="):
			version = arg.trim_prefix("--candidate-version=")
	var version_pattern := RegEx.new()
	version_pattern.compile("^(tmp|asset)_[0-9]{3}$")
	if version_pattern.search(version) == null:
		push_error("Expected --candidate-version=tmp_NNN or asset_NNN")
		get_tree().quit(1)
		return
	for enemy in ["keycap-brawler", "projector", "return-stamp", "great-volume-boss", "cyber-librarian"]:
		var folder := "res://design/concepts/enemy/%s/%s/" % [enemy, version]
		if production:
			folder = "res://assets/art/characters/%s/" % enemy.replace("-", "_")
		var config = load(folder + "battle_animation.tres")
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "rig_manifest.json"))
		var actions: Array = data.frame_actions
		check(actions.size() == 7, enemy + " seven actions")
		check(config.anchor == Vector2(0.5, 0.875), enemy + " anchor")
		check(config.flip_with_facing, enemy + " facing")
		var rig: Node2D = config.presentation_scene.instantiate()
		add_child(rig)
		var mode := 1 if "melee" in actions else 2
		var clock = Animator.new(config, mode)
		var keys := 0
		for clip_name in config.animation_library.get_animation_list():
			var clip: Animation = config.animation_library.get_animation(clip_name)
			check(clip.length <= 2.0, enemy + " short animation")
			for channel in clip.get_track_count():
				keys += clip.track_get_key_count(channel)
				if clip.track_get_key_count(channel) > 1:
					var changed := false
					for index in range(1, clip.track_get_key_count(channel)):
						if clip.track_get_key_value(channel, index) != clip.track_get_key_value(channel, 0): changed = true
					check(changed, enemy + " constant channel compacted")
		check(keys <= data.animation_budget.max_keys, enemy + " key budget")
		for action in actions:
			check(clock._has_clip(StringName(action)), enemy + " clip " + action)
			check(rig.handles_presentation_state(StringName(action)) == (action in data.skeleton_actions), enemy + " backend " + action)
			for index in config.frames.get_frame_count(StringName(action)):
				check(config.frames.get_frame_texture(StringName(action), index).get_size() == Vector2(640, 640), enemy + " unified frame")
			if action in ["melee", "ranged", "cast"]:
				clock.state = StringName(action)
				clock.age = clock._duration(StringName(action)) * config.impact_ratio
				check(clock.texture() == config.frames.get_frame_texture(StringName(action), 3), enemy + " release frame " + action)
			if action not in data.skeleton_actions: continue
			# Inspect real evaluated properties, so a valid but motionless rig fails.
			rig.apply_presentation({"state":StringName(action), "age":0.0, "duration":1.0, "motion_time":0.0})
			var root: Node2D = rig.get_node("Rig/Skeleton2D/RootBone")
			var initial := root.transform
			rig.apply_presentation({"state":StringName(action), "age":0.25, "duration":1.0, "motion_time":0.25})
			check(not root.transform.is_equal_approx(initial), enemy + " evaluated motion " + action)
			rig.apply_presentation({"state":StringName(action), "age":0.45, "duration":1.0, "motion_time":0.45})
			if action == "critical":
				check(rig.get_node("Rig/Skeleton2D/RootBone/CriticalPose").visible, enemy + " critical authored silhouette")
			if action == "cast" and enemy in ["return-stamp", "cyber-librarian"]:
				check(rig.get_node("Rig/CastCue").modulate.a > 0.9, enemy + " cast cue at release")
			if action == "cast" and enemy == "great-volume-boss":
				check(rig.get_node("Rig/Skeleton2D/RootBone/OpenBook").visible, enemy + " cast open book")
				check(rig.get_node("Rig/Plane0").visible, enemy + " cast plane release")
			if rig.has_node("Rig/CastLight"):
				check(is_equal_approx(rig.get_node("Rig/CastLight").modulate.a, 1.0 if action == "cast" else 0.0), enemy + " cast light release and no state leak")
				if action == "cast" and enemy == "cyber-librarian":
					check(rig.get_node("Rig/Skeleton2D/RootBone/CastPose").visible, enemy + " clear cast silhouette")
				if action == "ranged" and enemy == "cyber-librarian":
					check(rig.get_node("Rig/Skeleton2D/RootBone/AttackPose").visible and rig.get_node("Rig/AttackCue").modulate.a > 0.99, enemy + " clear attack silhouette and book stream")
			for previous in data.skeleton_actions:
				for fraction in [0.0, 0.45, 0.99]:
					rig.apply_presentation({"state":StringName(previous), "age":0.43, "duration":1.0, "motion_time":3.4})
					var fresh: Node2D = config.presentation_scene.instantiate()
					add_child(fresh)
					var context := {"state":StringName(action), "age":fraction, "duration":1.0, "motion_time":3.7,
						"display_size":config.display_size, "center":Vector2(150, 200), "facing_right":false}
					rig.apply_presentation(context)
					fresh.apply_presentation(context)
					for node in fresh.find_children("*", "Node2D", true, false):
						var actual: Node2D = rig.get_node(fresh.get_path_to(node))
						check(node.visible == actual.visible and node.transform.is_equal_approx(actual.transform), enemy + " clean transition " + previous + " -> " + action + ":" + node.name)
					check(not fresh.player.is_playing(), enemy + " manual authoritative clock")
					check(fresh.scale.x < 0.0, enemy + " left facing")
					fresh.free()
		clock.sync_health(0, 100)
		clock.advance(10)
		check(clock.texture() == config.frames.get_frame_texture(&"death", 2), enemy + " death freezes final pose")
		print("LIBRARY_ENEMY_CONTRACT ", enemy, " keys=", keys)
		rig.free()
	print("LIBRARY_ENEMY_CONTRACT_CHECK checks=", checks, " failures=", failures)
	get_tree().quit(failures)
