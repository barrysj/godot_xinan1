extends RichTextLabel
const Glossary = preload("res://game/content/glossary.gd")
var plain_copy := ""
var dark_ink := false
var pinned := false
var active_term := ""
var tooltip_layer: CanvasLayer
var tooltip_panel: PanelContainer

static func make(value: String, font_size: int = 20, dark: bool = false) -> RichTextLabel:
	var result = load("res://scenes/ui/glossary_text.gd").new()
	result.dark_ink = dark
	result.add_theme_font_size_override("normal_font_size",font_size)
	result.add_theme_color_override("default_color",Color("243943") if dark else Color("f1f7f5"))
	result.set_copy(value)
	return result

func _init() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in ["normal_font","bold_font","italics_font","bold_italics_font","mono_font"]:
		add_theme_font_override(key,preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
	meta_hover_started.connect(func(term): if not pinned: show_term(str(term)))
	meta_hover_ended.connect(func(_term): if not pinned: close_term())
	meta_clicked.connect(func(term): show_term(str(term),true))
	visibility_changed.connect(func(): if not is_visible_in_tree(): close_term())

func set_copy(value: String) -> void:
	if plain_copy == value and not text.is_empty(): return
	plain_copy = value
	text = Glossary.markup(value,dark_ink)
	close_term()

func show_term(term: String, pin := false) -> void:
	if not Glossary.TERMS.has(term): return
	close_term()
	active_term = term
	pinned = pin
	tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 120
	add_child(tooltip_layer)
	tooltip_panel = PanelContainer.new()
	tooltip_panel.add_to_group("glossary_popups")
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.theme = preload("res://resources/theme/theme-main.tres")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102635")
	style.border_color = Color(Glossary.TERMS[term][0])
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	tooltip_panel.add_theme_stylebox_override("panel",style)
	tooltip_layer.add_child(tooltip_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation",10)
	tooltip_panel.add_child(box)
	var heading := Label.new()
	heading.text = term
	heading.add_theme_color_override("font_color",Color(Glossary.TERMS[term][0]))
	heading.add_theme_font_size_override("font_size",24)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(heading)
	var explanation := Label.new()
	explanation.text = Glossary.TERMS[term][1]
	explanation.custom_minimum_size.x = minf(360,get_viewport_rect().size.x-64)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size",20)
	explanation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(explanation)
	var hint := Label.new()
	hint.text = "点击空白或 Esc 关闭" if pin else "点击术语可固定阅读"
	hint.add_theme_font_size_override("font_size",16)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	_position_tooltip.call_deferred()

func _position_tooltip() -> void:
	if not is_instance_valid(tooltip_panel): return
	tooltip_panel.reset_size()
	var bounds := get_global_transform_with_canvas()*Rect2(Vector2.ZERO,size)
	var at := Vector2(bounds.end.x+16,bounds.position.y)
	if at.x+tooltip_panel.size.x > get_viewport_rect().size.x-12:
		at = Vector2(bounds.position.x-tooltip_panel.size.x-16,bounds.position.y)
	if at.x < 12: at = Vector2(bounds.position.x,bounds.end.y+12)
	if at.y+tooltip_panel.size.y > get_viewport_rect().size.y-12:
		at.y = bounds.position.y-tooltip_panel.size.y-12
	tooltip_panel.position = at.clamp(Vector2(12,12),(get_viewport_rect().size-tooltip_panel.size-Vector2(12,12)).max(Vector2(12,12)))

func close_term() -> void:
	pinned = false
	active_term = ""
	if is_instance_valid(tooltip_layer):
		tooltip_layer.hide()
		tooltip_layer.queue_free()
	tooltip_layer = null
	tooltip_panel = null

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if pinned and (event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and not get_global_rect().has_point(event.position)) or (event is InputEventScreenTouch and event.pressed and not get_global_rect().has_point(event.position))):
		close_term()
		get_viewport().set_input_as_handled()
