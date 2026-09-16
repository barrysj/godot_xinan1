extends "res://design/concepts/m1-exploration-ui/m1_exploration_ui/005/hotspot.gd"

var artwork: Texture2D

func _draw() -> void:
	if artwork == null: return
	var at := size/2
	var tint := Color(0.55,0.65,0.65) if completed else Color.WHITE
	draw_texture_rect(artwork,Rect2(at-Vector2(30,30),Vector2(60,60)),false,tint)
	if selected or has_focus() or is_hovered():
		for sign_value in [-1,1]:
			var corner: Vector2 = at+Vector2(36,36)*sign_value
			draw_polyline(PackedVector2Array([corner-Vector2(0,14)*sign_value,corner,corner-Vector2(14,0)*sign_value]),Color("99eaff"),2,true)
	if completed:
		draw_polyline(PackedVector2Array([at+Vector2(18,-28),at+Vector2(23,-23),at+Vector2(33,-34)]),Color("95e6b1"),3,true)
