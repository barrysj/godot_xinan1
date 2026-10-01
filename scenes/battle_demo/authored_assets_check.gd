extends Node
const Content = preload("res://game/content/content_db.gd")
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const ROLES = ["guard", "archer", "healer", "striker", "inventor"]
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	var models := 0
	for unit in Content.characters():
		if not unit.id in ROLES: continue
		var model = unit.battle_animation
		check(model != null, unit.id + " has the approved animation")
		if model == null: continue
		models += 1
		var prefix: String = "res://assets/art/characters/" + unit.id + "/"
		check(model.resource_path == prefix + "battle_animation.tres", unit.id + " uses the formal package")
		check(unit.portrait is AtlasTexture and unit.portrait.atlas.resource_path.begins_with(prefix + "frames/"), unit.id + " portrait uses the new identity")
		var attack: StringName = &"ranged" if unit.resolved_attack_modes() == 2 else &"melee"
		var canvas := Vector2(1024, 512) if unit.id == "guard" else Vector2(512, 512)
		for clip in [&"idle", &"move", attack, &"cast", &"hurt", &"critical", &"death"]:
			check(model.frames.has_animation(clip), unit.id + " has " + clip)
			if not model.frames.has_animation(clip): continue
			check(model.frames.get_frame_count(clip) > 0, unit.id + " nonempty " + clip)
			for index in model.frames.get_frame_count(clip):
				var frame = model.frames.get_frame_texture(clip, index)
				check(frame != null and frame.get_size() == canvas, unit.id + " consistent canvas")
				check(frame.resource_path.begins_with(prefix + "frames/"), unit.id + " frame uses the formal package")
		var idle = model.frames.get_frame_texture(&"idle", 0)
		var critical = model.frames.get_frame_texture(&"critical", 0)
		var death = model.frames.get_frame_texture(&"death", 0)
		check(idle.get_image().get_data() != critical.get_image().get_data(), unit.id + " critical is a different drawn pose")
		check(idle.get_image().get_data() != death.get_image().get_data(), unit.id + " death is a different drawn pose")
		check(critical.get_image().get_data() != death.get_image().get_data(), unit.id + " defeat poses are distinct")
		var animator = Animator.new(model, unit.resolved_attack_modes())
		animator.sync_health(10, 100)
		animator.sync_motion(false, {})
		check(animator.state == &"critical" and animator.texture() == critical, unit.id + " low health selects critical")
		animator.sync_health(0, 100)
		animator.sync_motion(false, {})
		animator.advance(5)
		check(animator.state == &"death" and animator.texture() == death, unit.id + " death holds fallen pose")
		if unit.id != "guard":
			check(model.presentation_scene != null and model.animation_library != null, unit.id + " has hybrid presentation")
		print("AUTHORED_MODEL ", unit.id, " seven clips validated")
	check(models == ROLES.size(), "All five approved roles are integrated")
	if "--capture" in OS.get_cmdline_user_args():
		await capture_battle()
	print("AUTHORED_ASSETS_CHECK models=", models, " failures=", failures)
	get_tree().quit(failures)

func capture_battle() -> void:
	var battle = load("res://scenes/battle_demo/battle_demo.tscn").instantiate()
	add_child(battle)
	# Two legal four-unit parties cover all five roles without bypassing deployment.
	for party in 2:
		for size in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1920, 1200)]:
			get_window().size = size
			battle.formation = [0, -1, 3 if party == 0 else 4, 2, 1, -1]
			battle._start()
			await get_tree().create_timer(1.0).timeout
			battle.paused = true
			check(battle.phase == "battle" and battle.units.filter(func(unit): return unit.side == 0).size() == 4, "Legal four-unit battle started")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var path := "res://.godot/characters-battle-party%d-%dx%d.png" % [party + 1, size.x, size.y]
			check(get_viewport().get_texture().get_image().save_png(path) == OK, "Saved actual battle " + str(size))
