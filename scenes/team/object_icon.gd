extends Button
var glyph = "empty"
var role = -1
const CELLS = [Vector2i(1,8),Vector2i(3,7),Vector2i(0,7),Vector2i(2,7),Vector2i(3,8)]
func _draw() -> void:
	var edge = minf(size.x,size.y)*0.66
	var at = (size-Vector2.ONE*edge)/2
	if role >= 0:
		draw_texture_rect_region(preload("res://assets/pixel/kenney/tiny-dungeon.png"),Rect2(at,Vector2.ONE*edge),Rect2(Vector2(CELLS[role])*16,Vector2(16,16)))
		return
	draw_set_transform(at,0,Vector2.ONE*(edge/64.0))
	var ink = Color("e8eee9")
	var mint = Color("69d9bd")
	match glyph:
		"badge":
			draw_style_box(book_style(),Rect2(9,5,46,54))
			draw_rect(Rect2(13,7,6,50),Color("976347"))
			draw_rect(Rect2(25,17,22,17),Color("f4e4b8"))
			draw_line(Vector2(24,48),Vector2(48,48),ink,3)
		"shoe":
			draw_colored_polygon(PackedVector2Array([Vector2(7,13),Vector2(27,13),Vector2(32,30),Vector2(54,39),Vector2(57,51),Vector2(6,51)]),Color("78bed8"))
			draw_line(Vector2(7,52),Vector2(58,52),ink,7)
			for i in range(3): draw_line(Vector2(24+i*5,25+i*5),Vector2(36+i*5,21+i*5),ink,3)
		"shield":
			draw_colored_polygon(PackedVector2Array([Vector2(32,3),Vector2(55,13),Vector2(50,42),Vector2(32,61),Vector2(14,42),Vector2(9,13)]),Color("78bed8"))
			draw_line(Vector2(32,16),Vector2(32,46),ink,5)
			draw_line(Vector2(21,29),Vector2(43,29),ink,5)
		"arrow":
			draw_line(Vector2(8,56),Vector2(52,12),mint,9)
			draw_colored_polygon(PackedVector2Array([Vector2(32,7),Vector2(58,6),Vector2(57,33)]),ink)
		"heart":
			draw_circle(Vector2(21,22),14,Color("ed889a"))
			draw_circle(Vector2(43,22),14,Color("ed889a"))
			draw_colored_polygon(PackedVector2Array([Vector2(7,25),Vector2(57,25),Vector2(32,58)]),Color("ed889a"))
		"bolt":
			draw_colored_polygon(PackedVector2Array([Vector2(35,3),Vector2(11,35),Vector2(29,35),Vector2(23,61),Vector2(55,25),Vector2(36,25)]),Color("f6cc79"))
		"flask":
			draw_colored_polygon(PackedVector2Array([Vector2(23,6),Vector2(41,6),Vector2(41,28),Vector2(57,54),Vector2(7,54),Vector2(23,28)]),Color("aa95dd"))
			draw_circle(Vector2(33,42),5,ink)
		"attack":
			draw_line(Vector2(13,52),Vector2(51,12),ink,8)
			draw_line(Vector2(11,34),Vector2(30,53),mint,6)
		"remove":
			draw_line(Vector2(17,17),Vector2(47,47),Color("e8a391"),5)
			draw_line(Vector2(47,17),Vector2(17,47),Color("e8a391"),5)
		_:
			draw_line(Vector2(17,32),Vector2(47,32),Color("60798a"),3)
			draw_line(Vector2(32,17),Vector2(32,47),Color("60798a"),3)
	draw_set_transform(Vector2.ZERO)
func book_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("bd936c")
	style.set_corner_radius_all(3)
	return style
