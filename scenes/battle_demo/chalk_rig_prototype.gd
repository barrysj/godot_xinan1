extends Node2D
## PROTOTYPE — compare approved sequence frames with a cutout Bone2D rig.

const BattleAnimation = preload("res://scenes/battle_demo/battle_animation.gd")
const CHALK_MODEL = preload("res://resources/content/animations/chalk.tres")
const BODY = preload("res://design/concepts/chalk-spirit/chalk-rig/001/parts/body.png")
const LAUNCHER = preload("res://design/concepts/chalk-spirit/chalk-rig/001/parts/launcher.png")
const ORBITER_BACK = preload("res://design/concepts/chalk-spirit/chalk-rig/001/parts/orbiter_back.png")
const ORBITER_TOP = preload("res://design/concepts/chalk-spirit/chalk-rig/001/parts/orbiter_top.png")
const DUST = preload("res://design/concepts/chalk-spirit/chalk-rig/001/parts/dust_particle.png")
const PROJECTILE_STYLE = preload("res://resources/content/animations/chalk_projectile.tres")

const PAPER := Color("fff9ee")
const INK := Color("171922")
const BACKGROUND := Color("203a35")
const TEAL := Color("45d7bd")
const MAGENTA := Color("f04bc6")
const GOLD := Color("f0c95a")
const CYCLE_DURATION := 3.0
const ACTION_START := 1.0
const ACTION_PREVIEW_DURATION := 0.9
const SIMULATION_DURATION := 0.45
const WINDUP := 0.20

var elapsed := 0.0
var fixed_time := -1.0
var sequence_animation = BattleAnimation.new(CHALK_MODEL)
var sequence_sprite: Sprite2D
var rig: Node2D
var skeleton: Skeleton2D
var root_bone: Bone2D
var launcher_bone: Bone2D
var orbiter_back_bone: Bone2D
var orbiter_top_bone: Bone2D
var projectile: Sprite2D
var dust_layer: Node2D
var dust_sprites: Array[Sprite2D] = []
var preview_scale := 1.0
var left_anchor := Vector2.ZERO
var right_anchor := Vector2.ZERO
var phase_label := "待机"


func _ready() -> void:
	_build_sequence()
	_build_rig()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_apply_pose(0.0)
	var args := OS.get_cmdline_user_args()
	if "--chalk-rig-check" in args:
		call_deferred("_run_check")
	elif "--chalk-rig-capture" in args:
		call_deferred("_capture")


func _build_sequence() -> void:
	sequence_sprite = Sprite2D.new()
	sequence_sprite.name = "ApprovedSequenceFrames"
	add_child(sequence_sprite)


func _part(parent: Node, title: String, texture: Texture2D, position: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = title
	sprite.texture = texture
	sprite.position = position
	parent.add_child(sprite)
	return sprite


func _bone(parent: Node, title: String, position: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = title
	bone.position = position
	parent.add_child(bone)
	bone.rest = bone.transform
	return bone


func _build_rig() -> void:
	rig = Node2D.new()
	rig.name = "CutoutRig"
	add_child(rig)
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	rig.add_child(skeleton)
	root_bone = _bone(skeleton, "RootBone", Vector2.ZERO)
	_part(root_bone, "Body", BODY, Vector2(0, -144))
	launcher_bone = _bone(root_bone, "LauncherBone", Vector2(54, -145))
	_part(launcher_bone, "Launcher", LAUNCHER, Vector2(-54, 1))
	orbiter_back_bone = _bone(root_bone, "OrbiterBackBone", Vector2(-48.5, -182.5))
	_part(orbiter_back_bone, "OrbiterBack", ORBITER_BACK, Vector2(48.5, 38.5))
	orbiter_top_bone = _bone(root_bone, "OrbiterTopBone", Vector2(-28.5, -211.5))
	_part(orbiter_top_bone, "OrbiterTop", ORBITER_TOP, Vector2(28.5, 67.5))

	dust_layer = Node2D.new()
	dust_layer.name = "IndependentDust"
	rig.add_child(dust_layer)
	for index in 10:
		var mote := Sprite2D.new()
		mote.texture = DUST
		mote.name = "Dust%02d" % index
		mote.scale = Vector2.ONE * (0.55 + index % 3 * 0.22)
		dust_layer.add_child(mote)
		dust_sprites.append(mote)

	projectile = Sprite2D.new()
	projectile.name = "IndependentProjectile"
	projectile.texture = PROJECTILE_STYLE.texture
	projectile.scale = PROJECTILE_STYLE.display_size / Vector2(PROJECTILE_STYLE.texture.get_size())
	rig.add_child(projectile)


func _layout() -> void:
	var size := get_viewport_rect().size
	preview_scale = minf(size.x / 1920.0, size.y / 1080.0)
	left_anchor = Vector2(size.x * 0.28, size.y * 0.67)
	right_anchor = Vector2(size.x * 0.72, size.y * 0.67)
	sequence_sprite.scale = Vector2.ONE * preview_scale
	sequence_sprite.position = left_anchor + Vector2(0, -144 * preview_scale)
	rig.position = right_anchor
	rig.scale = Vector2.ONE * preview_scale
	queue_redraw()


func _action_age(time: float) -> float:
	if time < ACTION_START or time >= ACTION_START + ACTION_PREVIEW_DURATION:
		return -1.0
	return (time - ACTION_START) / ACTION_PREVIEW_DURATION * SIMULATION_DURATION


func _apply_pose(time: float) -> void:
	var cycle := fmod(time, CYCLE_DURATION)
	var action_age := _action_age(cycle)
	var bob := sin(cycle * TAU / CYCLE_DURATION * 2.0) * 4.0
	root_bone.position = Vector2(0, bob)
	root_bone.rotation = sin(cycle * TAU / CYCLE_DURATION) * 0.018
	launcher_bone.position = Vector2(54, -145)
	launcher_bone.rotation = sin(cycle * 2.2) * 0.025
	orbiter_back_bone.position = Vector2(-48.5, -182.5) + Vector2(cos(cycle * 2.4), sin(cycle * 2.4)) * 5.0
	orbiter_top_bone.position = Vector2(-28.5, -211.5) + Vector2(cos(cycle * 2.0 + 1.2), sin(cycle * 2.0 + 1.2)) * 4.0
	projectile.visible = false

	if action_age < 0:
		phase_label = "待机"
		sequence_animation.sync_motion(false, {})
		sequence_animation.state = &"idle"
		sequence_animation.age = cycle
	else:
		var action := {"age": action_age, "windup": WINDUP, "duration": SIMULATION_DURATION, "casts": false}
		sequence_animation.sync_motion(false, action)
		if action_age < WINDUP:
			phase_label = "前摇"
			var anticipation := action_age / WINDUP
			root_bone.position += Vector2(-8 * anticipation, 2 * anticipation)
			root_bone.rotation -= 0.045 * anticipation
			launcher_bone.position += Vector2(-3 * anticipation, 1 * anticipation)
			launcher_bone.rotation -= 0.08 * anticipation
			orbiter_back_bone.position.x -= 8 * anticipation
			orbiter_top_bone.position.x -= 5 * anticipation
		else:
			var recovery := clampf((action_age - WINDUP) / (SIMULATION_DURATION - WINDUP), 0.0, 1.0)
			phase_label = "出手" if recovery < 0.28 else "收招"
			var strength := pow(1.0 - recovery, 2.0)
			root_bone.position += Vector2(7 * strength, 0)
			root_bone.rotation += 0.035 * strength
			launcher_bone.position += Vector2(8 * strength, -2 * strength)
			launcher_bone.rotation += 0.05 * strength
			projectile.visible = recovery < 0.72
			projectile.position = root_bone.position + Vector2(92 + recovery * 180, -150)
	sequence_sprite.texture = sequence_animation.texture()
	_update_dust(cycle, action_age)
	queue_redraw()


func _update_dust(time: float, action_age: float) -> void:
	var burst := 1.0
	if action_age >= WINDUP:
		burst = 1.6 - clampf((action_age - WINDUP) / (SIMULATION_DURATION - WINDUP), 0.0, 1.0) * 0.6
	for index in dust_sprites.size():
		var mote := dust_sprites[index]
		var progress := fmod(time * (0.42 + index % 4 * 0.06) + index * 0.137, 1.0)
		mote.position = Vector2(
			sin(progress * TAU + index) * (9 + index % 3 * 3) * burst,
			-62 + progress * 78
		)
		mote.modulate = Color(0.88, 0.91, 0.91, (1.0 - progress) * 0.68)


func _process(delta: float) -> void:
	if fixed_time < 0:
		elapsed += delta
	_apply_pose(fixed_time if fixed_time >= 0 else elapsed)


func _text(position: Vector2, value: String, size: int, color := PAPER) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	draw_rect(Rect2(36, 28, size.x - 72, 78), PAPER)
	_text(Vector2(62, 78), "粉笔精灵动画生产原型", 30, INK)
	_text(Vector2(size.x - 470, 76), "序列帧 vs 分层骨骼 · 0.5×", 20, INK)
	draw_line(Vector2(size.x * 0.5, 142), Vector2(size.x * 0.5, size.y - 118), Color(PAPER, 0.28), 2)
	_text(Vector2(size.x * 0.17, 178), "正式 005 · 序列帧", 24)
	_text(Vector2(size.x * 0.61, 178), "原型 001 · 分层骨骼", 24)
	_text(Vector2(size.x * 0.17, 214), "每个动作重新绘制完整角色", 17, Color(PAPER, 0.7))
	_text(Vector2(size.x * 0.61, 214), "同一组部件连续插值", 17, Color(PAPER, 0.7))
	for anchor in [left_anchor, right_anchor]:
		draw_line(anchor - Vector2(12, 0), anchor + Vector2(12, 0), GOLD, 2)
		draw_line(anchor - Vector2(0, 12), anchor + Vector2(0, 12), GOLD, 2)
	_text(Vector2(size.x * 0.5 - 36, 270), phase_label, 28, MAGENTA if phase_label == "出手" else TEAL)
	draw_rect(Rect2(36, size.y - 94, size.x - 72, 54), Color(PAPER, 0.96))
	_text(Vector2(58, size.y - 58), "骨骼：主体 / 发射臂 / 浮游块 ×2    独立层：粉尘 / 弹体    当前验证：待机 → 前摇 → 出手 → 收招", 18, INK)


func _run_check() -> void:
	set_process(false)
	var failures := 0
	if root_bone == null or launcher_bone == null or launcher_bone.get_parent() != root_bone:
		failures += 1
	if dust_sprites.size() != 10 or projectile.texture == null:
		failures += 1
	_apply_pose(0.4)
	var idle_launcher := launcher_bone.transform
	_apply_pose(1.38)
	if launcher_bone.transform.is_equal_approx(idle_launcher):
		failures += 1
	if sequence_sprite.texture == null:
		failures += 1
	print("CHALK_RIG_CHECK bones=4 dust=10 sequence=approved-005 failures=", failures)
	get_tree().quit(failures)


func _capture_frame(path: String, resolution: Vector2i, time: float) -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = resolution
	fixed_time = time
	_layout()
	_apply_pose(time)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	assert(screenshot.get_size() == resolution)
	screenshot.save_png(path)


func _capture() -> void:
	set_process(false)
	var review := "res://design/concepts/chalk-spirit/chalk-rig/001/review/"
	for state in [
		["idle", 0.35], ["windup", 1.30], ["release", 1.43], ["recovery", 1.72],
	]:
		await _capture_frame(review + "rig-%s-1920x1080.png" % state[0], Vector2i(1920, 1080), state[1])
	for resolution in [Vector2i(2560, 1440), Vector2i(1920, 1200)]:
		await _capture_frame(
			review + "rig-release-%dx%d.png" % [resolution.x, resolution.y],
			resolution,
			1.43,
		)
	var frame_directory := "res://.godot/chalk-rig-frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frame_directory))
	for index in 40:
		await _capture_frame(
			frame_directory + "/frame-%03d.png" % index,
			Vector2i(1280, 720),
			3.0 * index / 39.0,
		)
	print("CHALK_RIG_CAPTURE states=4 resolutions=3 frames=40")
	get_tree().quit()
