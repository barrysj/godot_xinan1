extends Resource
## Both backends use idle/move/melee/ranged/cast/hurt/critical/death.
## Single-shot clips ignore their SpriteFrames loop flag; idle/critical always loop.
const ProjectileStyle = preload("res://game/content/battle_projectile_style.gd")

@export var frames: SpriteFrames
## Optional rigid/mesh presentation. States it declines fall back to SpriteFrames.
@export var presentation_scene: PackedScene
@export var animation_library: AnimationLibrary
## Only non-data-driven exceptions may declare an extension and its reason.
@export var presentation_extension: Script
@export_multiline var extension_reason: String = ""

func frame_clip(action: StringName, attack_modes: int = 1) -> StringName:
	if frames == null: return &""
	if frames.has_animation(action): return action
	if action in [&"melee", &"ranged"] and frames.has_animation(&"attack"):
		var bit := 1 if action == &"melee" else 2
		if attack_modes & bit: return &"attack"
	return &""
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
