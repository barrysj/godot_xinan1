extends "res://design/concepts/m1-exploration-ui/m1_exploration_ui/008/hotspot.gd"

func _draw() -> void:
	if artwork == null:
		return
	var at := size / 2.0
	var tint := Color(0.54, 0.64, 0.66, 0.72) if completed else Color.WHITE
	var art_size := Vector2(106, 106)
	draw_texture_rect(artwork, Rect2(at - art_size / 2.0, art_size), false, tint)
	if selected or has_focus() or is_hovered():
		var accent := Color("ff2daa") if kind == 3 else Color("99eaff")
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
