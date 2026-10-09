@tool
extends Resource
## Optional cast presentation. Never changes attack timing, trajectory or damage.
enum Shape { PRECISION, HEAVY }
@export var shape: Shape = Shape.PRECISION
@export var color := Color("62e9ff")
@export var accent := Color("ffca65")
## Logical screen offset from the unit projection; x mirrors with facing.
@export var muzzle_offset := Vector2(90, -70)
@export_range(0.25, 2.0, 0.05) var intensity := 1.0
