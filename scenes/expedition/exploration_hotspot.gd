extends Button
## Transparent rectangular hit target around an approved free-silhouette marker.

var kind := "memory"
var artwork: Texture2D
var completed := false
var selected := false
var motion_phase := 0.0
var interaction_strength := 0.0
var motion_time := 0.0
var interaction_tween: Tween

const IDLE_PERIOD := 2.2
const IDLE_LIFT := 4.0
const IDLE_PULSE := 0.05
const COMPLETED_LIFT := 1.5
const INTERACTION_SCALE := 0.06

func _ready() -> void:
	custom_minimum_size = Vector2(118, 118)
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var no_focus_box := StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", no_focus_box)
	mouse_entered.connect(_refresh_interaction)
	mouse_exited.connect(_refresh_interaction)
	focus_entered.connect(_refresh_interaction)
	focus_exited.connect(_refresh_interaction)

func _process(delta: float) -> void:
	motion_time = fmod(motion_time + delta, IDLE_PERIOD)
	queue_redraw()

func set_motion_index(index: int) -> void:
	motion_phase = float(index) * TAU / 4.0

func motion_sample(at_time: float) -> Dictionary:
	var wave := sin(TAU * at_time / IDLE_PERIOD + motion_phase)
	var offset_y := wave * (COMPLETED_LIFT if completed else IDLE_LIFT)
	var breathing := 0.0 if completed else (wave + 1.0) * 0.5 * IDLE_PULSE
	var active := clampf(interaction_strength, 0.0, 1.0)
	if selected:
		offset_y = 0.0
		breathing = IDLE_PULSE
		active = maxf(active, 0.20)
	return {
		"offset_y": offset_y,
		"scale": 1.0 + breathing + active * INTERACTION_SCALE,
		"active": active,
	}

func _refresh_interaction() -> void:
	var target := 1.0 if has_focus() or is_hovered() else 0.0
	if is_instance_valid(interaction_tween):
		interaction_tween.kill()
	var entering := target > interaction_strength
	interaction_tween = create_tween()
	interaction_tween.tween_property(self, "interaction_strength", target, 0.12 if entering else 0.18) \
		.set_trans(Tween.TRANS_BACK if entering else Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if artwork == null:
		return
	var sample := motion_sample(motion_time)
	var at := size / 2.0 + Vector2(0, sample.offset_y)
	var tint := Color(0.54, 0.64, 0.66, 0.72) if completed else Color.WHITE
	var art_size := Vector2(106, 106) * float(sample.scale)
	var accent := Color("ff2daa") if kind == "battle" else Color("99eaff")
	var glow_alpha := 0.07 + 0.12 * float(sample.active)
	var glow_size := art_size + Vector2(10, 10)
	draw_texture_rect(artwork, Rect2(at - glow_size / 2.0, glow_size), false, Color(accent.r, accent.g, accent.b, glow_alpha))
	draw_texture_rect(artwork, Rect2(at - art_size / 2.0, art_size), false, tint)
	if selected or has_focus() or is_hovered():
		for sign_value in [-1, 1]:
			var corner: Vector2 = at + art_size / 2.0 * sign_value
			draw_polyline(PackedVector2Array([
				corner - Vector2(0, 17) * sign_value,
				corner,
				corner - Vector2(17, 0) * sign_value,
			]), accent, 2, true)
	if completed:
		draw_polyline(PackedVector2Array([
			at + Vector2(29, -43),
			at + Vector2(35, -37),
			at + Vector2(47, -50),
		]), Color("95e6b1"), 3, true)
