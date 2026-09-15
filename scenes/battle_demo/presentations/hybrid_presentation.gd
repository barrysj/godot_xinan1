extends Node2D
## Stateless adapter: AnimationPlayer never advances itself or emits combat events.
## SpriteFrames fallback remains in the shared battle renderer using the same context.
@export var canvas_size := Vector2(288, 288)
@export var player_path: NodePath = ^"AnimationPlayer"
@onready var player: AnimationPlayer = get_node(player_path)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	set_process(false)
	visible = false

func handles_presentation_state(state: StringName) -> bool:
	return player != null and player.has_animation(state)

func apply_presentation(context: Dictionary) -> void:
	var state: StringName = context.get("state", &"idle")
	visible = handles_presentation_state(state)
	if not visible: return
	position = context.get("center", Vector2.ZERO)
	var dimensions: Vector2 = context.get("display_size", canvas_size)
	scale = dimensions / canvas_size
	if not context.get("facing_right", true): scale.x *= -1
	modulate = context.get("tint", Color.WHITE)
	var clip := player.get_animation(state)
	var cursor: float
	if state in [&"idle", &"move", &"critical"]:
		cursor = fmod(float(context.get("motion_time", 0.0)), clip.length)
	else:
		cursor = clampf(float(context.get("age", 0.0)) / maxf(float(context.get("duration", clip.length)), 0.001), 0, 1) * clip.length
	player.play(state)
	player.seek(cursor, true)
	player.pause()
