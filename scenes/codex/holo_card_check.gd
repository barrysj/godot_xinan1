extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var guide = load("res://scenes/codex/codex_panel.gd").new()
	add_child(guide)
	guide.tabs[5].pressed.emit()
	var page = guide.holo_page
	assert(page.grid.get_child_count() > 0)
	for dimensions in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		DisplayServer.window_set_size(dimensions)
		await get_tree().process_frame
		await get_tree().create_timer(0.2).timeout
		page.grid.get_child(0).pressed.emit()
		assert(is_instance_valid(page.active_card))
		page.active_card.set_tilt(Vector2(0.35,-0.25),true)
		for i in range(5): await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/holo-detail-%dx%d.png" % [dimensions.x,dimensions.y])
		var escape = InputEventAction.new()
		escape.action = "pause"
		escape.pressed = true
		Input.parse_input_event(escape)
		await get_tree().process_frame
		assert(is_instance_valid(guide) and not is_instance_valid(page.active_card))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/holo-list.png")
	guide.select_category(0)
	assert(not guide.heading.text.is_empty())
	print("HOLO_CODEX_CHECK PASS")
	get_tree().quit()
