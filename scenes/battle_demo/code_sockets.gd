extends Control
## Read-only code sockets shared by the HUD, recipes and item preview.
const Codes = preload("res://game/combat/code_catalog.gd")
const Glyph = preload("res://scenes/battle_demo/code_resource_glyph.gd")
var kind := "red"
var count := 0
var capacity := 6
var caption := ""

func _init() -> void:
	custom_minimum_size = Vector2(180, 76)
	size_flags_horizontal = SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_IGNORE

func configure(type: String, amount: int, slots: int, title: String = "") -> void:
	kind = type
	count = amount
	capacity = slots
	caption = title
	queue_redraw()

func _draw() -> void:
	var data: Dictionary = Codes.RULES.types[kind]
	var tint: Color = data.color
	var font := get_theme_font("font")
	draw_string(font, Vector2(2, 21), (data.name if caption.is_empty() else caption) + "  %d/%d" % [count, capacity], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, tint)
	var step := minf(36.0, (size.x - 4) / maxi(1, capacity))
	for i in range(capacity):
		var rect := Rect2(3 + i * step, 34, step - 5, 30)
		var filled := i < count
		draw_rect(rect, Color(tint, 0.22) if filled else Color("142334"))
		draw_rect(rect, tint if filled else Color("536071"), false, 1.5)
		if filled:
			Glyph.draw_icon(self, kind, rect.get_center(), tint, 8)
		else:
			draw_line(rect.position + Vector2(6,24), rect.end - Vector2(6,24), Color("536071"), 1)
