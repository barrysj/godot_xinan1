extends Node
const Combat = preload("res://game/combat/auto_battle.gd")
var failures = 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func pawn(id: int, side: int, cell: Vector2i, reach: float = 1.45) -> Dictionary:
	return {"id": id, "side": side, "cell": cell, "destination": cell,
		"position": Vector2(cell), "hp": 100.0, "timer": 0.0,
		"attack_range": reach, "move_speed": 2.4, "target_id": -1, "moving": false}

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var melee = pawn(0, 0, Vector2i(3, 6))
	var foe = pawn(1, 1, Vector2i(3, 0))
	var blocker = pawn(2, 0, Vector2i(3, 5))
	var units: Array[Dictionary] = [melee, foe, blocker]
	check(Combat.advance(melee, units, 0.05).is_empty(), "Cannot attack outside reach")
	check(melee.destination != blocker.cell and melee.moving, "Path routes around ally")
	var reached = false
	for step in range(160):
		var target = Combat.advance(melee, units, 0.05)
		check(melee.destination != blocker.cell and melee.destination != foe.cell, "Occupied cells reserved")
		if not target.is_empty():
			check(Combat.in_range(melee, target) and not melee.moving, "Stops in range before attack")
			reached = true
			break
	check(reached, "Melee reaches distant enemy")
	foe.hp = 0
	var next_foe = pawn(3, 1, Vector2i(6, 0))
	units.append(next_foe)
	Combat.advance(melee, units, 0.05)
	check(melee.target_id == 3, "Retarget after death")
	var ranged = pawn(4, 0, Vector2i(3, 3), 3.2)
	foe.hp = 100
	units = [ranged, foe]
	check(not Combat.advance(ranged, units, 0.05).is_empty() and not ranged.moving, "Ranged holds distance")
	foe.position = Vector2(3, 0)
	ranged.position = Vector2(3, 3.21)
	check(not Combat.in_range(ranged, foe), "Range boundary enforced")
	var trapped = pawn(0, 0, Vector2i(0, 0))
	units = [trapped, pawn(1, 0, Vector2i(1, 0)), pawn(2, 0, Vector2i(0, 1)), pawn(3, 1, Vector2i(6, 6))]
	Combat.advance(trapped, units, 0.05)
	check(not trapped.moving and trapped.target_id == -1, "Blocked unit waits safely")
	units[1].hp = 0
	Combat.advance(trapped, units, 0.05)
	check(trapped.moving, "Dead unit releases occupied cell")
	var battle = load("res://scenes/battle_demo/battle_demo.tscn").instantiate()
	add_child(battle)
	battle.set_process(false)
	battle._start()
	var start: Vector2 = battle.units[0].position
	for step in range(12): battle._process(0.05)
	check(battle.units[0].position != start, "Actual battle advances unit positions")
	battle.paused = true
	var frozen: Vector2 = battle.units[0].position
	var time: float = battle.elapsed
	battle._process(1.0)
	check(battle.units[0].position == frozen and battle.elapsed == time, "Pause freezes movement and clock")
	battle._start()
	check(battle.units[0].position == start and battle.units[0].target_id == -1, "Restart resets positions and targets")
	var snapshots = []
	for multiplier in [1, 2]:
		battle._start()
		battle.speed = multiplier
		for frame in range(180 / multiplier): battle._process(1.0 / 60.0)
		var snapshot = []
		for u in battle.units: snapshot.append([u.position, u.hp, u.count, u.target_id])
		snapshots.append(snapshot)
	check(snapshots[0] == snapshots[1], "1x and 2x positions, health and targets agree")
	for step in range(1800):
		if battle.phase != "battle": break
		battle._tick()
		var occupied = {}
		for u in battle.units:
			if u.hp <= 0: continue
			check(not occupied.has(u.cell), "Live units never share source cells")
			occupied[u.cell] = true
	check(battle.phase == "result" and battle.elapsed < 90, "Battle resolves without stalemate")
	battle.free()
	print("AUTO_BATTLE_CHECK ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	get_tree().quit(failures)
