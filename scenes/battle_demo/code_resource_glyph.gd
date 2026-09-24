extends RefCounted
## One visual vocabulary for stored code, recipe costs, and item type choices.

static func draw_icon(canvas: CanvasItem, kind: String, center: Vector2, color: Color, radius: float = 9.0) -> void:
	match kind:
		"red":
			var arrow := PackedVector2Array([
				center + Vector2(-radius * 0.75, -radius * 0.75),
				center + Vector2(radius * 0.65, 0),
				center + Vector2(-radius * 0.75, radius * 0.75)])
			canvas.draw_polyline(arrow, color, 2.5, true)
		"blue":
			for side in [-1.0, 1.0]:
				var x: float = center.x + side * radius * 0.55
				canvas.draw_line(Vector2(x, center.y - radius), Vector2(x - side * radius * 0.3, center.y - radius), color, 2.0, true)
				canvas.draw_line(Vector2(x - side * radius * 0.3, center.y - radius), Vector2(x - side * radius * 0.3, center.y + radius), color, 2.0, true)
				canvas.draw_line(Vector2(x - side * radius * 0.3, center.y + radius), Vector2(x, center.y + radius), color, 2.0, true)
		"green":
			canvas.draw_arc(center + Vector2(-radius * 0.38, 0), radius * 0.55, PI * 0.25, PI * 1.75, 14, color, 2.1, true)
			canvas.draw_arc(center + Vector2(radius * 0.38, 0), radius * 0.55, -PI * 0.75, PI * 0.75, 14, color, 2.1, true)
		"purple":
			canvas.draw_arc(center + Vector2(-radius * 0.28, -radius * 0.3), radius * 0.46, 0, TAU, 18, color, 2.0, true)
			canvas.draw_line(center + Vector2(0, 0), center + Vector2(radius * 0.72, radius * 0.72), color, 2.4, true)
			canvas.draw_line(center + Vector2(radius * 0.5, radius * 0.5), center + Vector2(radius * 0.8, radius * 0.2), color, 2.0, true)
