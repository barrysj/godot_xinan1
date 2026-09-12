extends Resource
## Simulation timing, independent of frame counts or animation backend.
@export_range(0.05, 1.0, 0.05) var windup: float = 0.20
@export_range(0.05, 1.0, 0.05) var recovery: float = 0.25
@export_range(1.0, 30.0, 0.5) var projectile_speed: float = 8.0
@export_enum("auto", "melee", "projectile") var delivery: String = "auto"

func timing(interval: float) -> Vector2:
	var total = maxf(0.1, windup + recovery)
	var factor = minf(1.0, interval / total)
	var lead = clampf(windup * factor, 0.05, maxf(0.05, interval - 0.05))
	return Vector2(lead, minf(maxf(0.05, recovery * factor), interval - lead))

func is_projectile(reach: float) -> bool:
	return delivery == "projectile" or (delivery == "auto" and reach > 1.5)
