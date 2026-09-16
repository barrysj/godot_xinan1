extends Node
## Compare two presentation resources at identical contexts, including all dynamic child properties.
const Baker = preload("res://tools/art/migration/bake_presentation.gd")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var sampler := Baker.new()
	var maxima := {"position": 0.0, "rotation": 0.0, "scale": 0.0, "modulate": 0.0}
	var visibility_errors := 0
	var boundary_samples := 0
	var limits: Dictionary = settings.get("tolerance", {"position":0.03,"rotation":0.001,"scale":0.002,"modulate":0.002})
	var worst: Dictionary = {}
	for action in settings.actions:
		var old: Node2D = load(settings.source).instantiate()
		var current: Node2D = load(settings.output.path_join("presentation.tscn")).instantiate()
		add_child(old)
		add_child(current)
		var children := sampler.descendants(old)
		var spec: Dictionary = settings.actions[action]
		var times: Array[float] = []
		for index in 289: times.append(float(index) / 144.0)
		if spec.get("loop", false):
			for index in 360: times.append(float(index) * 0.499)
			for time in [95.99,96.0,96.01,359.123,600.123]: times.append(time)
		for time in times:
			var context := {"state": StringName(spec.get("source_action", action)), "age": time,
				"duration": float(spec.length), "motion_time": time, "display_size": Vector2(settings.canvas[0], settings.canvas[1])}
			old.apply_presentation(context)
			context.state = StringName(action)
			current.apply_presentation(context)
			for child in children:
				if str(old.get_path_to(child)) in settings.get("ignore_nodes", []): continue
				var other := current.get_node(old.get_path_to(child))
				if child.is_visible_in_tree() != other.is_visible_in_tree(): visibility_errors += 1
				if not child.is_visible_in_tree(): continue
				for property in maxima:
					var actual_property: String = "global_" + property if settings.get("global_pose", false) and property in ["position", "rotation", "scale"] else property
					var error := sampler.distance(child.get(actual_property), other.get(actual_property))
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
							nearby = minf(nearby,sampler.distance(child.get(actual_property),other.get(actual_property)))
						var restore := context.duplicate()
						restore.state = StringName(spec.get("source_action",action))
						old.apply_presentation(restore)
						if nearby < limits[property]:
							boundary_samples += 1
							continue
					if error > maxima[property]:
						maxima[property] = error
						worst[property] = [action, time, str(old.get_path_to(child)), child.get(property), other.get(property)]
		old.free()
		current.free()
	sampler.free()
	print("PRESENTATION_COMPARISON max_errors=", maxima, " visibility_errors=", visibility_errors)
	print("WORST ", worst)
	print("BOUNDARY_SAMPLES ",boundary_samples," window_seconds=",settings.get("boundary_seconds",0.0))
	var passed: bool = visibility_errors == 0
	for property in maxima: passed = passed and maxima[property] < limits[property]
	print("PRESENTATION_COMPARISON ", "PASS" if passed else "FAIL")
	get_tree().quit(0 if passed else 1)
