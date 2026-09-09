extends RefCounted
## Presentation clock only: never delays or changes simulation damage.
const PRIORITY = {"hurt": 1, "attack": 2, "cast": 3, "death": 4}
var config: Resource
var state: StringName = &"idle"
var age := 0.0
var alive := true
var critical := false

func _init(animation_set: Resource = null) -> void:
	config = animation_set

func _has_clip(clip: StringName) -> bool:
	return config != null and config.frames != null and config.frames.has_animation(clip) and config.frames.get_frame_count(clip) > 0 and config.frames.get_animation_speed(clip) > 0

func _duration(clip: StringName) -> float:
	if not _has_clip(clip): return 0.0
	var total := 0.0
	for i in config.frames.get_frame_count(clip):
		total += config.frames.get_frame_duration(clip, i)
	return total / config.frames.get_animation_speed(clip)

func _rest() -> void:
	state = &"critical" if critical and _has_clip(&"critical") else &"idle"
	age = 0.0

func sync_health(hp: float, maximum: float) -> void:
	var was_alive := alive
	alive = hp > 0
	critical = alive and maximum > 0 and hp / maximum <= (config.critical_ratio if config != null else 0.25)
	if not alive:
		if state != &"death":
			state = &"death"
			age = 0.0
	elif not was_alive or state in [&"idle", &"critical"]:
		var rest: StringName = &"critical" if critical and _has_clip(&"critical") else &"idle"
		if state != rest or not was_alive: _rest()

func play(action: StringName) -> void:
	if not alive or not _has_clip(action): return
	if PRIORITY.get(action, 0) < PRIORITY.get(state, 0): return
	# Repeated hits cannot keep the hurt clip frozen on its first frame.
	if state == action and action == &"hurt": return
	state = action
	age = 0.0

func advance(delta: float) -> void:
	age += maxf(delta, 0.0)
	if state in [&"attack", &"cast", &"hurt"] and age >= _duration(state):
		_rest()

func texture() -> Texture2D:
	if not _has_clip(state): return null
	var duration := _duration(state)
	var cursor := fmod(age, duration) if state in [&"idle", &"critical"] else minf(age, duration)
	for i in config.frames.get_frame_count(state):
		cursor -= config.frames.get_frame_duration(state, i) / config.frames.get_animation_speed(state)
		if cursor < 0 or i == config.frames.get_frame_count(state) - 1:
			return config.frames.get_frame_texture(state, i)
	return null
