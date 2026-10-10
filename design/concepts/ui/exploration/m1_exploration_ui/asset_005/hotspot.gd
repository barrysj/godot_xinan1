extends Button

var kind := 0
var completed := false
var selected := false

func _ready() -> void:
	custom_minimum_size = Vector2(80, 80)
	flat = true
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	var at := size / 2
	var accent := Color("00f0ff") if selected else Color("829bab")
	if kind == 3: accent = Color("ff2daa") if not completed else Color("95c6b1")
	var rect := Rect2(at - Vector2(28,28),Vector2(56,56))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.06,0.08,0.13,0.92)
	panel.border_color = accent
	panel.set_border_width_all(2 if selected else 1)
	panel.set_corner_radius_all(6)
	draw_style_box(panel,rect)
	var ink := Color("00f0ff") if selected else Color("e0ebf2")
	match kind:
		0:
			draw_rect(Rect2(at-Vector2(16,13),Vector2(32,26)),ink,false,2)
			draw_polyline(PackedVector2Array([at+Vector2(-13,9),at+Vector2(-4,-1),at+Vector2(4,6),at+Vector2(13,-8)]),ink,2)
			draw_circle(at+Vector2(-6,-6),3,ink)
		1:
			draw_arc(at+Vector2(0,-7),9,0,TAU,24,ink,2)
			draw_arc(at+Vector2(0,18),15,PI,TAU,24,ink,2)
		2:
			draw_rect(Rect2(at-Vector2(16,14),Vector2(32,23)),ink,false,2)
			draw_line(at+Vector2(0,9),at+Vector2(0,18),ink,2)
			draw_line(at+Vector2(-9,18),at+Vector2(9,18),ink,2)
		3:
			draw_polyline(PackedVector2Array([at+Vector2(0,-19),at+Vector2(16,-11),at+Vector2(14,9),at+Vector2(0,21),at+Vector2(-14,9),at+Vector2(-16,-11),at+Vector2(0,-19)]),accent,2)
			if not completed:
				draw_line(at+Vector2(0,-10),at+Vector2(0,3),Color("f7ea39"),3)
				draw_circle(at+Vector2(0,10),2,Color("f7ea39"))
				for angle in [-135.0,-45.0,150.0]:
					var bolt := PackedVector2Array()
					for p in [Vector2(48,-3),Vector2(36,1),Vector2(40,4),Vector2(30,0)]:
						bolt.append(at+p.rotated(deg_to_rad(angle)))
					draw_polyline(bolt,accent,2,true)
	if completed:
		draw_polyline(PackedVector2Array([at+Vector2(17,-29),at+Vector2(22,-24),at+Vector2(33,-36)]),Color("95c6b1"),3,true)
	if selected or has_focus() or is_hovered():
		for sign_value in [-1,1]:
			var corner: Vector2 = at+Vector2(34,34)*sign_value
			draw_polyline(PackedVector2Array([corner-Vector2(0,18)*sign_value,corner,corner-Vector2(18,0)*sign_value]),ink,2)
