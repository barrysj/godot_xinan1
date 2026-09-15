extends Resource
## Optional battle presentation. Clip names: idle, move, attack, hurt, cast, critical, death.
## Single-shot clips ignore their SpriteFrames loop flag; idle/critical always loop.
const ProjectileStyle = preload("res://game/content/battle_projectile_style.gd")

@export var frames: SpriteFrames
## Optional rigid/mesh presentation. States it declines fall back to SpriteFrames.
@export var presentation_scene: PackedScene
@export var display_size := Vector2(64, 64)
@export var anchor := Vector2(0.5, 0.875)
@export_range(0.0, 1.0) var critical_ratio: float = 0.25

## Normalized release frame within attack/cast; aligned to simulation windup.
@export_range(0.05, 0.95) var impact_ratio: float = 0.45
## Opt-in for directional art; old front-facing placeholders remain unchanged.
@export var flip_with_facing := false
## Logical screen offsets from the unit projection, independent of occupancy.
@export var launch_offset := Vector2(0, -6)
@export var hit_offset := Vector2(0, -6)
## Optional visual head; absent styles keep the legacy four-dot projectile.
@export var projectile_style: ProjectileStyle
