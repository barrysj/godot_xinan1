extends "res://scenes/expedition/expanded_campus_map.gd"
const Presentation = preload("res://game/run/campus_presentation.gd")
var flow: Dictionary = {}
func _ready() -> void:
	super._ready()
	selection_enabled = false
	hover_overrides_selection = false
func route_at(_at: Vector2) -> int:
	return -1
func place_title(id: String) -> String:
	return str(flow.get("stops",{}).get(id,{}).get("title",id))
func place_at(at: Vector2) -> String:
	var nearest := ""
	var distance := 32.0
	if flow.is_empty() or not Rect2(Vector2.ZERO,size).has_point(at): return nearest
	for id in flow.stops:
		var d := at.distance_to(project(Presentation.point(flow.region,id,layout,flow)))
		if d < distance:
			nearest = id
			distance = d
	return nearest
func _draw_overlay() -> void:
	if flow.is_empty(): return
	for i in range(flow.layers.size()-1):
		for a in flow.layers[i]:
			for b in flow.layers[i+1]:
				var p := project(Presentation.point(flow.region,a,layout,flow))
				var q := project(Presentation.point(flow.region,b,layout,flow))
				overlay.draw_line(p,q,Color("0b1826"),6,true)
				overlay.draw_line(p,q,Color("7be1ec",.65),2,true)
	for i in range(flow.layers.size()):
		for j in range(flow.layers[i].size()):
			var id: String = flow.layers[i][j]
			var p := project(Presentation.point(flow.region,id,layout,flow))
			var color := Color("fff1b6") if selected_place == id else Color("7be1ec")
			overlay.draw_circle(p,20,Color("102231"))
			overlay.draw_circle(p,20,color,false,2,true)
			overlay.draw_string(font,p+Vector2(-6,7),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
			var name: String = flow.stops[id].title
			var width := font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+16
			var box := Rect2(p+Vector2(-width/2,-57 if j == 0 else 28),Vector2(width,27))
			box.position = box.position.clamp(Vector2(8,8),size-box.size-Vector2(8,8))
			overlay.draw_rect(box,Color("102231",.95))
			overlay.draw_string(font,box.position+Vector2(8,20),name,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
