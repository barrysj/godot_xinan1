extends "res://scenes/expedition/expanded_campus_map.gd"
## Actual four-stop campaign on the shared full-campus atlas; no alternate journey.
signal picked(index: int)
const Presentation = preload("res://game/run/campus_presentation.gd")
var journey
var selected := 0
func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(820,680)
	selection_enabled = false
	hover_overrides_selection = false
	place_picked.connect(_choose_place)
func route_at(_at: Vector2) -> int:
	return -1
func place_title(place: String) -> String:
	return Presentation.title(journey.data.region,place,journey.data.flow)
func place_at(at: Vector2) -> String:
	if journey == null or not Rect2(Vector2.ZERO,size).has_point(at): return ""
	var nearest := ""
	var distance := 32.0
	for place in journey.data.map[journey.data.step]:
		var d: float = at.distance_to(project(Presentation.point(journey.data.region,place,layout,journey.data.flow)))
		if d < distance:
			nearest = place
			distance = d
	return nearest
func _choose_place(place: String) -> void:
	var index: int = journey.data.map[journey.data.step].find(place)
	if index < 0: return
	choose(index)
func choose(index: int) -> void:
	if index < 0 or index >= journey.data.map[journey.data.step].size(): return
	selected = index
	selected_place = journey.data.map[journey.data.step][index]
	queue_redraw()
	picked.emit(index)
func _draw_overlay() -> void:
	if journey == null: return
	var map: Array = journey.data.map
	var step := int(journey.data.step)
	var region := str(journey.data.region)
	# Completed forks keep only the route the player actually travelled.
	for layer in range(map.size()-1):
		var start: Array = [journey.data.visited[layer]] if layer < step else map[layer]
		var finish: Array = [journey.data.visited[layer+1]] if layer+1 < step else map[layer+1]
		for a in start:
			for b in finish:
				var from := project(Presentation.point(region,a,layout,journey.data.flow))
				var to := project(Presentation.point(region,b,layout,journey.data.flow))
				overlay.draw_line(from,to,Color("0b1826"),6,true)
				overlay.draw_line(from,to,Color("7be1ec",.85 if layer < step else .38),2,true)
	for layer in range(map.size()):
		var places: Array = [journey.data.visited[layer]] if layer < step else map[layer]
		for index in range(places.size()):
			var place: String = places[index]
			var at := project(Presentation.point(region,place,layout,journey.data.flow))
			var current := layer == step
			var chosen := current and index == selected
			var color := Color("fff1b6") if chosen else Color("7be1ec") if current else Color("a7b8c4")
			var radius := 23.0 if current else 17.0
			overlay.draw_circle(at,radius+3,Color("0c1d2c",.95))
			overlay.draw_circle(at,radius,color,false,2,true)
			overlay.draw_string(font,at+Vector2(-7,7),str(layer+1),HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
			var label := Presentation.title(region,place,journey.data.flow)
			var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+18
			var box := Rect2(at+Vector2(-width/2, -62 if index == 0 else 31),Vector2(width,29))
			box.position = box.position.clamp(Vector2(8,8),size-box.size-Vector2(8,8))
			overlay.draw_rect(box,Color("102236",.94))
			overlay.draw_rect(box,color,false,1)
			overlay.draw_string(font,box.position+Vector2(9,21),label,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
