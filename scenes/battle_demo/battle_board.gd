extends RefCounted
## Rotate the existing logical grid; formation IDs and combat distances stay unchanged.
static func project(cell: Vector2) -> Vector2:
	return Vector2(1170 - cell.y * 180, 215 + cell.x * 50)

static func direction(value: Vector2) -> Vector2:
	return Vector2(-value.y, value.x)

static func slot_rect(side: int, slot: int) -> Rect2:
	var unit = {"side": side, "slot": slot}
	preload("res://game/combat/auto_battle.gd").initialize(unit)
	return Rect2(project(unit.position) + Vector2(-55, -24), Vector2(110, 90))
