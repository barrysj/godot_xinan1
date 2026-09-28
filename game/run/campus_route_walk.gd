extends RefCounted
## Ephemeral route rehearsal. Never reads or writes campaign progress.
const Geometry = preload("res://game/run/campus_route_geometry.gd")
var route = -1
var step = -1
var complete = false

func start(index: int) -> bool:
	if route >= 0 or index < 0 or index >= Geometry.ROUTES.size(): return false
	route = index
	step = 0
	complete = false
	return true

func advance() -> bool:
	if route < 0 or complete: return false
	if step < Geometry.ROUTES[route].places.size() - 1:
		step += 1
	else:
		complete = true
	return true

func current_place() -> String:
	return "" if route < 0 else Geometry.ROUTES[route].places[step]

func reset() -> void:
	route = -1
	step = -1
	complete = false
