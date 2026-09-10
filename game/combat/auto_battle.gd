extends RefCounted
## Board coordinates are independent of presentation and simulation speed.
const BOARD_SIZE = Vector2i(7, 7)
const DIRECTIONS = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]

static func initialize(unit: Dictionary) -> void:
	var row = int(unit.slot / 3)
	unit.cell = Vector2i(1 + unit.slot % 3 * 2, (2 - row * 2) if unit.side == 1 else (4 + row * 2))
	unit.position = Vector2(unit.cell)
	unit.destination = unit.cell
	unit.target_id = -1
	unit.moving = false

static func distance(a: Dictionary, b: Dictionary) -> float:
	return a.position.distance_to(b.position)

static func in_range(actor: Dictionary, target: Dictionary) -> bool:
	return target.hp > 0 and distance(actor, target) <= actor.attack_range + 0.001

static func advance(actor: Dictionary, units: Array[Dictionary], delta: float) -> Dictionary:
	actor.timer = maxf(0, actor.timer - delta)
	if actor.moving:
		actor.position = actor.position.move_toward(Vector2(actor.destination), actor.move_speed * delta)
		if actor.position.is_equal_approx(Vector2(actor.destination)):
			actor.cell = actor.destination
			actor.moving = false
		return {}
	var foes: Array[Dictionary] = units.filter(func(u): return u.side != actor.side and u.hp > 0)
	if foes.is_empty(): return {}
	# Keep a valid target in reach; otherwise prefer the nearest enemy in reach.
	for foe in foes:
		if foe.id == actor.target_id and in_range(actor, foe): return foe
	var nearest: Dictionary = {}
	for foe in foes:
		if in_range(actor, foe) and (nearest.is_empty() or distance(actor, foe) < distance(actor, nearest)):
			nearest = foe
	if not nearest.is_empty():
		actor.target_id = nearest.id
		return nearest
	# BFS finds the nearest reachable firing cell, going around allies and enemies.
	# Reserve both ends of travel to prevent stacking and head-on swaps.
	var blocked = {}
	for other in units:
		if other.hp > 0 and other.id != actor.id:
			blocked[other.cell] = true
			blocked[other.destination] = true
	var frontier: Array[Vector2i] = [actor.cell]
	var first_step = {actor.cell: actor.cell}
	var cursor = 0
	actor.target_id = -1
	while cursor < frontier.size():
		var cell = frontier[cursor]
		cursor += 1
		for foe in foes:
			if Vector2(cell).distance_to(foe.position) <= actor.attack_range + 0.001:
				actor.target_id = foe.id
				actor.destination = first_step[cell]
				actor.moving = actor.destination != actor.cell
				return {}
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if next.x < 0 or next.y < 0 or next.x >= BOARD_SIZE.x or next.y >= BOARD_SIZE.y: continue
			if blocked.has(next) or first_step.has(next): continue
			first_step[next] = next if cell == actor.cell else first_step[cell]
			frontier.append(next)
	return {}
