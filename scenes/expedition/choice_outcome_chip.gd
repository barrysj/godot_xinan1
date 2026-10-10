extends PanelContainer
## Compact, non-interactive consequence label with a native vector symbol.
const ChoiceSkin = preload("res://scenes/expedition/choice_skin.gd")
var kind := "unknown"
var symbol: Control
var pulse: Tween
var preferred_width := 0.0

func _ready() -> void:
	get_parent().resized.connect(_fit_width)
	_fit_width()

func _fit_width() -> void:
	# Long consequences wrap inside their card instead of widening the sheet.
	custom_minimum_size.x = minf(preferred_width,maxf(36,get_parent().size.x))

class OutcomeSymbol extends Control:
	var kind := "unknown"
	var ink := Color.WHITE
	func _draw() -> void:
		match kind:
			"gain","loss":
				var flip := -1.0 if kind == "loss" else 1.0
				draw_line(Vector2(8,8+5*flip),Vector2(8,8-5*flip),ink,1.8,true)
				draw_polyline(PackedVector2Array([Vector2(3,8),Vector2(8,8-5*flip),Vector2(13,8)]),ink,1.8,true)
			"item":
				draw_rect(Rect2(3,6,10,8),ink,false,1.5)
				draw_polyline(PackedVector2Array([Vector2(5,6),Vector2(5,3),Vector2(11,3),Vector2(11,6)]),ink,1.5,true)
			"resource","cost":
				draw_arc(Vector2(8,8),6,0,TAU,24,ink,1.5,true)
				draw_line(Vector2(4,8),Vector2(12,8),ink,1.5,true)
				if kind == "resource": draw_line(Vector2(8,4),Vector2(8,12),ink,1.5,true)
			"story":
				draw_rect(Rect2(3,2,10,12),ink,false,1.5)
				for y in [5,8,11]: draw_line(Vector2(5,y),Vector2(11,y),ink,1.3,true)
			"build":
				draw_polyline(PackedVector2Array([Vector2(3,12),Vector2(8,7),Vector2(12,3)]),ink,1.5,true)
				draw_line(Vector2(8,7),Vector2(12,12),ink,1.5,true)
				for point in [Vector2(3,12),Vector2(12,3),Vector2(12,12)]: draw_circle(point,2,ink)
			"recruit":
				draw_circle(Vector2(8,5),3,ink,false,1.5,true)
				draw_arc(Vector2(8,14),5,PI,TAU,16,ink,1.5,true)
			"route":
				draw_line(Vector2(2,8),Vector2(13,8),ink,1.8,true)
				draw_polyline(PackedVector2Array([Vector2(9,3),Vector2(14,8),Vector2(9,13)]),ink,1.8,true)
			_:
				draw_circle(Vector2(8,5),3,ink,false,1.5,true)
				draw_line(Vector2(8,8),Vector2(8,10),ink,1.5,true)
				draw_circle(Vector2(8,13),1,ink)

func setup(result: Dictionary) -> void:
	kind = result.kind
	name = "Outcome_"+kind
	set_meta("outcome_kind",kind)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ChoiceSkin.outcome_color(kind)
	var style := StyleBoxFlat.new()
	style.bg_color = ink.lerp(Color.WHITE,0.92)
	style.border_color = ink.lerp(Color.WHITE,0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	add_theme_stylebox_override("panel",style)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",5)
	add_child(row)
	symbol = OutcomeSymbol.new()
	symbol.kind = kind
	symbol.ink = ink
	symbol.custom_minimum_size = Vector2(16,16)
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(symbol)
	var caption := Label.new()
	caption.text = ChoiceSkin.OUTCOME_NAMES[kind]+(" · "+result.text if not result.text.is_empty() else "")
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ChoiceSkin.type_label(caption,"outcome")
	caption.add_theme_color_override("font_color",ink)
	preferred_width = ceilf(caption.get_theme_font("font").get_string_size(caption.text,HORIZONTAL_ALIGNMENT_LEFT,-1,caption.get_theme_font_size("font_size")).x)+35
	row.add_child(caption)

func emphasize() -> void:
	if not is_visible_in_tree(): return
	if pulse != null: pulse.kill()
	symbol.pivot_offset = symbol.size*0.5
	symbol.scale = Vector2.ONE*1.15
	pulse = create_tween()
	pulse.tween_property(symbol,"scale",Vector2.ONE,ChoiceSkin.duration("normal")).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
