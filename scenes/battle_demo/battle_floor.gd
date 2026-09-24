extends RefCounted
## Native tactical floor, shared by the existing demo and campaign renderer.
const Board = preload("res://scenes/battle_demo/battle_board.gd")
const CYAN = Color("#22b8d6")
const EDGE = Color("#536e83")

static func stage_polygon() -> PackedVector2Array:
	return PackedVector2Array([Vector2(206,190),Vector2(1054,190),
		Vector2(1080,204),Vector2(1150,582),Vector2(1128,600),
		Vector2(132,600),Vector2(110,582),Vector2(180,204)])

static func closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty(): result.append(result[0])
	return result

static func draw_stage(canvas: CanvasItem) -> void:
	var shape := stage_polygon()
	canvas.draw_colored_polygon(shape, Color(EDGE,0.09))
	canvas.draw_polyline(closed(shape),Color(EDGE,0.30),7.0,true)
	canvas.draw_polyline(closed(shape),Color("#d9eaf0",0.62),1.0,true)
	for x in [280.0,420.0,560.0,700.0,840.0,980.0]:
		canvas.draw_line(Vector2(x,594),Vector2(x+24,594),Color(EDGE,0.48),3.0,true)
		canvas.draw_line(Vector2(x,196),Vector2(x+16,196),Color(EDGE,0.35),2.0,true)

static func pad(rect: Rect2) -> PackedVector2Array:
	var c := rect.get_center() - Vector2(0,8)
	return PackedVector2Array([c+Vector2(-42,-24),c+Vector2(46,-24),
		c+Vector2(52,-17),c+Vector2(44,24),c+Vector2(-48,24),
		c+Vector2(-53,17),c+Vector2(-46,-18)])

static func draw_pad(canvas: CanvasItem, rect: Rect2, enemy: bool) -> void:
	var shape := pad(rect)
	var tint := Color("#df9386") if enemy else CYAN
	canvas.draw_colored_polygon(shape, Color(tint,0.035 if enemy else 0.10))
	canvas.draw_polyline(closed(shape),Color(tint,0.30 if enemy else 0.85),1.3,true)

static func reach_polygon(position: Vector2, radius: float) -> PackedVector2Array:
	var circle := PackedVector2Array()
	for i in range(128):
		circle.append(Board.project_unclamped(position+Vector2.from_angle(TAU*i/128.0)*radius)+Vector2(0,13))
	var pieces := Geometry2D.intersect_polygons(circle,stage_polygon())
	return pieces[0] if not pieces.is_empty() else PackedVector2Array()

static func draw_reach(canvas: CanvasItem, position: Vector2, radius: float) -> void:
	var shape := reach_polygon(position,radius)
	if shape.size() < 3: return
	canvas.draw_colored_polygon(shape,Color(CYAN,0.10))
	# Clip the fill, but never turn the field boundary into a fake range edge.
	var stage := stage_polygon()
	for i in range(128):
		var a := Board.project_unclamped(position+Vector2.from_angle(TAU*i/128.0)*radius)+Vector2(0,13)
		var b := Board.project_unclamped(position+Vector2.from_angle(TAU*(i+1)/128.0)*radius)+Vector2(0,13)
		if not Geometry2D.is_point_in_polygon(a,stage) or not Geometry2D.is_point_in_polygon(b,stage): continue
		canvas.draw_line(a,b,Color(CYAN,0.08),7.0,true)
		canvas.draw_line(a,b,Color("#8ce8f5",0.85),1.5,true)

static func draw_shadow(canvas: CanvasItem, at: Vector2) -> void:
	var shape := PackedVector2Array()
	for i in range(32):
		shape.append(at+Vector2(cos(TAU*i/32.0)*28,sin(TAU*i/32.0)*7))
	canvas.draw_colored_polygon(shape,Color("#1d3541",0.22))
