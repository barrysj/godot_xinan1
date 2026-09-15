extends Node
const Shield = preload("res://resources/content/animations/guard_shield.tres")
const ProjectileStyle = preload("res://game/content/battle_projectile_style.gd")
const Chalk = preload("res://resources/content/enemies/chalk.tres")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
	check(Chalk.portrait is AtlasTexture and Chalk.portrait.atlas.resource_path == "res://assets/art/characters/chalk_spirit/006/locomotion_sheet.png", "Chalk Spirit uses the approved portrait source")
	check(Chalk.battle_animation != null, "Chalk Spirit has an approved battle animation")
	if Chalk.battle_animation != null:
		var chalk_model = Chalk.battle_animation
		var expected_counts = {&"idle": 4, &"move": 8, &"attack": 8, &"cast": 8, &"hurt": 4, &"critical": 4, &"death": 8}
		var approved_sheets = [
			"res://assets/art/characters/chalk_spirit/006/locomotion_sheet.png",
			"res://assets/art/characters/chalk_spirit/006/combat_sheet.png",
			"res://assets/art/characters/chalk_spirit/006/reaction_sheet.png",
		]
		check(chalk_model.presentation_scene != null, "Chalk Spirit has a hybrid presentation scene")
		if chalk_model.presentation_scene != null:
			check(chalk_model.presentation_scene.resource_path == "res://scenes/battle_demo/presentations/chalk_spirit_presentation.tscn", "Chalk Spirit presentation resource is stable")
		for clip in expected_counts:
			check(chalk_model.frames.has_animation(clip), "Chalk Spirit has " + clip)
			check(chalk_model.frames.get_frame_count(clip) == expected_counts[clip], "Chalk Spirit frame count for " + clip)
			for index in chalk_model.frames.get_frame_count(clip):
				var frame = chalk_model.frames.get_frame_texture(clip, index)
				check(frame is AtlasTexture and frame.get_size() == Vector2(384, 384), "Chalk Spirit normalized frame")
				check(frame is AtlasTexture and frame.atlas.resource_path in approved_sheets, "Chalk Spirit uses approved sheets")
		check(chalk_model.projectile_style != null and chalk_model.projectile_style.usable(), "Chalk Spirit has an approved projectile")
		if chalk_model.projectile_style != null:
			check(chalk_model.projectile_style.resource_path == "res://resources/content/animations/chalk_projectile.tres", "Chalk Spirit projectile resource is stable")
			check(chalk_model.projectile_style.texture.resource_path == "res://assets/art/effects/chalk_projectile/projectile.png", "Chalk Spirit projectile uses approved art")
			check(chalk_model.projectile_style.display_size == Vector2(32, 16), "Chalk Spirit projectile display size")
	check(is_equal_approx(Shield.duration(), 16.0 / 24.0), "Authored 16-frame burst duration")
	var regions := {}
	for i in 16:
		var frame = Shield.texture((i + 0.1) / 24.0)
		check(frame is AtlasTexture and frame.atlas.resource_path.begins_with("res://assets/art/effects/"), "Actual illustrated VFX")
		regions[frame.region] = true
	check(regions.size() == 16 and Shield.texture(Shield.duration()) == null, "Distinct frames and finite playback")
	var preview = load("res://scenes/battle_demo/motion_preview.tscn").instantiate()
	add_child(preview)
	preview.set_process(false)
	preview.repeat = false
	preview.mode = 4
	preview._reset_preview()
	var ally = preview.units[0].duplicate()
	ally.id = 2
	ally.position = Vector2(2, 4)
	ally.timer = 1000.0
	preview.units.append(ally)
	preview.simulation.reset(preview.units)
	preview.units[0].timer = 0
	check(preview.simulation.request_action(0, 1), "Group cast request accepted")
	for i in 3: preview.advance_preview(0.05)
	check(preview.skill_effects.is_empty(), "No burst before actual release")
	preview.advance_preview(0.05)
	check(preview.skill_effects.size() == 1, "One burst for a group cast")
	if preview.skill_effects.is_empty():
		preview.free()
		get_tree().quit(1)
		return
	check(preview.units[0].shield > 0 and ally.shield > 0, "Same release shields multiple allies")
	preview.paused = true
	var age: float = preview.skill_effects[0].age
	preview.advance_preview(1.0)
	check(preview.skill_effects[0].age == age, "Pause freezes effect")
	preview.paused = false
	preview.speed = 2
	preview.advance_preview(0.05)
	check(is_equal_approx(preview.skill_effects[0].age, age + 0.1), "Double speed drives effect clock")
	check(Shield.texture(age) != Shield.texture(preview.skill_effects[0].age), "Runtime advances drawn frame")
	preview.skill_effects[0].age = 0
	check(preview._finish_delay() >= Shield.duration(), "Final burst participates in finish delay")
	preview.advance_preview(0.4)
	check(preview.skill_effects.is_empty(), "Completed burst is reclaimed")
	preview.speed = 1
	preview._reset_preview()
	for i in 4: preview.advance_preview(0.05)
	check(preview.skill_effects.size() == 1, "Replay creates a fresh burst")
	preview._reset_preview()
	check(preview.skill_effects.is_empty(), "Restart removes old burst")
	# Killing the caster during anticipation must not emit a release VFX.
	preview.units[0].hp = 0
	for i in 6: preview.advance_preview(0.05)
	check(preview.skill_effects.is_empty(), "Cancelled cast never displays burst")
	preview.mode = 3
	preview._reset_preview()
	for i in 4: preview.advance_preview(0.05)
	var shot: Dictionary = preview.simulation.projectiles[0]
	var shooter: Dictionary = preview.units[0]
	var target: Dictionary = preview.units[1]
	var projectile_style = ProjectileStyle.new()
	check(not projectile_style.usable(), "Projectile style requires a texture")
	projectile_style.texture = load("res://assets/pixel/kenney/tiny-town.png")
	check(projectile_style.usable(), "Configured projectile style is usable")
	shooter.battle_animation = shooter.battle_animation.duplicate(true)
	shooter.battle_animation.projectile_style = projectile_style
	check(preview._projectile_style(shot) == projectile_style, "Projectile presentation resolves from the shooter")
	shooter.battle_animation.projectile_style = null
	check(preview._projectile_style(shot) == null, "Absent projectile style preserves the fallback")
	check(preview._projectile_point(shot, 0).is_equal_approx(preview._project(shot.origin) + shooter.battle_animation.launch_offset), "Projectile starts at illustrated weapon")
	var arrived = shot.duplicate()
	arrived.position = target.position
	arrived.previous_position = target.position
	check(preview._projectile_point(arrived, 1).is_equal_approx(preview._project(target.position) + preview._hit_offset(target)), "Projectile ends at impact anchor")
	# Moving the caster after release must not drag the already launched shot.
	var detached: Vector2 = preview._projectile_point(shot, 0)
	shooter.position += Vector2(0, 2)
	check(preview._projectile_point(shot, 0) == detached, "Launched projectile retains its origin")
	preview.free()
	print("SKILL_VFX_CHECK failures=", failures)
	get_tree().quit(failures)
