extends RefCounted
## Shared cut-paper shapes. Rectangles remain the stable touch targets.
const RED = Color("e92746")
const INK = Color("121218")
const WHITE = Color("fff9ee")

static func cut(rect: Rect2) -> PackedVector2Array:
	var p = rect.position
	var s = rect.size
	var notch = minf(14.0, s.y * 0.2)
	return PackedVector2Array([p+Vector2(notch,0),p+Vector2(s.x,0),p+Vector2(s.x-notch,s.y),p+Vector2(0,s.y)])

static func card(canvas: CanvasItem, rect: Rect2, fill: Color, border: Color = WHITE) -> void:
	canvas.draw_colored_polygon(cut(Rect2(rect.position+Vector2(5,6),rect.size)),INK)
	canvas.draw_colored_polygon(cut(rect),border)
	canvas.draw_colored_polygon(cut(rect.grow(-3)),fill)

static func backdrop(canvas: CanvasItem, extent: Vector2) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO,extent),INK)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(extent.x*.31,0),Vector2(extent.x*.12,extent.y),Vector2(0,extent.y)]),RED)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(extent.x*.90,0),extent,Vector2(extent.x*.74,extent.y)]),RED)
	for y in range(12,int(extent.y),19):
		for x in range(10,210,19):
			canvas.draw_circle(Vector2(x+(9 if y%2 else 0),y),1.5,Color(0,0,0,0.24))
	for i in range(6):
		canvas.draw_line(Vector2(extent.x-150+i*26,0),Vector2(extent.x-290+i*26,110),WHITE,2)
