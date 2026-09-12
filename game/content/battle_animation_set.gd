extends Resource
## Optional battle presentation. Clip names: idle, move, attack, hurt, cast, critical, death.
## Single-shot clips ignore their SpriteFrames loop flag; idle/critical always loop.
@export var frames: SpriteFrames
@export var display_size := Vector2(64, 64)
@export var anchor := Vector2(0.5, 0.875)
@export_range(0.0, 1.0) var critical_ratio: float = 0.25

## Normalized release frame within attack/cast; aligned to simulation windup.
@export_range(0.05, 0.95) var impact_ratio: float = 0.45
## Opt-in for directional art; old front-facing placeholders remain unchanged.
@export var flip_with_facing := false
