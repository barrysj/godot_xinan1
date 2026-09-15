@tool
class_name BattleProjectileStyle
extends Resource
## Optional presentation for a projectile. Gameplay trajectory and timing stay in BattleSimulation.

@export var texture: Texture2D
@export var display_size := Vector2(24, 12)
@export var anchor := Vector2(0.5, 0.5)
@export_range(-180.0, 180.0, 1.0) var rotation_offset_degrees := 0.0
@export_range(0.0, 16.0, 0.5) var trail_gap := 2.0

func usable() -> bool:
	return texture != null and display_size.x > 0.0 and display_size.y > 0.0
