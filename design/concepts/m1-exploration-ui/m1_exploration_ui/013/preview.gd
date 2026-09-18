extends "res://design/concepts/m1-exploration-ui/m1_exploration_ui/012/preview.gd"

const STRIP_CANDIDATE_ROOT := "res://design/concepts/m1-exploration-ui/m1_exploration_ui/013/"
const STRIP_SIZE := Vector2(168, 34)

var interaction_strips: Array[TextureRect] = []

func _ready() -> void:
	super._ready()
	var strip_texture := UISkin.texture(STRIP_CANDIDATE_ROOT + "interaction-strip.png")
	for i in range(buttons.size()):
		var strip := TextureRect.new()
		strip.texture = strip_texture
		strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		strip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.modulate = Color(0.72, 0.82, 0.90, 0.78)
		add_child(strip)
		move_child(strip, labels[i].get_index())
		interaction_strips.append(strip)
		labels[i].add_theme_font_size_override("font_size", 15)
		labels[i].add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		labels[i].add_theme_color_override("font_outline_color", Color("03101b"))
		labels[i].add_theme_constant_override("outline_size", 4)
		buttons[i].mouse_entered.connect(_refresh_hint.bind(i))
		buttons[i].mouse_exited.connect(_refresh_hint.bind(i))
		buttons[i].focus_entered.connect(_refresh_hint.bind(i))
		buttons[i].focus_exited.connect(_refresh_hint.bind(i))
	_layout()
	_refresh_hints()

func _layout() -> void:
	super._layout()
	for i in range(mini(interaction_strips.size(), buttons.size())):
		var center := buttons[i].position + buttons[i].size / 2.0
		interaction_strips[i].size = STRIP_SIZE
		interaction_strips[i].position = center + Vector2(-STRIP_SIZE.x / 2.0, 56)
		labels[i].size = Vector2(150, 28)
		labels[i].position = center + Vector2(-75, 57)

func _refresh_hint(_index: int = -1) -> void:
	_refresh_hints.call_deferred()

func _refresh_hints() -> void:
	for i in range(buttons.size()):
		var active := (buttons[i].has_focus() or buttons[i].is_hovered()) and not popup.visible
		labels[i].visible = active
		if i < interaction_strips.size():
			var completed: bool = buttons[i].completed
			interaction_strips[i].modulate = Color(0.50, 0.78, 0.62, 0.58) if completed else (Color(1.08, 1.08, 1.08, 0.96) if active else Color(0.58, 0.70, 0.82, 0.64))

func _snap(_output: String, dimensions: Vector2i, state: String) -> void:
	var output := "res://design/concepts/m1-exploration-ui/review/codex-workflow/preview-013"
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.get_size() == dimensions)
	assert(image.save_png(output + "/%s-%dx%d.png" % [state, dimensions.x, dimensions.y]) == OK)
	await get_tree().process_frame
