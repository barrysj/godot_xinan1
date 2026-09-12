extends RefCounted
## Rotate the logical grid and reserve safe margins for scenery and unit labels.
const DEPTH_X = [1000.0, 905.0, 810.0, 630.0, 450.0, 355.0, 260.0]
const ROW_Y = [215.0, 250.0, 320.0, 390.0, 460.0, 530.0, 555.0]
static func axis(value: float, stops: Array) -> float:
	var at := clampf(value, 0, 6)
	var index := mini(int(at), 5)
	return lerpf(stops[index], stops[index + 1], at - index)

static func project(cell: Vector2) -> Vector2:
	return Vector2(axis(cell.y, DEPTH_X), axis(cell.x, ROW_Y))

static func direction(value: Vector2) -> Vector2:
	return Vector2(-value.y, value.x)

static func slot_rect(side: int, slot: int) -> Rect2:
	var unit = {"side": side, "slot": slot}
	preload("res://game/combat/auto_battle.gd").initialize(unit)
	return Rect2(project(unit.position) + Vector2(-55, -24), Vector2(110, 90))
