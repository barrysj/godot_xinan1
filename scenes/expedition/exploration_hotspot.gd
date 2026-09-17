extends Button
## Transparent rectangular hit target around an approved free-silhouette marker.

var kind := "memory"
var artwork: Texture2D
var completed := false
var selected := false

func _ready() -> void:
	custom_minimum_size = Vector2(118, 118)
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var no_focus_box := StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", no_focus_box)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	if artwork == null:
		return
	var at := size / 2.0
	var tint := Color(0.54, 0.64, 0.66, 0.72) if completed else Color.WHITE
	var art_size := Vector2(106, 106)
	draw_texture_rect(artwork, Rect2(at - art_size / 2.0, art_size), false, tint)
	if selected or has_focus() or is_hovered():
		var accent := Color("ff2daa") if kind == "battle" else Color("99eaff")
		for sign_value in [-1, 1]:
			var corner: Vector2 = at + Vector2(53, 53) * sign_value
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
