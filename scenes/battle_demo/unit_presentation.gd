extends RefCounted
## Per-unit view state. No combat decisions, resources remain shared and immutable.
var hurt_age := 1.0
var hurt_direction := Vector2.ZERO
var death_age := 0.0
var alive := true
var facing_right := true
var motion_time := 0.0
var action: Dictionary = {}

func consume(event: Dictionary) -> void:
	if event.kind == "action_started":
		action = {"age": 0.0, "windup": event.windup, "duration": event.duration,
			"direction": (event.to - event.from).normalized(), "casts": event.casts}
	elif event.kind in ["action_cancelled", "action_finished"]:
		action = {}
	elif event.kind == "impact" and event.effect == "damage" and event.actual > 0:
		hurt_age = 0
		hurt_direction = (event.to - event.from).normalized()

func advance(delta: float, unit: Dictionary) -> void:
	var now_alive: bool = unit.hp > 0
	if now_alive != alive:
		death_age = 0
		action = {}
		alive = now_alive
	if not alive: death_age += delta
	hurt_age += delta
	motion_time += delta
	if not action.is_empty(): action.age = minf(action.age + delta, action.duration)
	var direction: Vector2 = unit.get("screen_facing", unit.get("facing", Vector2.ZERO))
	if absf(direction.x) > 0.15: facing_right = direction.x > 0

func pose(unit: Dictionary, animated: bool) -> Dictionary:
	var offset := Vector2.ZERO
	var rotation := 0.0
	var stretch := Vector2.ONE
	var tint := Color.WHITE
	if not alive:
		var progress = clampf(death_age / 0.45, 0, 1)
		# A supplied death clip owns its pose; fallback settles gently to the floor.
		if not animated:
			rotation = progress * 0.65 * (1 if facing_right else -1)
			offset.y = progress * 8
		tint = Color.WHITE.lerp(Color(0.55, 0.57, 0.60, 0.24), progress)
	elif not animated:
		if not action.is_empty():
			var direction: Vector2 = action.direction * Vector2(1, 0.67)
			if action.age < action.windup:
				var anticipation: float = action.age / action.windup
				offset = -direction * 5 * sin(anticipation * PI * 0.5)
				stretch = Vector2(1 + anticipation * 0.05, 1 - anticipation * 0.05)
			else:
				var recovery: float = clampf((action.age - action.windup) / maxf(0.05, action.duration - action.windup), 0, 1)
				offset = direction * 13 * pow(1 - recovery, 2)
				rotation = direction.x * 0.12 * (1 - recovery)
		elif unit.get("moving", false):
			var stride = sin(motion_time * 16)
			offset.y = -absf(stride) * 3
			rotation = stride * 0.055
		else:
			stretch.y = 1 + sin(motion_time * 3 + unit.slot) * 0.015
	if alive and hurt_age < 0.18:
		var strength = 1 - hurt_age / 0.18
		tint = Color.WHITE.lerp(Color(1.8, 1.8, 1.8), strength)
		# Recoil overlays rather than restarting/cancelling attack or cast.
		offset += hurt_direction * Vector2(1, 0.67) * sin(strength * PI) * 5
	return {"offset": offset, "rotation": rotation, "stretch": stretch, "tint": tint,
		"flip": not facing_right}

static func position(unit: Dictionary, alpha: float) -> Vector2:
	return unit.get("previous_position", unit.position).lerp(unit.position, clampf(alpha, 0, 1))
