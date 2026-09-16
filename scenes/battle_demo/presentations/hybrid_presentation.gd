extends Node2D
## Stateless adapter: AnimationPlayer never advances itself or emits combat events.
## SpriteFrames fallback remains in the shared battle renderer using the same context.
@export var canvas_size := Vector2(288, 288)
@export var player_path: NodePath = ^"AnimationPlayer"
@onready var player: AnimationPlayer = get_node(player_path)
var cycle_layers: Dictionary = {}
var cycle_players: Array[AnimationPlayer] = []
var active_cycles: Array = []
var selected_clip: StringName = &""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	if player.has_animation_library(&""):
		var library := player.get_animation_library(&"")
		cycle_layers = library.get_meta(&"cycle_layers", {})
		var count := 0
		for layers in cycle_layers.values(): count = maxi(count, layers.size())
		for index in count:
			var layer := AnimationPlayer.new()
			layer.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			add_child(layer)
			layer.add_animation_library(&"", library)
			cycle_players.append(layer)
	set_process(false)
	visible = false

func handles_presentation_state(state: StringName) -> bool:
	return player != null and player.has_animation(state)

func apply_presentation(context: Dictionary) -> void:
	var state: StringName = context.get("state", &"idle")
	visible = handles_presentation_state(state)
	if not visible:
		selected_clip = &""
		return
	position = context.get("center", Vector2.ZERO)
	var dimensions: Vector2 = context.get("display_size", canvas_size)
	scale = dimensions / canvas_size
	if not context.get("facing_right", true): scale.x *= -1
	modulate = context.get("tint", Color.WHITE)
	var clip := player.get_animation(state)
	var changed := selected_clip != state
	if changed:
		if player.has_animation(&"RESET"):
			player.assigned_animation = &"RESET"
			player.seek(0.0, true)
		player.assigned_animation = state
		selected_clip = state
		active_cycles = cycle_layers.get(state, [])
		for index in active_cycles.size():
			cycle_players[index].assigned_animation = active_cycles[index]
	var cursor: float
	if state in [&"idle", &"move", &"critical"]:
		cursor = fmod(float(context.get("motion_time", 0.0)), clip.length)
	else:
		cursor = clampf(float(context.get("age", 0.0)) / maxf(float(context.get("duration", clip.length)), 0.001), 0, 1) * clip.length
	if changed or not clip.get_meta(&"constant_pose", false): player.seek(cursor, true)
	for index in active_cycles.size():
		var layer := cycle_players[index]
		var curve := layer.get_animation(active_cycles[index])
		var period: float = curve.get_meta(&"period", curve.length)
		layer.seek(fposmod(float(context.get("motion_time", 0.0)), period) / period * curve.length, true)
