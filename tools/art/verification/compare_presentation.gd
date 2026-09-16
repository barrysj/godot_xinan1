extends Node
## Compare two presentation resources at identical contexts, including all dynamic child properties.
const Pose = preload("res://tools/art/verification/presentation_math.gd")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Pass one JSON comparison settings path")
		get_tree().quit(1)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not parsed is Dictionary or not parsed.has_all(["source", "target", "canvas", "actions"]) or parsed.actions.is_empty():
		push_error("Comparison requires source/target scenes, canvas and nonempty actions")
		get_tree().quit(1)
		return
	var settings: Dictionary = parsed
	var source: PackedScene = load(settings.source)
	var target: PackedScene = load(settings.target)
	if source == null or target == null:
		get_tree().quit(1)
		return
	var maxima := {"position": 0.0, "rotation": 0.0, "scale": 0.0, "modulate": 0.0}
	var visibility_errors := 0
	var boundary_samples := 0
	var limits: Dictionary = settings.get("tolerance", {"position":0.03,"rotation":0.001,"scale":0.002,"modulate":0.002})
	var worst: Dictionary = {}
	for action in settings.actions:
		var old: Node2D = source.instantiate()
		var current: Node2D = target.instantiate()
		add_child(old)
		add_child(current)
		if not old.has_method("apply_presentation") or not current.has_method("apply_presentation"):
			push_error("Both scenes must implement apply_presentation(context)")
			get_tree().quit(1)
			return
		var children := Pose.descendants(old)
		children.push_front(old)
		var spec: Dictionary = settings.actions[action]
		var times: Array[float] = []
		var duration := float(spec.get("length", 0.0))
		var end := float(spec.get("sample_end", duration))
		var fps := float(settings.get("fps", 144.0))
		if duration <= 0.0 or end <= 0.0 or fps <= 0.0:
			push_error("Action length, sample_end and fps must be positive")
			get_tree().quit(1)
			return
		for index in int(ceil(end * fps)) + 1: times.append(minf(float(index) / fps, end))
		for time in spec.get("times", []): times.append(float(time))
		for time in times:
			var context := {"state": StringName(spec.get("source_action", action)), "age": time,
				"duration": float(spec.length), "motion_time": time, "display_size": Vector2(settings.canvas[0], settings.canvas[1]), "facing_right": bool(settings.get("facing_right", true))}
			old.apply_presentation(context)
			context.state = StringName(action)
			current.apply_presentation(context)
			for child in children:
				if str(old.get_path_to(child)) in settings.get("ignore_nodes", []): continue
				var other := current.get_node_or_null(old.get_path_to(child)) as Node2D
				if other == null:
					push_error("Missing comparison node: " + str(old.get_path_to(child)))
					get_tree().quit(1)
					return
				if child.is_visible_in_tree() != other.is_visible_in_tree(): visibility_errors += 1
				if not child.is_visible_in_tree(): continue
				for property in maxima:
					var actual_property: String = "global_" + property if settings.get("global_pose", false) and property in ["position", "rotation", "scale"] else property
					var error := Pose.distance(child.get(actual_property), other.get(actual_property))
					# Discontinuous particle rebirth has two valid one-sided limits.
					# Only accept a large difference if the legacy pose matches within
					# the explicit sub-frame temporal tolerance, never widen spatial limits.
					if error >= limits[property] and settings.get("boundary_seconds", 0.0) > 0:
						var nearby := error
						for direction in [-1.0,1.0]:
							var probe := context.duplicate()
							probe.state = StringName(spec.get("source_action",action))
							probe.age = time + direction * settings.boundary_seconds
							probe.motion_time = probe.age
							old.apply_presentation(probe)
							nearby = minf(nearby,Pose.distance(child.get(actual_property),other.get(actual_property)))
						var restore := context.duplicate()
						restore.state = StringName(spec.get("source_action",action))
						old.apply_presentation(restore)
						if nearby < limits[property]:
							boundary_samples += 1
							continue
					if error > maxima[property]:
						maxima[property] = error
						worst[property] = [action, time, str(old.get_path_to(child)), child.get(actual_property), other.get(actual_property)]
		old.free()
		current.free()
	print("PRESENTATION_COMPARISON max_errors=", maxima, " visibility_errors=", visibility_errors)
	print("WORST ", worst)
	print("BOUNDARY_SAMPLES ",boundary_samples," window_seconds=",settings.get("boundary_seconds",0.0))
	var passed: bool = visibility_errors == 0
	for property in maxima: passed = passed and maxima[property] < limits[property]
	print("PRESENTATION_COMPARISON ", "PASS" if passed else "FAIL")
	get_tree().quit(0 if passed else 1)
