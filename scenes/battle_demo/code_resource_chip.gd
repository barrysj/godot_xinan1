extends Control
const Codes = preload("res://game/combat/code_catalog.gd")
const Glyph = preload("res://scenes/battle_demo/code_resource_glyph.gd")
var kind := "red"
var amount := 1
var enough := false
var polarity := ""

func _init() -> void:
	custom_minimum_size = Vector2(53, 20)
	mouse_filter = MOUSE_FILTER_IGNORE

func configure(type: String, cost: int, affordable: bool, direction: String = "") -> void:
	kind = type
	amount = cost
	enough = affordable
	polarity = direction
	tooltip_text = "%s ×%d" % [Codes.RULES.types[kind].name, amount]
	queue_redraw()

func _draw() -> void:
	var tint: Color = Codes.RULES.types[kind].color
	if not enough: tint = Color(tint, 0.44)
	var offset := 10.0 if not polarity.is_empty() else 0.0
	if not polarity.is_empty():
		draw_string(get_theme_font("font"), Vector2(0, 15), polarity, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint)
	draw_rect(Rect2(1 + offset, 1, 21, 18), Color("122533"))
	draw_rect(Rect2(1 + offset, 1, 21, 18), tint, false, 1.1)
	Glyph.draw_icon(self, kind, Vector2(11.5 + offset, 10), tint, 7)
	draw_string(get_theme_font("font"), Vector2(27 + offset, 15), "×%d" % amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint)
