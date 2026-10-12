extends "res://scenes/expedition/expanded_campus_map.gd"
## Actual four-stop campaign on the shared full-campus atlas; no alternate journey.
signal picked(index: int)
signal candidate_previewed(index: int)
const Presentation = preload("res://game/run/campus_presentation.gd")
var journey
var selected := 0
var selection_flash := 0.0
var selection_tween: Tween
var hovered_candidate := -1
var spatial_targets := false
func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2.ZERO
	selection_enabled = false
	hover_overrides_selection = false
	place_picked.connect(_choose_place)
	mouse_exited.connect(func(): preview_candidate(-1))

func preview_candidate(index: int) -> void:
	if hovered_candidate == index: return
	hovered_candidate = index
	if overlay != null: overlay.queue_redraw()
	candidate_previewed.emit(index)

func _gui_input(event: InputEvent) -> void:
	super._gui_input(event)
	if event is InputEventMouseMotion and not dragging:
		var place := place_at(event.position)
		preview_candidate(journey.data.map[journey.data.step].find(place))
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
	if selection_tween != null and selection_tween.is_valid(): selection_tween.kill()
	selection_flash = 1.0
	selection_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var timing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/animation.json"))
	selection_tween.tween_method(func(value: float): selection_flash = value; overlay.queue_redraw(), 1.0, 0.0, float(timing.durations_ms.emphasis) / 1000.0)
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
				var line_color := Color("ffffff", .65 if layer < step else .35)
				overlay.draw_line(from,to,line_color,2,true)
	if spatial_targets: return
	for layer in range(map.size()):
		var places: Array = [journey.data.visited[layer]] if layer < step else map[layer]
		for index in range(places.size()):
			var place: String = places[index]
			var at := project(Presentation.point(region,place,layout,journey.data.flow))
			var current := layer == step
			var chosen := current and index == selected
			var hovering := current and index == hovered_candidate
			var color := Color("fff1b6") if chosen else Color("7be1ec") if current else Color("a7b8c4", .9 if layer < step else .6)
			var radius := 23.0 if current else 17.0
			if hovering and not chosen: overlay.draw_circle(at, radius+8, Color("7be1ec", .2))
			if chosen:
				overlay.draw_circle(at, radius+9, Color("fff1b6", .17))
				if selection_flash > .01:
					overlay.draw_circle(at, radius+9+(1.0-selection_flash)*14, Color("fff1b6", selection_flash*.65), false, 2, true)
			overlay.draw_circle(at,radius+3,Color("0c1d2c",.95))
			overlay.draw_circle(at,radius,color,false,2,true)
			overlay.draw_string(font,at+Vector2(-7,7),"✓" if layer < step else str(layer+1),HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
			if current and spatial_targets: continue
			var label := Presentation.title(region,place,journey.data.flow)
			var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+18
			var box := Rect2(at+Vector2(-width/2, -62 if index == 0 else 31),Vector2(width,29))
			box.position = box.position.clamp(Vector2(8,8),size-box.size-Vector2(8,8))
			overlay.draw_rect(box,Color("102236",.94))
			overlay.draw_rect(box,color,false,1)
			overlay.draw_string(font,box.position+Vector2(9,21),label,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
