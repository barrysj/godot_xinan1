extends Node
const Shield = preload("res://resources/content/animations/guard_shield.tres")
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
	preview.free()
	print("SKILL_VFX_CHECK failures=", failures)
	get_tree().quit(failures)
