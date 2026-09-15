extends Node2D
## Production cutout presentation for chalk spirit asset 006.
## The shared battle clock supplies state and time; unhandled states use SpriteFrames.

const BODY = preload("res://assets/art/characters/chalk_spirit/006/parts/body.png")
const LAUNCHER = preload("res://assets/art/characters/chalk_spirit/006/parts/launcher.png")
const ORBITER_BACK = preload("res://assets/art/characters/chalk_spirit/006/parts/orbiter_back.png")
const ORBITER_TOP = preload("res://assets/art/characters/chalk_spirit/006/parts/orbiter_top.png")
const DUST = preload("res://assets/art/characters/chalk_spirit/006/parts/dust_particle.png")

const PAPER := Color("fff9ee")
const TEAL := Color("45d7bd")
const MAGENTA := Color("f04bc6")
const GOLD := Color("f0c95a")
const RIG_MODES: Array[StringName] = [&"idle", &"move", &"attack", &"cast", &"hurt", &"critical"]
const MODE_DURATIONS := {
	&"idle": 1.5,
	&"move": 1.8,
	&"attack": 2.0,
	&"cast": 2.0,
	&"hurt": 1.4,
	&"critical": 1.8,
}

var rig: Node2D
var skeleton: Skeleton2D
var root_bone: Bone2D
var launcher_bone: Bone2D
var orbiter_back_bone: Bone2D
var orbiter_top_bone: Bone2D
var muzzle_flash: Polygon2D
var cast_effect: Node2D
var cast_halo: Polygon2D
var cast_ring_outer: Line2D
var cast_ring_inner: Line2D
var cast_core: Polygon2D
var cast_core_highlight: Polygon2D
var cast_motes: Array[Sprite2D] = []
var dust_sprites: Array[Sprite2D] = []


func _ready() -> void:
	# Painterly parts rotate and scale, so nearest sampling causes crawling edges.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_build_rig()
	visible = false
	set_process(false)


func configure_motion_preview() -> void:
	# Compatibility hook for the developer preview harness.
	pass


func handles_presentation_state(state: StringName) -> bool:
	return state in RIG_MODES


func handles_motion_preview_state(state: StringName) -> bool:
	return handles_presentation_state(state)


func apply_motion_preview(context: Dictionary) -> void:
	apply_presentation(context)


func apply_presentation(context: Dictionary) -> void:
	var state: StringName = context.get("state", &"idle")
	visible = handles_presentation_state(state)
	if not visible:
		return
	position = context.get("center", Vector2.ZERO)
	var display_size: Vector2 = context.get("display_size", Vector2(64, 64))
	var facing := 1.0 if context.get("facing_right", true) else -1.0
	scale = Vector2(display_size.x / 288.0 * facing, display_size.y / 288.0)
	modulate = context.get("tint", Color.WHITE)
	var duration: float = context.get("duration", 0.0)
	var age: float = context.get("age", 0.0)
	var local_time: float
	if state in [&"idle", &"move", &"critical"]:
		local_time = context.get("motion_time", age)
	else:
		local_time = MODE_DURATIONS[state] * clampf(age / maxf(duration, 0.001), 0.0, 1.0)
	_apply_mode(state, local_time)


func _part(parent: Node, title: String, texture: Texture2D, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = title
	sprite.texture = texture
	sprite.position = at
	parent.add_child(sprite)
	return sprite


func _bone(parent: Node, title: String, at: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = title
	bone.position = at
	# Rigid transform pivots are not length-driven IK chains.
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

	var dust_layer := Node2D.new()
	dust_layer.name = "IndependentDust"
	rig.add_child(dust_layer)
	for index in 10:
		var mote := Sprite2D.new()
		mote.texture = DUST
		mote.name = "Dust%02d" % index
		mote.scale = Vector2.ONE * (0.55 + index % 3 * 0.22)
		dust_layer.add_child(mote)
		dust_sprites.append(mote)

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


func _reset_rig(time: float) -> void:
	rig.modulate = Color.WHITE
	root_bone.position = Vector2(0, sin(time * 3.2) * 2.0)
	root_bone.rotation = 0.0
	launcher_bone.position = Vector2(54, -145)
	launcher_bone.rotation = 0.0
	orbiter_back_bone.position = Vector2(-48.5, -182.5)
	orbiter_back_bone.rotation = 0.0
	orbiter_top_bone.position = Vector2(-28.5, -211.5)
	orbiter_top_bone.rotation = 0.0
	muzzle_flash.visible = false
	cast_effect.visible = false
	cast_effect.modulate = Color.WHITE


func _apply_idle(time: float) -> void:
	root_bone.position.y += sin(time * TAU / 1.5) * 4.0
	root_bone.rotation = sin(time * TAU / 3.0) * 0.018
	launcher_bone.rotation = sin(time * 2.2) * 0.025
	orbiter_back_bone.position += Vector2(cos(time * 2.4), sin(time * 2.4)) * 5.0
	orbiter_top_bone.position += Vector2(cos(time * 2.0 + 1.2), sin(time * 2.0 + 1.2)) * 4.0
	_update_dust(time, 1.0)


func _apply_move(time: float) -> void:
	var stride := sin(time * TAU / 0.48)
	root_bone.position += Vector2(stride * 5.0, -absf(stride) * 10.0)
	root_bone.rotation = stride * 0.055
	launcher_bone.rotation = -stride * 0.075
	orbiter_back_bone.position += Vector2(-stride * 13.0, cos(time * TAU / 0.48) * 8.0)
	orbiter_top_bone.position += Vector2(-stride * 9.0, -cos(time * TAU / 0.48) * 6.0)
	_update_dust(time * 1.35, 1.35)


func _apply_attack(time: float) -> void:
	if time < 0.25:
		_apply_idle(time)
	elif time < 0.72:
		var weight := smoothstep(0.0, 1.0, (time - 0.25) / 0.47)
		root_bone.position += Vector2(9.0, 3.0) * weight
		root_bone.rotation = 0.045 * weight
		launcher_bone.position += Vector2(-5.0, 1.0) * weight
		launcher_bone.rotation = -0.055 * weight
		orbiter_back_bone.position += Vector2(-10.0, 3.0) * weight
		orbiter_top_bone.position += Vector2(-7.0, -4.0) * weight
		_update_dust(time, 0.75)
	elif time < 1.0:
		var snap := smoothstep(0.0, 1.0, minf((time - 0.72) / 0.12, 1.0))
		root_bone.position += Vector2(lerpf(9.0, -19.0, snap), lerpf(3.0, -3.0, snap))
		root_bone.rotation = lerpf(0.045, -0.11, snap)
		launcher_bone.position += Vector2(lerpf(-5.0, 2.0, snap), lerpf(1.0, -3.0, snap))
		launcher_bone.rotation = lerpf(-0.055, -0.13, snap)
		orbiter_back_bone.position += Vector2(9.0, 1.0) * snap
		orbiter_top_bone.position += Vector2(7.0, -1.0) * snap
		var fire_progress := clampf((time - 0.78) / 0.22, 0.0, 1.0)
		muzzle_flash.visible = time >= 0.76 and time < 0.91
		muzzle_flash.scale = Vector2.ONE * (0.75 + sin(fire_progress * PI) * 0.85)
		_update_dust(time, 1.8)
	elif time < 1.65:
		var recovery := clampf((time - 1.0) / 0.65, 0.0, 1.0)
		var strength := pow(1.0 - recovery, 2.0)
		root_bone.position += Vector2(-17.0, -3.0) * strength
		root_bone.rotation = -0.095 * strength
		launcher_bone.position += Vector2(2.0, -2.0) * strength
		launcher_bone.rotation = -0.11 * strength
		orbiter_back_bone.position += Vector2(8.0, 2.0) * strength
		orbiter_top_bone.position += Vector2(6.0, -1.0) * strength
		_update_dust(time, 1.0 + strength * 0.6)
	else:
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
		_apply_idle(time)
	elif time < 1.05:
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
		var release := (time - 1.05) / 0.50
		root_bone.position.y -= 12.0 * (1.0 - release)
		orbiter_back_bone.position += Vector2(-34.0, -16.0) * (1.0 - release)
		orbiter_top_bone.position += Vector2(25.0, -28.0) * (1.0 - release)
		_update_cast_effect(time, 1.0, release)
		_update_dust(time, 1.6)
	else:
		_apply_idle(time)


func _apply_hurt(time: float) -> void:
	if time < 0.15 or time >= 0.90:
		_apply_idle(time)
		return
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
	var tremble := sin(time * 17.0)
	root_bone.position += Vector2(tremble * 2.0, 14.0 + absf(sin(time * 4.0)) * 3.0)
	root_bone.rotation = -0.055 + tremble * 0.012
	launcher_bone.position.y += 5.0
	launcher_bone.rotation = 0.11
	orbiter_back_bone.position += Vector2(8.0, 14.0)
	orbiter_top_bone.position += Vector2(5.0, 10.0)
	_update_dust(time * 0.7, 0.45)


func _apply_mode(mode: StringName, time: float) -> void:
	_reset_rig(time)
	match mode:
		&"idle": _apply_idle(time)
		&"move": _apply_move(time)
		&"attack": _apply_attack(time)
		&"cast": _apply_cast(time)
		&"hurt": _apply_hurt(time)
		&"critical": _apply_critical(time)


func _update_dust(time: float, intensity: float) -> void:
	for index in dust_sprites.size():
		var mote := dust_sprites[index]
		var progress := fmod(time * (0.42 + index % 4 * 0.06) + index * 0.137, 1.0)
		mote.position = Vector2(
			sin(progress * TAU + index) * (9.0 + index % 3 * 3.0) * intensity,
			-62.0 + progress * 78.0,
		)
		mote.modulate = Color(0.88, 0.91, 0.91, (1.0 - progress) * 0.68 * minf(intensity, 1.4))
