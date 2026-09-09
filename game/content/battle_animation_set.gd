extends Resource
## Optional battle presentation. Clip names: idle, attack, hurt, cast, critical, death.
## Single-shot clips ignore their SpriteFrames loop flag; idle/critical always loop.
@export var frames: SpriteFrames
@export var display_size := Vector2(64, 64)
@export var anchor := Vector2(0.5, 0.875)
@export_range(0.0, 1.0) var critical_ratio: float = 0.25
