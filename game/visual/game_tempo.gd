extends Node
## Shared clock for simulation, character animation and UI tweens.
const BASE_SCALE := 0.8

func _enter_tree() -> void:
	Engine.time_scale = BASE_SCALE
