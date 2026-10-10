extends PanelContainer

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var outline := PackedVector2Array([Vector2.ZERO,Vector2(size.x-22,0),Vector2(size.x,22),size,Vector2(0,size.y),Vector2.ZERO])
	var shadow := PackedVector2Array()
	for point in outline: shadow.append(point+Vector2(3,7))
	draw_colored_polygon(shadow,Color(0,0,0,0.25))
	draw_colored_polygon(outline,Color(0.045,0.085,0.13,0.96))
	draw_polyline(outline,Color(0.5,0.6,0.7,0.35),1,true)
	draw_line(Vector2(1,30),Vector2(1,70),Color("68d7e4"),3,true)
	draw_line(Vector2(size.x,54),Vector2(size.x,63),Color("d96c9f"),1,true)
