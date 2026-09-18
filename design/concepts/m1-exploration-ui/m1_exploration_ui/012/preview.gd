extends "res://design/concepts/m1-exploration-ui/m1_exploration_ui/011/preview.gd"

const CANDIDATE_ROOT := "res://design/concepts/m1-exploration-ui/m1_exploration_ui/012/"
const LIBRARY_BACKGROUND := "res://assets/art/backgrounds/m1_library/anomaly/atrium-down.png"

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is TextureRect:
			child.texture = UISkin.texture(LIBRARY_BACKGROUND)
			break
	popup.artwork = null
	popup.add_theme_stylebox_override("panel",_panel_box(UISkin.texture(CANDIDATE_ROOT + "panel.png")))
	var button_texture := UISkin.texture(CANDIDATE_ROOT + "button.png")
	primary.add_theme_stylebox_override("normal",_button_box(button_texture,Color.WHITE))
	primary.add_theme_stylebox_override("hover",_button_box(button_texture,Color(1.08,1.08,1.08)))
	primary.add_theme_stylebox_override("focus",_button_box(button_texture,Color(1.08,1.08,1.08)))
	primary.add_theme_stylebox_override("pressed",_button_box(button_texture,Color(0.68,0.78,0.82)))
	primary.add_theme_stylebox_override("disabled",_button_box(button_texture,Color(0.38,0.44,0.48,0.62)))
	for color_name in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
		primary.add_theme_color_override(color_name,Color("f7fbff"))
	primary.add_theme_color_override("font_disabled_color",Color("8493a0"))
	_layout()

func _panel_box(texture: Texture2D) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = 42
	box.texture_margin_right = 42
	box.texture_margin_top = 28
	box.texture_margin_bottom = 28
	box.set_content_margin_all(28)
	box.content_margin_top = 42
	box.content_margin_bottom = 42
	return box

func _button_box(texture: Texture2D, tint: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = 28
	box.texture_margin_right = 28
	box.texture_margin_top = 12
	box.texture_margin_bottom = 12
	box.set_content_margin_all(8)
	box.modulate_color = tint
	return box

func _snap(_output: String, dimensions: Vector2i, state: String) -> void:
	var output := "res://design/concepts/m1-exploration-ui/review/codex-workflow/preview-012"
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.get_size() == dimensions)
	assert(image.save_png(output + "/%s-%dx%d.png" % [state, dimensions.x, dimensions.y]) == OK)
	await get_tree().process_frame
