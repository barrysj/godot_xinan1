extends "res://tools/art/archive/legacy-animation/bake_presentation.gd"
## Offline composition of independent periodic channels. Settings select source
## properties, periods and optional reference subtraction; no character formulas.

func evaluate(sample: Dictionary, time: float, _hidden_value: Variant = null) -> Variant:
	if sample.get("method", "") != "":
		sampling_root.call(sample.method, time)
	else:
		sampling_context.age = time
		sampling_context.motion_time = time
		sampling_root.call("apply_presentation", sampling_context)
	var value: Variant = sample.node.get_indexed(NodePath(sample.property))
	if sample.get("subtract_method", "") != "":
		sampling_root.call(sample.subtract_method, time)
		value -= sample.node.get_indexed(NodePath(sample.property))
	return value

func add_values(clip: Animation, path: NodePath, times: Array, values: Array, discrete: bool = false) -> void:
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, path)
	clip.track_set_interpolation_loop_wrap(track, false)
	var weights := PackedFloat32Array()
	weights.resize(times.size())
	weights.fill(1.0)
	clip.set("tracks/%d/keys" % track, {"times": PackedFloat32Array(times), "transitions": weights,
		"update": Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS, "values": values})

func run() -> void:
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var source: PackedScene = load(settings.source)
	var legacy: AnimationLibrary = load(settings.library)
	var library := AnimationLibrary.new()
	var reset := Animation.new()
	reset.length = 0.001
	var reference := source.instantiate()
	add_child(reference)
	var defaults := {}
	var layers := {}
	for state in settings.actions:
		var previous: Animation = legacy.get_animation(state)
		var clip := Animation.new()
		var cycles: Array = settings.actions[state]
		clip.length = previous.length if cycles.is_empty() else float(settings.lengths[state])
		clip.set_meta(&"constant_pose", not cycles.is_empty())
		var replaced := {}
		for cycle in cycles:
			for spec in cycle.tracks:
				var path: String = spec.get("target", spec.path)
				replaced[path.split(":")[0] + ":" + path.split(":")[1]] = true
		for track in previous.get_track_count():
			var path := previous.track_get_path(track)
			var node := reference.get_node(NodePath(path.get_concatenated_names()))
			var initial: Variant = node.get_indexed(NodePath(path.get_concatenated_subnames()))
			initial = defaults.get(str(path), initial)
			if not defaults.has(str(path)):
				defaults[str(path)] = initial
				add_values(reset, path, [0.0], [initial], initial is bool)
			if replaced.has(str(path)): continue
			var constant := true
			var first: Variant = previous.track_get_key_value(track, 0)
			for index in previous.track_get_key_count(track):
				if distance(first, previous.track_get_key_value(track,index)) > 0.000001: constant = false
			if not cycles.is_empty() or constant:
				if distance(initial, first) > 0.000001: add_values(clip,path,[0.0],[first],first is bool)
			else:
				if first is bool:
					previous.copy_track(track, clip)
				else:
					var times: Array = []
					var values: Array = []
					for index in previous.track_get_key_count(track):
						times.append(previous.track_get_key_time(track,index))
						values.append(previous.track_get_key_value(track,index))
					var kept := {0:true,times.size()-1:true}
					reduce(times,values,0,times.size()-1,tolerance_for(path),kept)
					var indices: Array = kept.keys()
					indices.sort()
					var output_times: Array = []
					var output_values: Array = []
					for index in indices:
						output_times.append(times[index])
						output_values.append(values[index])
					add_values(clip,path,output_times,output_values)
		library.add_animation(state, clip)
		layers[state] = []
		for number in cycles.size():
			var cycle: Dictionary = cycles[number]
			var curve := Animation.new()
			curve.length = cycle.period
			curve.set_meta(&"period", float(cycle.period))
			curve.loop_mode = Animation.LOOP_LINEAR
			var name := "_cycle_%s_%02d" % [state, number]
			layers[state].append(name)
			for spec in cycle.tracks:
				var path := NodePath(spec.path)
				var sample := {"node": reference.get_node(NodePath(path.get_concatenated_names())),
					"property": path.get_concatenated_subnames(), "method": spec.get("method", ""),
					"subtract_method": spec.get("subtract_method", "")}
				sampling_root = reference
				sampling_context = {"state": StringName(state), "duration": cycle.period, "display_size":Vector2(settings.canvas[0],settings.canvas[1])}
				var count := int(ceil(cycle.period * 120.0))
				var keys := {}
				var tolerance := tolerance_for(path)
				for index in count:
					var left: float = cycle.period * index / count
					var right: float = cycle.period * (index+1) / count
					var a: Variant = evaluate(sample,left)
					var b: Variant = evaluate(sample,right)
					keys[left] = a
					keys[right] = b
					refine(sample,left,right,a,b,tolerance,keys)
				var times: Array = keys.keys()
				times.sort()
				var values: Array = []
				for time in times: values.append(keys[time])
				# Simplify using actual, possibly adaptive, timestamps.
				var kept := {0:true, times.size()-1:true}
				reduce(times,values,0,times.size()-1,tolerance,kept)
				var indices: Array = kept.keys()
				indices.sort()
				var final_times: Array = []
				var final_values: Array = []
				for index in indices:
					final_times.append(maxf(0, times[index]-0.000001))
					final_values.append(values[index])
				add_values(curve,NodePath(spec.get("target",spec.path)),final_times,final_values)
			library.add_animation(name,curve)
	# Offsets used only by periodic layers must be reset before one-shot actions.
	for path in settings.get("reset", {}): add_values(reset,NodePath(path),[0.0],[settings.reset[path]])
	var animated := {}
	for name in library.get_animation_list():
		var clip := library.get_animation(name)
		for track in clip.get_track_count():
			var path := clip.track_get_path(track)
			animated[str(path.get_concatenated_names()) + ":" + str(path.get_subname(0))] = true
	for track in range(reset.get_track_count()-1,-1,-1):
		var path := reset.track_get_path(track)
		if not animated.has(str(path.get_concatenated_names())+":"+str(path.get_subname(0))): reset.remove_track(track)
	library.add_animation(&"RESET",reset)
	library.set_meta(&"cycle_layers",layers)
	var total := 0
	for name in library.get_animation_list():
		var clip := library.get_animation(name)
		for track in clip.get_track_count(): total += clip.track_get_key_count(track)
	print("COMPACT_CYCLES keys=",total)
	assert(total <= int(settings.get("max_keys",6000)), "Animation key budget exceeded")
	assert(ResourceSaver.save(library,settings.output) == OK)
	assert(FileAccess.get_file_as_bytes(settings.output).size() <= int(settings.get("max_bytes",524288)), "Animation byte budget exceeded")
	if settings.has("scene_input"):
		library.take_over_path(settings.output)
		var scene_root: Node2D = load(settings.scene_input).instantiate()
		for path in defaults:
			var property := NodePath(path)
			scene_root.get_node(NodePath(property.get_concatenated_names())).set_indexed(NodePath(property.get_concatenated_subnames()),defaults[path])
		var player: AnimationPlayer = scene_root.get_node("AnimationPlayer")
		player.remove_animation_library(&"")
		player.add_animation_library(&"",library)
		var packed := PackedScene.new()
		assert(packed.pack(scene_root) == OK)
		assert(ResourceSaver.save(packed,settings.scene_output) == OK)
		scene_root.free()
	reference.free()
	get_tree().quit()

func reduce(times: Array, values: Array, left: int, right: int, tolerance: float, kept: Dictionary) -> void:
	var largest := tolerance
	var split := -1
	for index in range(left+1,right):
		var weight: float = (times[index]-times[left])/(times[right]-times[left])
		var error := distance(values[index],lerp(values[left],values[right],weight))
		if error > largest:
			largest = error
			split = index
	if split >= 0:
		kept[split] = true
		reduce(times,values,left,split,tolerance,kept)
		reduce(times,values,split,right,tolerance,kept)

func tolerance_for(path: NodePath) -> float:
	if "position" in str(path): return 0.05
	if "rotation" in str(path): return 0.0005
	return 0.001
