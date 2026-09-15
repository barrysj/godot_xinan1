extends Node2D
## PROTOTYPE — compare approved sequence frames with a hybrid cutout Bone2D rig.

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
const MODES: Array[StringName] = [&"idle", &"move", &"attack", &"cast", &"hurt", &"critical", &"death"]
const MODE_NAMES := {
	&"idle": "待机", &"move": "移动", &"attack": "远程", &"cast": "施法",
	&"hurt": "受击", &"critical": "濒危", &"death": "退场",
}
const MODE_DURATIONS := {
	&"idle": 1.5, &"move": 1.8, &"attack": 2.0, &"cast": 2.0,
	&"hurt": 1.4, &"critical": 1.8, &"death": 2.2,
}
const CLIP_DURATIONS := {
	&"attack": 8.0 / 12.0, &"cast": 8.0 / 12.0,
	&"hurt": 4.0 / 12.0, &"death": 8.0 / 8.0,
}
const TOUR_DURATION := 12.7

var elapsed := 0.0
var fixed_time := -1.0
var fixed_mode: StringName = &""
var sequence_animation = BattleAnimation.new(CHALK_MODEL)
var sequence_sprite: Sprite2D
var hybrid_sequence_sprite: Sprite2D
var rig: Node2D
var skeleton: Skeleton2D
var root_bone: Bone2D
var launcher_bone: Bone2D
var orbiter_back_bone: Bone2D
var orbiter_top_bone: Bone2D
var projectile: Sprite2D
var muzzle_flash: Polygon2D
var cast_effect: Node2D
var cast_halo: Polygon2D
var cast_ring_outer: Line2D
var cast_ring_inner: Line2D
var cast_core: Polygon2D
var cast_core_highlight: Polygon2D
var cast_motes: Array[Sprite2D] = []
var dust_layer: Node2D
var dust_sprites: Array[Sprite2D] = []
var preview_scale := 1.0
var left_anchor := Vector2.ZERO
var right_anchor := Vector2.ZERO
var mode_label := "待机"
var phase_label := "骨骼循环"
var embedded_preview := false


func configure_motion_preview() -> void:
	embedded_preview = true


func handles_motion_preview_state(state: StringName) -> bool:
	return state in [&"idle", &"move", &"attack", &"cast", &"hurt", &"critical"]


func _ready() -> void:
	# Painterly cutout parts rotate and shrink; nearest sampling inherited from the
	# pixel battle scene makes their edges crawl between frames.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_sequence()
	_build_rig()
	if embedded_preview:
		sequence_sprite.visible = false
		hybrid_sequence_sprite.position = Vector2(0, -144)
		rig.position = Vector2.ZERO
		set_process(false)
		return
	get_viewport().size_changed.connect(_layout)
	_layout()
	_apply_mode(&"idle", 0.0)
	var args := OS.get_cmdline_user_args()
	if "--chalk-rig-check" in args:
		call_deferred("_run_check")
	elif "--chalk-rig-capture" in args:
		call_deferred("_capture")


func _build_sequence() -> void:
	sequence_sprite = Sprite2D.new()
	sequence_sprite.name = "ApprovedSequenceFrames"
	add_child(sequence_sprite)
	hybrid_sequence_sprite = Sprite2D.new()
	hybrid_sequence_sprite.name = "PreservedDeathSequence"
	add_child(hybrid_sequence_sprite)


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
	# These bones are transform pivots for rigid sprites, not length-driven IK chains.
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(1.0)
	bone.set_bone_angle(0.0)
	parent.add_child(bone)
	bone.rest = bone.transform
	return bone


func _regular_polygon(points: int, radius: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in points:
		var angle := TAU * index / points
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon


func _ring_points(points: int, radius: float, alternate: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in points:
		var angle := TAU * index / points
		var point_radius := radius + (alternate if index % 2 == 0 else -alternate)
		polygon.append(Vector2(cos(angle), sin(angle)) * point_radius)
	polygon.append(polygon[0])
	return polygon


func _build_rig() -> void:
	rig = Node2D.new()
	rig.name = "HybridCutoutRig"
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
	projectile.scale = PROJECTILE_STYLE.display_size / Vector2(PROJECTILE_STYLE.texture.get_size()) * 1.25
	rig.add_child(projectile)

	muzzle_flash = Polygon2D.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(-18, -6), Vector2(-9, 0), Vector2(-24, 8),
		Vector2(-6, 5), Vector2(-10, 18), Vector2(0, 8), Vector2(12, 15),
		Vector2(8, 3), Vector2(22, 0), Vector2(8, -3), Vector2(12, -15),
		Vector2(0, -8), Vector2(-10, -18),
	])
	muzzle_flash.color = GOLD
	muzzle_flash.position = Vector2(126, -132)
	rig.add_child(muzzle_flash)

	cast_effect = Node2D.new()
	cast_effect.name = "LayeredCastSigil"
	cast_effect.position = Vector2(96, -166)
	rig.add_child(cast_effect)
	rig.move_child(cast_effect, 0)

	cast_halo = Polygon2D.new()
	cast_halo.name = "SoftHalo"
	cast_halo.polygon = _regular_polygon(24, 42.0)
	cast_halo.color = Color(TEAL, 0.14)
	cast_effect.add_child(cast_halo)

	cast_ring_outer = Line2D.new()
	cast_ring_outer.name = "TealChalkRing"
	cast_ring_outer.points = _ring_points(12, 50.0, 4.0)
	cast_ring_outer.width = 3.5
	cast_ring_outer.default_color = Color(TEAL, 0.88)
	cast_effect.add_child(cast_ring_outer)

	cast_ring_inner = Line2D.new()
	cast_ring_inner.name = "MagentaRuneRing"
	cast_ring_inner.points = _ring_points(8, 30.0, 5.0)
	cast_ring_inner.width = 2.5
	cast_ring_inner.default_color = Color(MAGENTA, 0.92)
	cast_effect.add_child(cast_ring_inner)

	cast_core = Polygon2D.new()
	cast_core.name = "MagentaDiamondCore"
	cast_core.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(14, 0), Vector2(0, 18), Vector2(-14, 0),
	])
	cast_core.color = Color(MAGENTA, 0.88)
	cast_effect.add_child(cast_core)

	cast_core_highlight = Polygon2D.new()
	cast_core_highlight.name = "PaperCore"
	cast_core_highlight.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0),
	])
	cast_core_highlight.color = Color(PAPER, 0.94)
	cast_effect.add_child(cast_core_highlight)

	for index in 8:
		var mote := Sprite2D.new()
		mote.name = "CastMote%02d" % index
		mote.texture = DUST
		mote.modulate = Color(PAPER if index % 2 == 0 else MAGENTA, 0.9)
		cast_effect.add_child(mote)
		cast_motes.append(mote)


func _layout() -> void:
	if embedded_preview: return
	var size := get_viewport_rect().size
	preview_scale = minf(size.x / 1920.0, size.y / 1080.0)
	left_anchor = Vector2(size.x * 0.28, size.y * 0.67)
	right_anchor = Vector2(size.x * 0.72, size.y * 0.67)
	sequence_sprite.scale = Vector2.ONE * preview_scale
	sequence_sprite.position = left_anchor + Vector2(0, -144 * preview_scale)
	hybrid_sequence_sprite.scale = Vector2.ONE * preview_scale
	hybrid_sequence_sprite.position = right_anchor + Vector2(0, -144 * preview_scale)
	rig.position = right_anchor
	rig.scale = Vector2.ONE * preview_scale
	queue_redraw()


func _tour_state(time: float) -> Array:
	var cursor := fmod(time, TOUR_DURATION)
	for mode in MODES:
		var duration: float = MODE_DURATIONS[mode]
		if cursor < duration:
			return [mode, cursor]
		cursor -= duration
	return [&"idle", 0.0]


func _set_sequence(mode: StringName, time: float) -> void:
	var clip := mode
	var clip_age := time
	if mode in [&"attack", &"cast"]:
		if time < 0.25 or time >= 1.70:
			clip = &"idle"
			clip_age = time
		else:
			clip_age = clampf((time - 0.25) / 1.30, 0.0, 1.0) * CLIP_DURATIONS[mode]
	elif mode == &"hurt":
		if time < 0.15 or time >= 0.85:
			clip = &"idle"
			clip_age = time
		else:
			clip_age = clampf((time - 0.15) / 0.60, 0.0, 1.0) * CLIP_DURATIONS[mode]
	elif mode == &"death":
		if time < 0.12:
			clip = &"idle"
			clip_age = time
		else:
			clip_age = clampf((time - 0.12) / 1.55, 0.0, 1.0) * CLIP_DURATIONS[mode]
	sequence_animation.state = clip
	sequence_animation.age = clip_age
	sequence_sprite.texture = sequence_animation.texture()
	hybrid_sequence_sprite.texture = sequence_sprite.texture


func _reset_rig(time: float) -> void:
	rig.visible = true
	hybrid_sequence_sprite.visible = false
	rig.modulate = Color.WHITE
	root_bone.position = Vector2(0, sin(time * 3.2) * 2.0)
	root_bone.rotation = 0.0
	launcher_bone.position = Vector2(54, -145)
	launcher_bone.rotation = 0.0
	orbiter_back_bone.position = Vector2(-48.5, -182.5)
	orbiter_back_bone.rotation = 0.0
	orbiter_top_bone.position = Vector2(-28.5, -211.5)
	orbiter_top_bone.rotation = 0.0
	projectile.visible = false
	muzzle_flash.visible = false
	cast_effect.visible = false
	cast_effect.modulate = Color.WHITE


func _apply_idle(time: float) -> void:
	phase_label = "骨骼循环"
	root_bone.position.y += sin(time * TAU / 1.5) * 4.0
	root_bone.rotation = sin(time * TAU / 3.0) * 0.018
	launcher_bone.rotation = sin(time * 2.2) * 0.025
	orbiter_back_bone.position += Vector2(cos(time * 2.4), sin(time * 2.4)) * 5.0
	orbiter_top_bone.position += Vector2(cos(time * 2.0 + 1.2), sin(time * 2.0 + 1.2)) * 4.0
	_update_dust(time, 1.0)


func _apply_move(time: float) -> void:
	phase_label = "骨骼循环"
	var stride := sin(time * TAU / 0.48)
	root_bone.position += Vector2(stride * 5.0, -absf(stride) * 10.0)
	root_bone.rotation = stride * 0.055
	launcher_bone.rotation = -stride * 0.075
	orbiter_back_bone.position += Vector2(-stride * 13.0, cos(time * TAU / 0.48) * 8.0)
	orbiter_top_bone.position += Vector2(-stride * 9.0, -cos(time * TAU / 0.48) * 6.0)
	_update_dust(time * 1.35, 1.35)


func _apply_attack(time: float) -> void:
	if time < 0.25:
		phase_label = "准备"
		_apply_idle(time)
	elif time < 0.72:
		phase_label = "前倾架枪"
		var weight := smoothstep(0.0, 1.0, (time - 0.25) / 0.47)
		root_bone.position += Vector2(9.0, 3.0) * weight
		root_bone.rotation = 0.045 * weight
		launcher_bone.position += Vector2(-5.0, 1.0) * weight
		launcher_bone.rotation = -0.055 * weight
		orbiter_back_bone.position += Vector2(-10.0, 3.0) * weight
		orbiter_top_bone.position += Vector2(-7.0, -4.0) * weight
		_update_dust(time, 0.75)
	elif time < 1.0:
		phase_label = "后坐出手"
		var snap := smoothstep(0.0, 1.0, minf((time - 0.72) / 0.12, 1.0))
		root_bone.position += Vector2(lerpf(9.0, -19.0, snap), lerpf(3.0, -3.0, snap))
		root_bone.rotation = lerpf(0.045, -0.11, snap)
		launcher_bone.position += Vector2(lerpf(-5.0, 2.0, snap), lerpf(1.0, -3.0, snap))
		launcher_bone.rotation = lerpf(-0.055, -0.13, snap)
		orbiter_back_bone.position += Vector2(9.0, 1.0) * snap
		orbiter_top_bone.position += Vector2(7.0, -1.0) * snap
		var fire_progress := clampf((time - 0.78) / 0.22, 0.0, 1.0)
		projectile.visible = not embedded_preview and time >= 0.78
		projectile.position = Vector2(126.0 + fire_progress * 230.0, -132.0)
		muzzle_flash.visible = time >= 0.76 and time < 0.91
		muzzle_flash.scale = Vector2.ONE * (0.75 + sin(fire_progress * PI) * 0.85)
		_update_dust(time, 1.8)
	elif time < 1.65:
		phase_label = "后坐收招"
		var recovery := clampf((time - 1.0) / 0.65, 0.0, 1.0)
		var strength := pow(1.0 - recovery, 2.0)
		root_bone.position += Vector2(-17.0, -3.0) * strength
		root_bone.rotation = -0.095 * strength
		launcher_bone.position += Vector2(2.0, -2.0) * strength
		launcher_bone.rotation = -0.11 * strength
		orbiter_back_bone.position += Vector2(8.0, 2.0) * strength
		orbiter_top_bone.position += Vector2(6.0, -1.0) * strength
		projectile.visible = not embedded_preview and recovery < 0.52
		projectile.position = Vector2(356.0 + recovery * 100.0, -132.0)
		_update_dust(time, 1.0 + strength * 0.6)
	else:
		phase_label = "返回待机"
		_apply_idle(time)


func _update_cast_effect(time: float, energy: float, release: float = 0.0) -> void:
	cast_effect.visible = true
	cast_effect.scale = Vector2.ONE * lerpf(0.36, 1.0, energy) * lerpf(1.0, 2.25, release)
	cast_effect.rotation = time * 0.35
	cast_effect.modulate = Color(1.0, 1.0, 1.0, (0.35 + energy * 0.65) * (1.0 - release))
	cast_halo.scale = Vector2.ONE * (0.82 + sin(time * 9.0) * 0.08)
	cast_ring_outer.rotation = time * 1.25
	cast_ring_inner.rotation = -time * 1.75
	cast_core.rotation = time * 0.8
	cast_core.scale = Vector2.ONE * (0.72 + energy * 0.35 + sin(time * 16.0) * 0.08)
	cast_core_highlight.scale = Vector2.ONE * (0.8 + sin(time * 20.0) * 0.18)
	for index in cast_motes.size():
		var angle := time * (2.2 if index % 2 == 0 else -1.7) + TAU * index / cast_motes.size()
		var radius := 58.0 + sin(time * 5.0 + index) * 8.0
		cast_motes[index].position = Vector2(cos(angle), sin(angle)) * radius
		cast_motes[index].scale = Vector2.ONE * (0.7 + index % 3 * 0.22)


func _apply_cast(time: float) -> void:
	if time < 0.25:
		phase_label = "准备"
		_apply_idle(time)
	elif time < 1.05:
		phase_label = "聚能展开"
		var charge := smoothstep(0.0, 1.0, (time - 0.25) / 0.80)
		root_bone.position.y -= 12.0 * charge
		launcher_bone.rotation = 0.14 * charge
		orbiter_back_bone.position += Vector2(-34.0, -16.0) * charge
		orbiter_back_bone.rotation = -0.45 * charge
		orbiter_top_bone.position += Vector2(25.0, -28.0) * charge
		orbiter_top_bone.rotation = 0.55 * charge
		_update_cast_effect(time, charge)
		_update_dust(time, 0.8 + charge * 0.8)
	elif time < 1.55:
		phase_label = "能量释放"
		var release := (time - 1.05) / 0.50
		root_bone.position.y -= 12.0 * (1.0 - release)
		orbiter_back_bone.position += Vector2(-34.0, -16.0) * (1.0 - release)
		orbiter_top_bone.position += Vector2(25.0, -28.0) * (1.0 - release)
		_update_cast_effect(time, 1.0, release)
		_update_dust(time, 1.6)
	else:
		phase_label = "返回待机"
		_apply_idle(time)


func _apply_hurt(time: float) -> void:
	if time < 0.15 or time >= 0.90:
		phase_label = "返回待机"
		_apply_idle(time)
		return
	phase_label = "受击震荡"
	var progress := (time - 0.15) / 0.75
	var strength := pow(1.0 - progress, 2.0)
	root_bone.position += Vector2(-26.0, 5.0) * strength
	root_bone.rotation = -0.18 * strength
	launcher_bone.rotation = 0.22 * strength
	orbiter_back_bone.position += Vector2(-34.0, 18.0) * strength
	orbiter_top_bone.position += Vector2(22.0, -24.0) * strength
	rig.modulate = Color(1.0, 0.45 + progress * 0.55, 0.72 + progress * 0.28)
	_update_dust(time, 1.7 - progress * 0.7)


func _apply_critical(time: float) -> void:
	phase_label = "骨骼循环"
	var tremble := sin(time * 17.0)
	root_bone.position += Vector2(tremble * 2.0, 14.0 + absf(sin(time * 4.0)) * 3.0)
	root_bone.rotation = -0.055 + tremble * 0.012
	launcher_bone.position.y += 5.0
	launcher_bone.rotation = 0.11
	orbiter_back_bone.position += Vector2(8.0, 14.0)
	orbiter_top_bone.position += Vector2(5.0, 10.0)
	_update_dust(time * 0.7, 0.45)


func _apply_death(_time: float) -> void:
	phase_label = "保留正式 005 序列帧"
	rig.visible = false
	hybrid_sequence_sprite.visible = true


func _apply_mode(mode: StringName, time: float) -> void:
	mode_label = MODE_NAMES[mode]
	_set_sequence(mode, time)
	_reset_rig(time)
	match mode:
		&"idle": _apply_idle(time)
		&"move": _apply_move(time)
		&"attack": _apply_attack(time)
		&"cast": _apply_cast(time)
		&"hurt": _apply_hurt(time)
		&"critical": _apply_critical(time)
		&"death": _apply_death(time)
	queue_redraw()


func _apply_tour(time: float) -> void:
	var state := _tour_state(time)
	_apply_mode(state[0], state[1])


func apply_motion_preview(context: Dictionary) -> void:
	if not embedded_preview: return
	var state: StringName = context.get("state", &"idle")
	visible = handles_motion_preview_state(state)
	if not visible: return
	position = context.get("center", Vector2.ZERO)
	var display_size: Vector2 = context.get("display_size", Vector2(64, 64))
	var facing := 1.0 if context.get("facing_right", true) else -1.0
	scale = Vector2(display_size.x / 288.0 * facing, display_size.y / 288.0)
	modulate = context.get("tint", Color.WHITE)
	var mode: StringName = state if state in MODES else &"idle"
	var duration: float = context.get("duration", 0.0)
	var age: float = context.get("age", 0.0)
	var local_time: float
	if mode in [&"idle", &"move", &"critical"]:
		local_time = context.get("motion_time", age)
	else:
		local_time = MODE_DURATIONS[mode] * clampf(age / maxf(duration, 0.001), 0.0, 1.0)
	_apply_mode(mode, local_time)


func _update_dust(time: float, intensity: float) -> void:
	for index in dust_sprites.size():
		var mote := dust_sprites[index]
		var progress := fmod(time * (0.42 + index % 4 * 0.06) + index * 0.137, 1.0)
		mote.position = Vector2(
			sin(progress * TAU + index) * (9.0 + index % 3 * 3.0) * intensity,
			-62.0 + progress * 78.0,
		)
		mote.modulate = Color(0.88, 0.91, 0.91, (1.0 - progress) * 0.68 * minf(intensity, 1.4))


func _process(delta: float) -> void:
	if embedded_preview: return
	if fixed_time >= 0:
		_apply_mode(fixed_mode, fixed_time)
	else:
		elapsed += delta
		_apply_tour(elapsed)


func _text(position: Vector2, value: String, size: int, color := PAPER) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw() -> void:
	if embedded_preview: return
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	draw_rect(Rect2(36, 28, size.x - 72, 78), PAPER)
	_text(Vector2(62, 78), "粉笔精灵混合动画原型 003", 30, INK)
	_text(Vector2(size.x - 500, 76), "正式 005 vs 混合方案 · 0.5×", 20, INK)
	draw_line(Vector2(size.x * 0.5, 142), Vector2(size.x * 0.5, size.y - 118), Color(PAPER, 0.28), 2)
	_text(Vector2(size.x * 0.17, 178), "正式 005 · 序列帧", 24)
	_text(Vector2(size.x * 0.61, 178), "候选 003 · 混合动画", 24)
	_text(Vector2(size.x * 0.17, 214), "当前正式动作", 17, Color(PAPER, 0.7))
	_text(Vector2(size.x * 0.61, 214), "固定部件补间；死亡保留原帧", 17, Color(PAPER, 0.7))
	for anchor in [left_anchor, right_anchor]:
		draw_line(anchor - Vector2(12, 0), anchor + Vector2(12, 0), GOLD, 2)
		draw_line(anchor - Vector2(0, 12), anchor + Vector2(0, 12), GOLD, 2)
	var state_text := "%s · %s" % [mode_label, phase_label]
	_text(Vector2(size.x * 0.5 - state_text.length() * 9, 270), state_text, 28, MAGENTA if mode_label in ["远程", "施法"] else TEAL)
	draw_rect(Rect2(36, size.y - 94, size.x - 72, 54), Color(PAPER, 0.96))
	_text(Vector2(58, size.y - 58), "骨骼：待机 / 移动 / 远程 / 施法 / 受击 / 濒危    序列帧：退场    独立层：粉尘 / 弹体 / 枪口光 / 双环法阵", 18, INK)


func _run_check() -> void:
	set_process(false)
	var failures := 0
	if texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
		failures += 1
	for bone in [root_bone, launcher_bone, orbiter_back_bone, orbiter_top_bone]:
		if bone.get_autocalculate_length_and_angle():
			failures += 1
	if root_bone == null or launcher_bone == null or launcher_bone.get_parent() != root_bone:
		failures += 1
	if dust_sprites.size() != 10 or projectile.texture == null:
		failures += 1
	for mode in MODES:
		_apply_mode(mode, MODE_DURATIONS[mode] * 0.5)
		if sequence_sprite.texture == null:
			failures += 1
	_apply_mode(&"attack", 0.86)
	if not projectile.visible or not muzzle_flash.visible or root_bone.position.x >= 0.0 or projectile.position.x <= 0.0:
		failures += 1
	_apply_mode(&"attack", 0.62)
	if root_bone.position.x <= 0.0:
		failures += 1
	_apply_mode(&"cast", 0.95)
	if not cast_effect.visible or cast_motes.size() != 8 or cast_ring_outer.points.size() != 13 or cast_ring_inner.points.size() != 9:
		failures += 1
	_apply_mode(&"death", 1.40)
	if rig.visible or not hybrid_sequence_sprite.visible:
		failures += 1
	print("CHALK_RIG_CHECK actions=7 rig=6 death=approved-005 failures=", failures)
	get_tree().quit(failures)


func _capture_frame(path: String, resolution: Vector2i, time: float, mode: StringName) -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = resolution
	fixed_mode = mode
	fixed_time = time
	_layout()
	_apply_mode(mode, time)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	assert(screenshot.get_size() == resolution)
	screenshot.save_png(path)


func _capture() -> void:
	set_process(false)
	var review := "res://design/concepts/chalk-spirit/chalk-rig/003/review/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(review))
	for state in [
		["idle", 0.10], ["windup", 0.62], ["release", 0.86], ["recovery", 1.28],
	]:
		await _capture_frame(review + "rig-%s-1920x1080.png" % state[0], Vector2i(1920, 1080), state[1], &"attack")
	var representatives := {
		&"idle": 0.65, &"move": 0.70, &"attack": 0.86, &"cast": 0.95,
		&"hurt": 0.30, &"critical": 0.85, &"death": 1.55,
	}
	for mode in MODES:
		await _capture_frame(
			review + "rig-%s-1920x1080.png" % mode,
			Vector2i(1920, 1080),
			representatives[mode],
			mode,
		)
	for resolution in [Vector2i(2560, 1440), Vector2i(1920, 1200)]:
		await _capture_frame(
			review + "rig-release-%dx%d.png" % [resolution.x, resolution.y],
			resolution,
			0.86,
			&"attack",
		)

	var attack_frames := "res://.godot/chalk-rig-frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(attack_frames))
	for index in 40:
		await _capture_frame(
			attack_frames + "/frame-%03d.png" % index,
			Vector2i(1280, 720),
			2.0 * index / 39.0,
			&"attack",
		)

	var tour_frames := "res://.godot/chalk-rig-tour-frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(tour_frames))
	var frame_index := 0
	for mode in MODES:
		for local_index in 16:
			await _capture_frame(
				tour_frames + "/frame-%03d.png" % frame_index,
				Vector2i(960, 540),
				MODE_DURATIONS[mode] * local_index / 15.0,
				mode,
			)
			frame_index += 1
	print("CHALK_RIG_CAPTURE actions=7 attack_frames=40 tour_frames=112 resolutions=3")
	get_tree().quit()
