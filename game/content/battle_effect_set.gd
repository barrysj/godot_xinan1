@tool
extends Resource
## Optional authored skill burst. Time is supplied by the shared presentation clock.
@export var frames: SpriteFrames
@export var animation: StringName = &"burst"
@export var display_size := Vector2(144, 144)
@export var anchor := Vector2(0.5, 0.5)
@export var offset := Vector2(0, -44)

func duration() -> float:
	if frames == null or not frames.has_animation(animation): return 0.0
	var fps := frames.get_animation_speed(animation)
	if fps <= 0: return 0.0
	var total := 0.0
	for i in frames.get_frame_count(animation): total += frames.get_frame_duration(animation, i)
	return total / fps

func texture(age: float) -> Texture2D:
	if age < 0 or age >= duration(): return null
	var position := age * frames.get_animation_speed(animation)
	for i in frames.get_frame_count(animation):
		var weight := frames.get_frame_duration(animation, i)
		if position < weight: return frames.get_frame_texture(animation, i)
		position -= weight
	return null

