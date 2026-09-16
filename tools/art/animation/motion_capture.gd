extends RefCounted
## One fixed-step capture session. Only this explicit entry writes raster frames.

static func run(preview: Node, manifest_path: String) -> void:
	preview.set_process(false)
	preview.repeat = false
	var absolute := ProjectSettings.globalize_path(manifest_path).simplify_path()
	var allowed := ProjectSettings.globalize_path("res://.godot/motion-capture/").simplify_path()
	if not absolute.begins_with(allowed.trim_suffix("/") + "/"):
		push_error("Capture manifest must be below .godot/motion-capture")
		preview.get_tree().quit(1)
		return
	var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(absolute))
	var directory := absolute.get_base_dir()
	if ProjectSettings.globalize_path("res://" + job.cache).simplify_path() != directory:
		push_error("Capture cache does not match manifest")
		preview.get_tree().quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(job.size[0]), int(job.size[1]))
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	preview.add_child(viewport)
	var rig: Node2D
	if preview.preview_presentation_scene != null:
		rig = preview.preview_presentation_scene.instantiate()
		viewport.add_child(rig)
	var fallback := Node2D.new()
	viewport.add_child(fallback)
	var sprite := Sprite2D.new()
	sprite.centered = false
	fallback.add_child(sprite)
	var actions: Array = []
	for action in preview.ACTION_MODES:
		if preview._mode_enabled(preview.ACTION_MODES[action]): actions.append(action)
	job.supported_actions = actions.duplicate()
	if not job.requested_action.is_empty():
		if job.requested_action not in actions:
			push_error("Requested action is unsupported")
			preview.get_tree().quit(1)
			return
		actions = [job.requested_action]
	job.captures = []
	var frame_root := directory.path_join("frames")
	DirAccess.make_dir_recursive_absolute(frame_root)
	for action in actions:
		var record := {"action": action, "source_clip": action, "fps": job.fps,
			"loop": action != "death", "before": "idle", "after": "death" if action == "death" else "idle",
			"frames": [], "backends": [], "events": []}
		preview.mode = preview.Mode.IDLE
		preview._reset_preview()
		var count := int(job.fps * 3)
		for index in count:
			if index == int(job.fps * 0.4):
				preview.mode = preview.ACTION_MODES[action]
				preview._reset_preview()
			if index == int(job.fps * 2.2) and action in ["move", "critical"]:
				preview.mode = preview.Mode.IDLE
				preview._reset_preview()
			preview.advance_preview(1.0 / float(job.fps))
			var actor: Dictionary = preview.units[0]
			var context: Dictionary = preview._presentation_context(actor, Vector2.ZERO, 4.0)
			context.center = Vector2(job.size[0] * 0.5, job.size[1] * 0.85)
			context.display_size = Vector2.ONE * 256.0
			var handled := rig != null and bool(rig.call("handles_presentation_state", context.state))
			if rig != null: rig.call("apply_presentation", context)
			fallback.visible = not handled
			var backend := "skeleton" if handled else "sprite_frames"
			if backend not in record.backends: record.backends.append(backend)
			if context.state in [&"melee", &"ranged", &"attack"]:
				var source_clip: StringName = actor.battle_animation.frame_clip(context.state, actor.get("attack_modes", 1))
				record.source_clip = str(source_clip) if source_clip != &"" else action
			if not handled:
				sprite.texture = actor.animation.texture()
				if sprite.texture != null:
					sprite.position = -context.display_size * actor.battle_animation.anchor
					sprite.scale = context.display_size / sprite.texture.get_size()
				fallback.position = context.center
				fallback.scale.x = 1.0 if context.facing_right or not actor.battle_animation.flip_with_facing else -1.0
				fallback.modulate = context.tint
			await RenderingServer.frame_post_draw
			var relative := "frames/%s-%04d.png" % [action, index]
			var error := viewport.get_texture().get_image().save_png(directory.path_join(relative))
			if error != OK:
				push_error("Unable to save capture frame")
				preview.get_tree().quit(1)
				return
			record.frames.append(relative)
			record.events = preview.history.duplicate(true)
		record.duration = float(count) / float(job.fps)
		job.captures.append(record)
		print("MOTION_CAPTURE action=", action, " frames=", count)
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	file.store_string(JSON.stringify(job, "\t"))
	file.close()
	viewport.queue_free()
	preview.get_tree().quit()
