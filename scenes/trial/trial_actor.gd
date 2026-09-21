extends Node2D
## Read-only combatant view. Animation clocks and recoil never enter simulation data.
const Presenter = preload("res://scenes/battle_demo/unit_presentation.gd")
const Animator = preload("res://scenes/battle_demo/battle_animation.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const TEAL = Color("76e5cb")
const RED = Color("ff958f")
const GOLD = Color("ffe08d")
const BLUE = Color("8fdfff")
var snapshot: Dictionary = {}
var presenter = Presenter.new()
var animator
var hybrid: Node2D
var selected := false
var marked := false
var phase_text := ""
var _resource: Resource

func configure(unit: Dictionary) -> void:
	_resource = unit.get("battle_animation")
	animator = Animator.new(_resource, unit.get("attack_modes", 1))
	presenter.facing_right = unit.side == 0
	if _resource != null and _resource.presentation_scene != null:
		var candidate = _resource.presentation_scene.instantiate()
		if candidate is Node2D and candidate.has_method("apply_presentation"):
			hybrid = candidate
			hybrid.show_behind_parent = true
			add_child(hybrid)
		else:
			candidate.free()
			push_warning("Trial animation presentation must expose apply_presentation(context)")

func consume(event: Dictionary) -> void:
	if event.kind.begins_with("action_") and event.actor_id == snapshot.get("id", -1):
		presenter.consume(event)
	if event.kind == "impact" and event.target_id == snapshot.get("id", -1):
		presenter.consume(event)
		if event.get("effect", "") == "damage" and event.get("actual", 0) > 0:
			animator.play(&"hurt")

func synchronize(unit: Dictionary, delta: float, alpha: float, pixel_position: Vector2, factor: float, has_mark: bool, is_selected: bool, pixel_direction: Vector2 = Vector2.ZERO) -> void:
	# Never add presentation fields to the authoritative runtime dictionary.
	snapshot = unit.duplicate()
	var logical: Vector2 = unit.get("facing", Vector2.ZERO)
	snapshot.screen_facing = pixel_direction.normalized() if not pixel_direction.is_zero_approx() else Vector2(-logical.y, logical.x)
	presenter.advance(maxf(delta, 0), snapshot)
	var previous_direction: Vector2 = presenter.action.get("direction", snapshot.screen_facing)
	presenter.action = unit.get("action", {}).duplicate()
	if not presenter.action.is_empty():
		presenter.action.direction = previous_direction
		presenter.action.age = minf(presenter.action.age + clampf(alpha, 0, 1) * 0.05, presenter.action.duration)
		phase_text = "施法" if presenter.action.casts else ("蓄势" if presenter.action.age < presenter.action.windup else "收招")
	else:
		phase_text = "移动" if unit.get("moving", false) else ""
	animator.sync_health(unit.hp, unit.max_hp)
	animator.sync_motion(unit.get("moving", false), presenter.action)
	animator.advance(maxf(delta, 0))
	position = pixel_position
	z_index = int(pixel_position.y)
	scale = Vector2.ONE * factor
	marked = has_mark
	selected = is_selected
	if is_instance_valid(hybrid):
		var pose: Dictionary = presenter.pose(snapshot, true)
		hybrid.call("apply_presentation", {"center": pose.offset,
			"display_size": _resource.display_size, "state": animator.state,
			"age": animator.age, "duration": animator._duration(animator.state),
			"motion_time": presenter.motion_time, "facing_right": presenter.facing_right,
			"tint": pose.tint})
	queue_redraw()

func _draw() -> void:
	if snapshot.is_empty(): return
	var alive: bool = snapshot.hp > 0
	var tint = TEAL if snapshot.side == 0 else RED
	var body_visible = not is_instance_valid(hybrid) or not hybrid.visible
	var death_alpha = 1.0 if alive else maxf(0.18, 1.0 - presenter.death_age * 1.6)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.26))
	draw_circle(Vector2.ZERO, 27, Color(0, 0, 0, 0.28 * death_alpha))
	if alive: draw_arc(Vector2.ZERO, 27, 0, TAU, 32, Color(tint, 0.6), 2, true)
	if selected: draw_arc(Vector2.ZERO, 34, 0, TAU, 32, GOLD, 3, true)
	draw_set_transform(Vector2.ZERO)
	if body_visible: _draw_body()
	if alive and snapshot.shield > 0:
		var outline = PackedVector2Array([Vector2(-29, -63), Vector2(29, -63), Vector2(35, -30), Vector2(22, 0), Vector2(0, 10), Vector2(-22, 0), Vector2(-35, -30), Vector2(-29, -63)])
		draw_colored_polygon(outline, Color(BLUE, 0.045))
		draw_polyline(outline, Color(BLUE, 0.72), 2, true)
	if alive and marked:
		var phase = presenter.motion_time * 2
		for i in 4:
			var angle = phase + i * PI / 2
			draw_arc(Vector2(0, -31), 43, angle, angle + 0.8, 9, GOLD, 2, true)
		_center(Vector2(0, -83), "漏洞", GOLD, 16)
	if alive and not presenter.action.is_empty():
		var action: Dictionary = presenter.action
		var windup: float = clampf(action.age / maxf(action.windup, 0.001), 0, 1)
		if action.age < action.windup:
			draw_arc(Vector2(0, -31), 39, -PI / 2, -PI / 2 + TAU * windup, 24, Color(GOLD if action.casts else tint, 0.65), 2, true)
	_draw_status(tint, alive)

func _draw_body() -> void:
	var texture: Texture2D = animator.texture()
	var pose: Dictionary = presenter.pose(snapshot, texture != null)
	var stretch: Vector2 = pose.stretch
	if texture != null:
		if _resource.flip_with_facing and pose.flip: stretch.x *= -1
		draw_set_transform(pose.offset, pose.rotation, stretch)
		draw_texture_rect(texture, Rect2(-_resource.display_size * _resource.anchor, _resource.display_size), false, pose.tint)
	else:
		# Articulated silhouettes communicate role and gait until authored assets exist.
		if pose.flip: stretch.x *= -1
		draw_set_transform(pose.offset, pose.rotation, stretch)
		if snapshot.side == 1: _draw_machine(pose.tint)
		else: _draw_student(pose.tint)
	draw_set_transform(Vector2.ZERO)

func _draw_student(flash: Color) -> void:
	var role: int = snapshot.get("role", 0)
	var colors = [Color("6dbfc6"), Color("d2b273"), Color("9acb99"), Color("92b6e8"), Color("c599df"), Color("e49b7e")]
	var color: Color = colors[posmod(role, colors.size())] * flash
	var dark = Color("17283e") * flash
	var skin = Color("eac9ae") * flash
	var stride = sin(presenter.motion_time * 15) * 7 if snapshot.get("moving", false) else 0.0
	var reach := 0.0
	if not presenter.action.is_empty():
		var a: Dictionary = presenter.action
		reach = -5.0 * sin(clampf(a.age / a.windup, 0, 1) * PI / 2) if a.age < a.windup else 15.0 * pow(1.0 - clampf((a.age - a.windup) / maxf(0.05, a.duration - a.windup), 0, 1), 2)
	draw_line(Vector2(-7, -20), Vector2(-10 - stride, -2), dark, 9, true)
	draw_line(Vector2(7, -20), Vector2(11 + stride, -2), dark, 9, true)
	draw_line(Vector2(-13 - stride, -2), Vector2(-5 - stride, -2), color, 5, true)
	draw_line(Vector2(8 + stride, -2), Vector2(18 + stride, -2), color, 5, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -48), Vector2(11, -48), Vector2(16, -20), Vector2(-15, -20)]), color)
	draw_line(Vector2(0, -44), Vector2(0, -23), Color("cce6ed") * flash, 2, true)
	draw_circle(Vector2(0, -60), 11, skin)
	draw_arc(Vector2(0, -62), 10, PI, TAU, 15, dark, 5, true)
	draw_circle(Vector2(5, -60), 1.5, dark)
	draw_line(Vector2(-10, -44), Vector2(-17, -28 - stride * 0.4), color.darkened(0.15), 7, true)
	var hand = Vector2(15 + reach, -33)
	draw_line(Vector2(9, -44), hand, color.lightened(0.15), 7, true)
	draw_circle(hand, 4, skin)
	match role:
		0:
			var shield = PackedVector2Array([hand + Vector2(-8,-17), hand + Vector2(15,-13), hand + Vector2(12,12), hand + Vector2(0,21), hand + Vector2(-10,10)])
			draw_colored_polygon(shield, Color("315a73") * flash)
			draw_polyline(shield + PackedVector2Array([shield[0]]), BLUE * flash, 2, true)
		1:
			draw_arc(hand, 19, -PI / 2, PI / 2, 18, GOLD * flash, 3, true)
			draw_line(hand + Vector2(0,-19), hand + Vector2(0,19), Color("eef1db") * flash, 1, true)
		2:
			draw_circle(hand + Vector2(5, 0), 9, color.darkened(0.2))
			draw_line(hand + Vector2(1,-5), hand + Vector2(1,5), Color.WHITE * flash, 3, true)
			draw_line(hand + Vector2(-4,0), hand + Vector2(6,0), Color.WHITE * flash, 3, true)
		3, 4:
			draw_rect(Rect2(hand + Vector2(-5,-9), Vector2(24,17)), dark)
			draw_rect(Rect2(hand + Vector2(-2,-6), Vector2(18,11)), Color("34676a") * flash)
			draw_line(hand + Vector2(0,-3), hand + Vector2(9,-3), TEAL * flash, 2, true)
			draw_line(hand + Vector2(0,2), hand + Vector2(13,2), GOLD * flash, 2, true)
		5:
			draw_line(hand, hand + Vector2(22,-12), Color("edf5ee") * flash, 5, true)
			draw_line(hand + Vector2(5,-6), hand + Vector2(9,1), GOLD * flash, 3, true)

func _draw_machine(flash: Color) -> void:
	var boss: bool = str(snapshot.get("name", "")).contains("回滚")
	var wide = 31.0 if boss else 23.0
	var stride = sin(presenter.motion_time * 12) * 5 if snapshot.get("moving", false) else 0.0
	var dark = Color("263345") * flash
	var accent = (Color("d297e6") if boss else RED) * flash
	draw_line(Vector2(-12,-12), Vector2(-19-stride,0), dark, 9, true)
	draw_line(Vector2(12,-12), Vector2(19+stride,0), dark, 9, true)
	draw_rect(Rect2(-wide,-65,wide*2,50), dark)
	draw_rect(Rect2(-wide+5,-60,wide*2-10,31), accent.darkened(0.55))
	for i in 3:
		draw_line(Vector2(-wide+9,-53+i*8), Vector2(wide-10-i*4,-53+i*8), accent, 2, true)
	draw_line(Vector2(-wide-6,-42), Vector2(-wide-7,-16), dark, 8, true)
	draw_line(Vector2(wide+2,-42), Vector2(wide+14,-33), dark, 9, true)
	draw_circle(Vector2(wide+15,-33), 6, accent)
	if boss:
		draw_arc(Vector2(0,-45), 40, PI, TAU, 24, accent, 3, true)
		draw_line(Vector2(0,-86), Vector2(0,-74), accent, 3, true)

func _draw_status(color: Color, alive: bool) -> void:
	var hp = Rect2(-31, 15, 62, 5)
	draw_rect(hp.grow(1), Color("07111b"))
	draw_rect(hp, Color("354153"))
	hp.size.x *= clampf(float(snapshot.hp) / maxf(float(snapshot.max_hp), 1), 0, 1)
	draw_rect(hp, color if alive else Color("798493"))
	if alive and snapshot.shield > 0:
		draw_rect(Rect2(-31, 12, 62 * minf(snapshot.shield / snapshot.max_hp, 1), 2), BLUE)
	_center(Vector2(0, 38), snapshot.name if alive else "已退场", color if alive else Color("8798ab"), 16)
	if not alive: return
	if selected: _center(Vector2(0, -95), "%d / %d" % [snapshot.hp, snapshot.max_hp], Color.WHITE, 16)
	var skill = snapshot.get("skill")
	if skill != null:
		var count: int = skill.attacks_to_trigger
		for i in mini(count, 10):
			draw_rect(Rect2(-count * 4 + i * 8, 43, 5, 3), GOLD if i < snapshot.get("count", 0) else Color("394958"))
	if not phase_text.is_empty(): _center(Vector2(0, 62), phase_text, Color(GOLD, 0.75) if phase_text == "施法" else Color("839bab"), 12)

func _center(at: Vector2, text: String, color: Color, font_size: int) -> void:
	var width = FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string_outline(FONT, at - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("091520"))
	draw_string(FONT, at - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
