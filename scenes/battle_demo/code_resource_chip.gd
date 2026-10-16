extends Control
const Codes = preload("res://game/combat/code_catalog.gd")
const Glyph = preload("res://scenes/battle_demo/code_resource_glyph.gd")
const ANY_ART = preload("res://assets/art/ui/any_code/asset_001/any-code.png")
var kind := "red"
var amount := 1
var enough := false
var polarity := ""
var stock := -1

func _init() -> void:
	custom_minimum_size = Vector2(53, 20)
	mouse_filter = MOUSE_FILTER_IGNORE

func configure(type: String, cost: int, affordable: bool, direction: String = "") -> void:
	kind = type
	amount = cost
	enough = affordable
	polarity = direction
	tooltip_text = "%s ×%d" % [("任意代码" if kind == "any" else Codes.RULES.types[kind].name), amount]
	queue_redraw()

func _draw() -> void:
	var tint: Color = Color.WHITE if kind == "any" else Codes.RULES.types[kind].color
	if not enough: tint = Color(tint, 0.65)
	if not enough and stock >= 0:
		draw_rect(Rect2(0,0,53,20),Color("392a22"))
	var offset := 10.0 if not polarity.is_empty() else 0.0
	if not polarity.is_empty():
		draw_string(get_theme_font("font"), Vector2(0, 15), polarity, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tint)
	draw_rect(Rect2(1 + offset, 1, 21, 18), Color("122533"))
	draw_rect(Rect2(1 + offset, 1, 21, 18), tint, false, 1.1)
	if kind == "any": draw_texture_rect_region(ANY_ART,Rect2(2+offset,5,20,10),Rect2(20,340,1220,600),tint)
	else: Glyph.draw_icon(self, kind, Vector2(11.5 + offset, 10), tint, 7)
	draw_string(get_theme_font("font"), Vector2(27 + offset, 15), ("%d/%d" % [stock,amount] if not enough and stock >= 0 else "×%d" % amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffd0a1") if not enough and stock >= 0 else tint)
