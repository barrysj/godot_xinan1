extends Node
const Shield = preload("res://resources/content/animations/guard_shield.tres")
const ProjectileStyle = preload("res://game/content/battle_projectile_style.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _ready() -> void:
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
