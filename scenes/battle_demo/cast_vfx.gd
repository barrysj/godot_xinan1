extends RefCounted
## Transient drawing data lives beside the view, never inside the simulation.
var bursts: Array[Dictionary] = []

func clear() -> void:
	bursts.clear()

func advance(delta: float) -> void:
	for burst in bursts: burst.age += delta
	bursts = bursts.filter(func(burst): return burst.age < burst.duration)

func remaining() -> float:
	var result := 0.0
	for burst in bursts: result = maxf(result, burst.duration - burst.age)
	return result

func consume(event: Dictionary, style: Resource, muzzle: Vector2, hit: Vector2) -> void:
	if style == null: return
	var kind: String = event.kind
	if kind == "action_released" and event.get("casts", false):
		for burst in bursts:
			if burst.kind == "release" and burst.action_id == event.action_id and burst.target_id == event.target_id: return
		bursts.append({"kind": "release", "age": 0.0, "duration": 0.40 if style.shape == 0 else 0.60,
			"style": style, "position": muzzle, "direction": (hit - muzzle).normalized(),
			"action_id": event.action_id, "target_id": event.target_id})
	elif kind == "impact" and event.get("special", false) and event.get("effect", "") == "damage":
		# Several damage effects can share a target/action. Only one visual flash.
		for burst in bursts:
			if burst.kind == "impact" and burst.action_id == event.action_id and burst.target_id == event.target_id: return
		bursts.append({"kind": "impact", "age": 0.0, "duration": 0.32 if style.shape == 0 else 0.48,
			"style": style, "position": hit, "direction": (hit - muzzle).normalized(),
			"action_id": event.action_id, "target_id": event.target_id})

## A wavefront expands across the shot axis while travelling away from the muzzle.
## Draw and capture use the same geometry; direction handles both facing and aim.
func sonic_rings(burst: Dictionary) -> Array[Dictionary]:
	var rings: Array[Dictionary] = []
	if burst.kind != "release": return rings
	var heavy: bool = burst.style.shape == 1
	var direction: Vector2 = burst.direction
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	direction = direction.normalized()
	var normal := direction.orthogonal()
	for index in range(2 if heavy else 1):
		var delay := index * 0.085
		var age: float = burst.age - delay
		var duration: float = burst.duration - delay
		if age < 0.0 or age >= duration: continue
		var progress := clampf(age / duration, 0.0, 1.0)
		var expansion := 1.0 - pow(1.0 - progress, 2.0)
		var radius: float = lerpf(14.0, 60.0, expansion) if heavy else lerpf(9.0, 38.0, expansion)
		if index == 1: radius *= 0.76
		var center: Vector2 = burst.position + direction * (8.0 + progress * (52.0 if heavy else 46.0))
		var points := PackedVector2Array()
		for segment in range(49):
			var angle := segment * TAU / 48.0
			points.append(center + direction * cos(angle) * radius * 0.30 + normal * sin(angle) * radius)
		rings.append({"center": center, "direction": direction, "radius": radius,
			"points": points, "index": index, "progress": progress,
			"width": (3.2 if heavy else 2.0) * (1.0 - progress * 0.45),
			"alpha": pow(1.0 - progress, 1.4) * (0.8 if index == 1 else 1.0)})
	return rings

func draw_charge(canvas: CanvasItem, style: Resource, at: Vector2, progress: float, time: float) -> void:
	var strength := smoothstep(0.0, 1.0, progress)
	var radius: float = (10.0 if style.shape == 0 else 20.0) * (0.45 + strength * 0.55)
	_halo(canvas, at, radius * 1.15, style.color, strength * 0.2 * style.intensity)
	_arc(canvas, at, radius, style.color, strength * 0.8, time * 2, Vector2(0.55, 1.0))
	if style.shape == 1:
		_arc(canvas, at, radius + 5, style.color, strength * 0.5, -time * 2, Vector2(0.55, 1.0))
	for i in range(5 if style.shape == 0 else 8):
		var angle := i * TAU / (5.0 if style.shape == 0 else 8.0) + time * 1.7
		var radial := Vector2.from_angle(angle)
		var distance := radius + 6 + fmod(1.0 - progress + i * 0.17, 1.0) * 18
		canvas.draw_line(at + radial * distance, at + radial * (distance + 4), Color(style.color, strength * 0.7), 1.5, true)
	_spark(canvas, at, Vector2.RIGHT, 3 + strength * 5, Color("f4ffff", strength))

func draw_projectile(canvas: CanvasItem, style: Resource, at: Vector2, direction: Vector2, age: float) -> void:
	var length: float = 58.0 if style.shape == 0 else 37.0
	var width: float = 3.0 if style.shape == 0 else 9.0
	var rear := at - direction * length
	_streak(canvas, at, direction, length, width * 1.1, Color(style.color, 0.45 * style.intensity))
	_streak(canvas, at + direction * 3, direction, length * 0.7, width * 0.4, Color("f1ffff", 0.9))
	if style.shape == 1:
		var sideways := direction.orthogonal()
		for sign in [-1.0, 1.0]:
			var offset: Vector2 = sideways * sign * (5 + sin(age * 25) * 1.5)
			canvas.draw_line(rear + direction * 8 + offset, at - direction * 6 + offset * 0.25, Color(style.color, 0.55), 1.2, true)

func draw_bursts(canvas: CanvasItem) -> void:
	for burst in bursts:
		var style: Resource = burst.style
		var t: float = burst.age / burst.duration
		var fade := pow(1.0 - t, 1.7)
		var heavy: bool = style.shape == 1
		var at: Vector2 = burst.position
		var direction: Vector2 = burst.direction
		if direction.is_zero_approx(): direction = Vector2.RIGHT
		var perpendicular := direction.orthogonal()
		if burst.kind == "release":
			for ring in sonic_rings(burst):
				var alpha: float = clampf(ring.alpha * style.intensity, 0.0, 1.0)
				# A narrow colored edge and white core keep the 2D wave readable.
				canvas.draw_polyline(ring.points, Color(style.color, alpha * 0.18), ring.width + 4, true)
				canvas.draw_polyline(ring.points, Color(style.color, alpha * 0.95), ring.width, true)
				canvas.draw_polyline(ring.points, Color("f3ffff", alpha * 0.8), 0.85, true)
				for sign in [-1.0, 1.0]:
					var tip: Vector2 = ring.center + perpendicular * sign * ring.radius * 0.75
					canvas.draw_line(tip - direction * (18 if heavy else 12), tip - direction * 3,
						Color(style.color, alpha * 0.6), 1.2, true)
			# Muzzle ignition dies sooner than the travelling pressure wave.
			t = clampf(burst.age / (0.28 if heavy else 0.18), 0.0, 1.0)
			fade = pow(1.0 - t, 1.7)
			var radius: float = (24.0 if heavy else 13.0) + t * (22.0 if heavy else 10.0)
			_halo(canvas, at, radius * 0.7, style.color, fade * 0.22 * style.intensity)
			_spark(canvas, at, direction, (21 if heavy else 12) * fade, Color(style.color, fade * 0.95))
			_spark(canvas, at, direction, (15 if heavy else 8) * fade, Color("f2ffff", fade))
			for sign in [-1.0, 1.0]:
				var offset: Vector2 = perpendicular * sign * (8 if heavy else 4) * fade
				canvas.draw_line(at - direction * 6 + offset, at + direction * (24 if heavy else 14) + offset * 0.2, Color(style.color, fade * 0.8), 1.4, true)
		else:
			var radius: float = 7 + t * (43 if heavy else 25)
			_halo(canvas, at, (18 if heavy else 11) * fade, style.color, fade * 0.25 * style.intensity)
			if heavy: _arc(canvas, at, radius, style.color, fade * 0.65, 0.3, Vector2.ONE)
			for i in range(8 if heavy else 6):
				var radial := Vector2.from_angle(i * TAU / (8.0 if heavy else 6.0) + 0.23)
				_streak(canvas, at + radial * (radius + (12 if heavy else 7) * fade), radial, (13 if heavy else 8) * fade, 1.5 * fade, Color(style.color, fade))
			_spark(canvas, at, direction, 12 * fade, Color("f6ffff", fade))

func _halo(canvas: CanvasItem, at: Vector2, radius: float, color: Color, alpha: float) -> void:
	for layer in range(4, 0, -1):
		canvas.draw_circle(at, radius * layer / 4.0, Color(color, alpha * 0.18))

func _arc(canvas: CanvasItem, at: Vector2, radius: float, color: Color, alpha: float, rotation: float, stretch: Vector2) -> void:
	for sector in range(3):
		var points := PackedVector2Array()
		for i in range(9): points.append(at + Vector2.from_angle(sector * TAU / 3.0 + i * 0.115 + rotation) * stretch * radius)
		canvas.draw_polyline(points, Color(color, alpha), 1.4, true)

func _spark(canvas: CanvasItem, at: Vector2, direction: Vector2, radius: float, color: Color) -> void:
	if radius < 0.25 or color.a < 0.005: return
	var points := PackedVector2Array()
	for i in range(8):
		var distance := radius * (0.23 if i % 2 else (1.0 if i % 4 == 0 else 0.72))
		points.append(at + Vector2.from_angle(direction.angle() + i * TAU / 8.0) * distance)
	canvas.draw_colored_polygon(points, color)

func _streak(canvas: CanvasItem, at: Vector2, direction: Vector2, length: float, width: float, color: Color) -> void:
	if length < 0.25 or width < 0.05 or color.a < 0.005: return
	var middle := at - direction * length * 0.3
	var normal := direction.orthogonal() * width
	canvas.draw_colored_polygon(PackedVector2Array([at, middle + normal, at - direction * length, middle - normal]), color)
