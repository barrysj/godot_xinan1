extends RefCounted
## Presentation clock; simulation action timing is authoritative.
const PRIORITY = {"hurt": 1, "attack": 2, "cast": 3, "death": 4}
var config: Resource
var state: StringName = &"idle"
var age := 0.0
var alive := true
var critical := false
var moving := false
var action_driven := false

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
	state = _rest_clip()
	age = 0.0

func sync_health(hp: float, maximum: float) -> void:
	var was_alive := alive
	alive = hp > 0
	critical = alive and maximum > 0 and hp / maximum <= (config.critical_ratio if config != null else 0.25)
	if not alive:
		if state != &"death":
			state = &"death"
			age = 0.0
	elif not was_alive or state in [&"idle", &"critical", &"move"]:
		var rest: StringName = _rest_clip()
		if state != rest or not was_alive: _rest()

func play(action: StringName) -> void:
	if not alive or not _has_clip(action): return
	if PRIORITY.get(action, 0) < PRIORITY.get(state, 0): return
	# Repeated hits cannot keep the hurt clip frozen on its first frame.
	if state == action and action == &"hurt": return
	state = action
	age = 0.0

func advance(delta: float) -> void:
	if action_driven: return
	age += maxf(delta, 0.0)
	if state in [&"attack", &"cast", &"hurt"] and age >= _duration(state):
		_rest()

func texture() -> Texture2D:
	if not _has_clip(state): return null
	var duration := _duration(state)
	var cursor := fmod(age, duration) if state in [&"idle", &"critical", &"move"] else minf(age, duration)
	for i in config.frames.get_frame_count(state):
		cursor -= config.frames.get_frame_duration(state, i) / config.frames.get_animation_speed(state)
		if cursor < 0 or i == config.frames.get_frame_count(state) - 1:
			return config.frames.get_frame_texture(state, i)
	return null

func _rest_clip() -> StringName:
	if moving and _has_clip(&"move"): return &"move"
	return &"critical" if critical and _has_clip(&"critical") else &"idle"

func sync_motion(is_moving: bool, action: Dictionary) -> void:
	moving = is_moving
	if not alive:
		action_driven = false
		return
	if action.is_empty():
		if action_driven:
			action_driven = false
			_rest()
		elif state in [&"idle", &"critical", &"move"] and state != _rest_clip():
			_rest()
		return
	var clip: StringName = &"cast" if action.casts else &"attack"
	if not _has_clip(clip): return
	action_driven = true
	state = clip
	var impact: float = config.impact_ratio
	var fraction: float
	if action.age < action.windup:
		fraction = action.age / action.windup * impact
	else:
		fraction = impact + (1 - impact) * clampf((action.age - action.windup) / maxf(0.05, action.duration - action.windup), 0, 1)
	age = fraction * _duration(clip)
