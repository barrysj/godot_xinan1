extends "res://design/concepts/m1-exploration-ui/m1_exploration_ui/005/preview.gd"
const UISkin = preload("res://design/concepts/m1-exploration-ui/m1_exploration_ui/008/skin.gd")

func _ready() -> void:
	super._ready()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var sources = ["006/memory.png","007/character.png","006/terminal.png","007/guardian.png"]
	for i in range(4):
		buttons[i].set_script(preload("res://design/concepts/m1-exploration-ui/m1_exploration_ui/008/hotspot.gd"))
		buttons[i].kind = i
		buttons[i].artwork = UISkin.texture("res://design/concepts/m1-exploration-ui/m1_exploration_ui/"+sources[i])
		buttons[i].queue_redraw()
	popup.set_script(preload("res://design/concepts/m1-exploration-ui/m1_exploration_ui/008/panel.gd"))
	popup.artwork = UISkin.texture("res://design/concepts/m1-exploration-ui/m1_exploration_ui/006/panel.png")
	var margins := StyleBoxEmpty.new()
	margins.set_content_margin_all(28)
	margins.content_margin_top = 44
	margins.content_margin_bottom = 48
	popup.add_theme_stylebox_override("panel",margins)
	var button_texture := UISkin.texture("res://design/concepts/m1-exploration-ui/m1_exploration_ui/006/button.png")
	for state in ["normal","hover","pressed","disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = button_texture
		box.set_content_margin_all(8)
		box.modulate_color = Color(0.65,0.75,0.8) if state=="pressed" else Color.WHITE
		primary.add_theme_stylebox_override(state,box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("d0faff")
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(5)
	primary.add_theme_stylebox_override("focus",focus)
	_layout()

func open_detail(index: int) -> void:
	super.open_detail(index)
	primary.text = ["查看","交流","读取","挑战"][index]

func _snap(_output: String, dimensions: Vector2i, state: String) -> void:
	var output := "res://design/concepts/m1-exploration-ui/review/codex-workflow/preview-008"
	DirAccess.make_dir_recursive_absolute(output)
	await super._snap(output,dimensions,state)
