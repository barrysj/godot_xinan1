extends Node
## Generic legacy-to-resource sampler. Settings describe a source scene and action durations.
## No character IDs, bone names or authored motion formulas belong in this tool.
const PROPERTIES := [&"position", &"rotation", &"scale", &"modulate", &"visible"]
var sampling_root: Node2D
var sampling_context: Dictionary

func evaluate(sample: Dictionary, time: float, hidden_value: Variant = null) -> Variant:
	sample.node.set(sample.property, sample.initial)
	sampling_context.age = time
	sampling_context.motion_time = time
	sampling_root.call("apply_presentation", sampling_context)
	if hidden_value != null and not sample.node.is_visible_in_tree(): return hidden_value
	return sample.node.get(sample.property)

func refine(sample: Dictionary, left: float, right: float, a: Variant, b: Variant,
		tolerance: float, keys: Dictionary, depth: int = 0) -> void:
	if right - left < 0.000001 or depth >= 24: return
	var midpoint := (left + right) * 0.5
	var value: Variant = evaluate(sample, midpoint, lerp(a, b, 0.5))
	var error := distance(value, lerp(a, b, 0.5))
	for fraction in [0.25, 0.75]:
		error = maxf(error, distance(evaluate(sample, lerpf(left, right, fraction), lerp(a, b, fraction)), lerp(a, b, fraction)))
	if error <= tolerance: return
	keys[midpoint] = value
	refine(sample, left, midpoint, a, value, tolerance, keys, depth + 1)
	refine(sample, midpoint, right, value, b, tolerance, keys, depth + 1)

func _ready() -> void:
	call_deferred("run")

func descendants(node: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for child in node.get_children():
		if child is Node2D: result.append(child)
		result.append_array(descendants(child))
	return result

func ownership(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		ownership(child, owner_root)

func distance(a: Variant, b: Variant) -> float:
	if a is Vector2: return a.distance_to(b)
	if a is Color: return maxf(maxf(absf(a.r-b.r), absf(a.g-b.g)), maxf(absf(a.b-b.b), absf(a.a-b.a)))
	return absf(float(a)-float(b))

func simplify(values: Array, first: int, last: int, tolerance: float, kept: Dictionary) -> void:
	if last - first <= 1: return
	var largest := tolerance
	var split := -1
	for index in range(first + 1, last):
		var fraction := float(index-first) / float(last-first)
		var predicted: Variant = lerp(values[first], values[last], fraction)
		var error := distance(values[index], predicted)
		if error > largest:
			largest = error
			split = index
	if split >= 0:
		kept[split] = true
		simplify(values, first, split, tolerance, kept)
		simplify(values, split, last, tolerance, kept)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Pass one JSON bake settings path")
		get_tree().quit(1)
		return
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	# Raw sampling is an intermediate only. Long cyclic motions must be split
	# into independent periods by compact_cycles before becoming runtime assets.
	if not str(settings.output).begins_with("res://.godot/"):
		push_error("Raw bake output must be below res://.godot; use compact_cycles for runtime assets")
		get_tree().quit(1)
		return
	for spec in settings.actions.values():
		if float(spec.length) > 8.0:
			push_error("Raw sample horizon exceeds 8 seconds; describe independent cycles instead")
			get_tree().quit(1)
			return
	var source: PackedScene = load(settings.source)
	var canvas := Vector2(settings.canvas[0], settings.canvas[1])
	var library := AnimationLibrary.new()
	var packed_root: Node2D
	for action in settings.actions:
		var spec: Dictionary = settings.actions[action]
		var node: Node2D = source.instantiate()
		add_child(node)
		var children := descendants(node)
		var samples: Array = []
		for child in children:
			for property in PROPERTIES: samples.append({"node": child, "property": property, "initial": child.get(property), "values": [], "active": []})
		var length: float = spec.length
		sampling_root = node
		sampling_context = {"state": StringName(spec.get("source_action", action)), "duration": length,
			"display_size": canvas, "facing_right": true}
		var count := int(round(length * settings.fps))
		for index in count + 1:
			var cursor: float = float(index) / settings.fps
			node.call("apply_presentation", {"state": StringName(spec.get("source_action", action)),
				"age": cursor, "duration": length, "motion_time": cursor,
				"display_size": canvas, "facing_right": true})
			for sample in samples:
				sample.values.append(sample.node.get(sample.property))
				sample.active.append(sample.node.is_visible_in_tree())
		var animation := Animation.new()
		animation.length = length
		animation.loop_mode = Animation.LOOP_LINEAR if spec.get("loop", false) else Animation.LOOP_NONE
		for sample in samples:
			var values: Array = sample.values
			var keys := {0: true, count: true}
			for index in range(1, values.size()):
				if sample.active[index] != sample.active[index-1]:
					keys[index-1] = true
					keys[index] = true
			var discrete: bool = values[0] is bool
			if discrete:
				for index in range(1, values.size()):
					if values[index] != values[index-1]: keys[index] = true
			else:
				var tolerance: float = 0.02 if sample.property == &"position" else 0.0005
				simplify(values, 0, count, tolerance, keys)
			var track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track, NodePath(str(node.get_path_to(sample.node)) + ":" + str(sample.property)))
			animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS)
			animation.track_set_interpolation_loop_wrap(track, false)
			var indices: Array = keys.keys()
			indices.sort()
			var precise: Dictionary = {}
			for index in indices:
				var time: float = float(index) / settings.fps
				if discrete and index > 0 and values[index] != values[index - 1]:
					var lower: float = float(index - 1) / settings.fps
					var upper := time
					while upper - lower > 0.000001:
						var middle := (lower + upper) * 0.5
						if evaluate(sample, middle) == values[index]: upper = middle
						else: lower = middle
					time = upper
				precise[time] = values[index]
			if not discrete:
				for index in range(indices.size() - 1):
					var left: float = float(indices[index]) / settings.fps
					var right: float = float(indices[index+1]) / settings.fps
					refine(sample, left, right, values[indices[index]], values[indices[index+1]],
						0.02 if sample.property == &"position" else 0.0005, precise)
			var times: Array = precise.keys()
			times.sort()
			# Import serialized key arrays directly: interactive insert/set-time APIs
			# merge approximately equal times and erase left limits at discontinuities.
			var packed_times := PackedFloat32Array()
			var transitions := PackedFloat32Array()
			var output_values: Array = []
			for time in times:
				# A tiny left bias preserves right-continuous changes after float32
				# serialization (e.g. a particle reborn exactly at a render frame).
				packed_times.append(maxf(0.0, time - 0.00001))
				transitions.append(1.0)
				output_values.append(precise[time])
			animation.set("tracks/%d/keys" % track, {"times": packed_times, "transitions": transitions,
				"update": Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS, "values": output_values})
		library.add_animation(StringName(action), animation)
		print("BAKE action=", action, " tracks=", animation.get_track_count())
		if packed_root != null: packed_root.free()
		packed_root = node
	var output: String = settings.output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	assert(ResourceSaver.save(library, output.path_join("animations.tres")) == OK)
	library.take_over_path(output.path_join("animations.tres"))
	packed_root.set_script(null)
	packed_root.name = "Presentation"
	packed_root.position = Vector2.ZERO
	packed_root.scale = Vector2.ONE
	packed_root.modulate = Color.WHITE
	packed_root.visible = false
	packed_root.set_script(load("res://scenes/battle_demo/presentations/hybrid_presentation.gd"))
	packed_root.set("canvas_size", canvas)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.add_animation_library(&"", library)
	packed_root.add_child(player)
	ownership(packed_root, packed_root)
	var scene := PackedScene.new()
	assert(scene.pack(packed_root) == OK)
	assert(ResourceSaver.save(scene, output.path_join("presentation.tscn")) == OK)
	packed_root.free()
	get_tree().quit()
