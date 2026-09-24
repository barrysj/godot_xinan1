extends Button
const Codes = preload("res://game/combat/code_catalog.gd")
const Glyph = preload("res://scenes/battle_demo/code_resource_glyph.gd")
var kind := "red"

func _ready() -> void:
	custom_minimum_size = Vector2(25, 25)
	tooltip_text = Codes.RULES.types[kind].name

func _draw() -> void:
	Glyph.draw_icon(self, kind, size / 2, Codes.RULES.types[kind].color, 8)
