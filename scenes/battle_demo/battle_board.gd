extends RefCounted
## Rotate the logical grid and reserve safe margins for scenery and unit labels.
const DEPTH_X = [1000.0, 876.666667, 753.333333, 630.0, 506.666667, 383.333333, 260.0]
const ROW_Y = [220.0, 278.0, 336.0, 394.0, 452.0, 510.0, 568.0]
static func axis(value: float, stops: Array) -> float:
	var at := clampf(value, 0, 6)
	var index := mini(int(at), 5)
	return lerpf(stops[index], stops[index + 1], at - index)

static func project(cell: Vector2) -> Vector2:
	return Vector2(axis(cell.y, DEPTH_X), axis(cell.x, ROW_Y))

static func project_unclamped(cell: Vector2) -> Vector2:
	# One affine map keeps circular logical reach smooth and truthful on the floor.
	return Vector2(1000.0 - cell.y * (740.0 / 6.0), 220.0 + cell.x * 58.0)

static func direction(value: Vector2) -> Vector2:
	return Vector2(-value.y, value.x)

static func slot_rect(side: int, slot: int) -> Rect2:
	var unit = {"side": side, "slot": slot}
	preload("res://game/combat/auto_battle.gd").initialize(unit)
	return Rect2(project(unit.position) + Vector2(-55, -24), Vector2(110, 90))
