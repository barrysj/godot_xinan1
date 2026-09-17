extends "res://design/concepts/m1-exploration-ui/m1_exploration_ui/008/preview.gd"

const PreviewHotspot = preload("res://design/concepts/m1-exploration-ui/m1_exploration_ui/011/hotspot.gd")

func _ready() -> void:
	super._ready()
	var sources := [
		"res://assets/art/ui/m1_exploration_ui/memory.png",
		"res://assets/art/ui/m1_exploration_ui/character.png",
		"res://assets/art/ui/m1_exploration_ui/terminal.png",
		"res://assets/art/ui/m1_exploration_ui/guardian.png",
	]
	popup.artwork = UISkin.texture("res://assets/art/ui/m1_exploration_ui/panel.png")
	var formal_button := UISkin.texture("res://assets/art/ui/m1_exploration_ui/button.png")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = formal_button
		box.set_content_margin_all(8)
		box.modulate_color = Color(0.65, 0.75, 0.8) if state == "pressed" else Color.WHITE
		primary.add_theme_stylebox_override(state, box)
	for i in range(buttons.size()):
		buttons[i].set_script(PreviewHotspot)
		buttons[i].kind = i
		buttons[i].artwork = UISkin.texture(sources[i])
		var no_focus_box := StyleBoxEmpty.new()
		buttons[i].add_theme_stylebox_override("focus", no_focus_box)
		buttons[i].queue_redraw()
		labels[i].add_theme_font_size_override("font_size", 18)
	_layout()

func _layout() -> void:
	super._layout()
	for i in range(buttons.size()):
		var center := buttons[i].position + buttons[i].size / 2.0
		buttons[i].size = Vector2(118, 118)
		buttons[i].position = center - buttons[i].size / 2.0
		labels[i].size = Vector2(150, 32)
		labels[i].position = center + Vector2(-75, 60)
	if selected >= 0 and popup.visible:
		popup.reset_size()
		var target := buttons[selected].position + Vector2(140, -60)
		if target.x + popup.size.x > size.x - 28:
			target.x = buttons[selected].position.x - popup.size.x - 34
		popup.position = target.clamp(Vector2(28, 28), size - popup.size - Vector2(28, 28))
	connector.queue_redraw()

func _snap(_output: String, dimensions: Vector2i, state: String) -> void:
	var output := "res://design/concepts/m1-exploration-ui/review/codex-workflow/preview-011"
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.get_size() == dimensions)
	assert(image.save_png(output + "/%s-%dx%d.png" % [state, dimensions.x, dimensions.y]) == OK)
	await get_tree().process_frame
