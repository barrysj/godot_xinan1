extends Node
const Content = preload("res://game/content/content_db.gd")
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	var models := 0
	for unit in Content.characters():
		var model = unit.battle_animation
		if model == null: continue
		models += 1
		check(unit.portrait is AtlasTexture and unit.portrait.atlas.resource_path.begins_with("res://assets/art/characters/"), unit.id + " has matching illustrated portrait")
		check(model.frames != null, unit.id + " has actual frames")
		for clip in [&"idle", &"move", &"attack", &"cast", &"hurt", &"critical", &"death"]:
			check(model.frames.has_animation(clip), unit.id + " has " + clip)
			var regions = {}
			for i in model.frames.get_frame_count(clip):
				var frame = model.frames.get_frame_texture(clip, i)
				check(frame is AtlasTexture and frame.get_size() == Vector2(384, 384), "Normalized frame canvas")
				check(frame.atlas.resource_path == "res://assets/art/characters/" + unit.id + "/battle_sheet.png", "Runtime uses illustrated source, not placeholder")
				regions[frame.region] = true
			if clip in [&"move", &"attack", &"cast", &"hurt", &"death"]:
				check(regions.size() >= 3, unit.id + " distinct drawn poses for " + clip)
		var animator = Animator.new(model)
		for cast in [false, true]:
			var clip: StringName = &"cast" if cast else &"attack"
			animator.sync_motion(false, {"age": 0.2, "windup": 0.2, "duration": 0.45, "casts": cast})
			check(animator.texture() == model.frames.get_frame_texture(clip, 2), unit.id + " release selects actual extended pose")
		animator.sync_health(0, 100)
		animator.sync_motion(false, {})
		animator.advance(2)
		check(animator.texture() == model.frames.get_frame_texture(&"death", 2), unit.id + " holds drawn fallen pose")
		print("AUTHORED_MODEL ", unit.id, " seven clips validated")
	check(models >= (2 if "--require-two-models" in OS.get_cmdline_user_args() else 1), "Required number of illustrated battle models")
	print("AUTHORED_ASSETS_CHECK models=", models, " failures=", failures)
	get_tree().quit(failures)
