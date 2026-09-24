extends HBoxContainer
const Codes = preload("res://game/combat/code_catalog.gd")
signal item_selected(index: int)
var selected := 0
func _ready() -> void:
	add_theme_constant_override("separation",3)
	for kind in Codes.RULES.types:
		var index := get_child_count()
		var button := Button.new()
		button.text = ["指","数","协","权"][index]
		button.custom_minimum_size = Vector2(21,23)
		button.add_theme_font_size_override("font_size",12)
		button.tooltip_text = Codes.RULES.types[kind].name
		button.pressed.connect(func(): select(index); item_selected.emit(index))
		add_child(button)
	select(selected)
func select(index: int) -> void:
	selected = index
	for i in range(get_child_count()):
		var style := StyleBoxFlat.new()
		var color: Color = Codes.RULES.types[Codes.RULES.types.keys()[i]].color
		style.bg_color = Color(color,0.65 if i == selected else 0.18)
		style.border_color = Color.WHITE if i == selected else color
		style.set_border_width_all(2 if i == selected else 1)
		style.set_corner_radius_all(3)
		for state in ["normal","hover","pressed","focus"]: get_child(i).add_theme_stylebox_override(state,style)
