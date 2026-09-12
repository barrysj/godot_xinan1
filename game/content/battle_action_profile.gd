extends Resource
## Simulation timing, independent of frame counts or animation backend.
@export_range(0.05, 1.0, 0.05) var windup: float = 0.20
@export_range(0.05, 1.0, 0.05) var recovery: float = 0.25
@export_range(1.0, 30.0, 0.5) var projectile_speed: float = 8.0
@export_enum("auto", "melee", "projectile") var delivery: String = "auto"

func timing(interval: float) -> Vector2:
	# Gear can reduce intervals below the editor's base-stat minimum.
	# Keep both phases positive; simulation steps quantize their actual deadlines.
	var phases = Vector2(maxf(0.001, windup), maxf(0.001, recovery))
	return phases * minf(1.0, maxf(0.001, interval) / (phases.x + phases.y))

func is_projectile(reach: float) -> bool:
	return delivery == "projectile" or (delivery == "auto" and reach > 1.5)
