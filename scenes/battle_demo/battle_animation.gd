extends RefCounted
## Presentation clock; simulation action timing is authoritative.
const PRIORITY = {"hurt": 1, "melee": 2, "ranged": 2, "attack": 2, "cast": 3, "death": 4}
var config: Resource
var attack_modes := 1
var state: StringName = &"idle"
var age := 0.0
var alive := true
var critical := false
var moving := false
var action_driven := false

func _init(animation_set: Resource = null, capabilities: int = 1) -> void:
	config = animation_set
	attack_modes = capabilities

func _canonical(clip: StringName) -> StringName:
	return (&"ranged" if attack_modes == 2 else &"melee") if clip == &"attack" else clip

func _has_clip(clip: StringName) -> bool:
	if config == null: return false
	clip = _canonical(clip)
	if clip == &"melee" and not attack_modes & 1: return false
	if clip == &"ranged" and not attack_modes & 2: return false
	if config.animation_library != null and config.animation_library.has_animation(clip): return true
	var source: StringName = config.frame_clip(clip, attack_modes)
	return source != &"" and config.frames.get_frame_count(source) > 0 and config.frames.get_animation_speed(source) > 0

func _duration(clip: StringName) -> float:
	if not _has_clip(clip): return 0.0
	clip = _canonical(clip)
	var source: StringName = config.frame_clip(clip, attack_modes)
	if source == &"": return config.animation_library.get_animation(clip).length
	var total := 0.0
	for i in config.frames.get_frame_count(source):
		total += config.frames.get_frame_duration(source, i)
	return total / config.frames.get_animation_speed(source)

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
	action = _canonical(action)
	if not alive or not _has_clip(action): return
	if PRIORITY.get(action, 0) < PRIORITY.get(state, 0): return
	# Repeated hits cannot keep the hurt clip frozen on its first frame.
	if state == action and action == &"hurt": return
	state = action
	age = 0.0

func advance(delta: float) -> void:
	if action_driven: return
	age += maxf(delta, 0.0)
	if state in [&"melee", &"ranged", &"cast", &"hurt"] and age >= _duration(state):
		_rest()

func texture() -> Texture2D:
	if not _has_clip(state): return null
	var source: StringName = config.frame_clip(_canonical(state), attack_modes)
	if source == &"": return null
	var duration := _duration(state)
	var cursor := fmod(age, duration) if state in [&"idle", &"critical", &"move"] else minf(age, duration)
	for i in config.frames.get_frame_count(source):
		cursor -= config.frames.get_frame_duration(source, i) / config.frames.get_animation_speed(source)
		if cursor < 0 or i == config.frames.get_frame_count(source) - 1:
			return config.frames.get_frame_texture(source, i)
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
	var clip: StringName = &"cast" if action.casts else _canonical(StringName(action.get("mode", "attack")))
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
