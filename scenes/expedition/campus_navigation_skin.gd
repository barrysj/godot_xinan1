extends RefCounted
## Shared native cartographic frame; all colours come from the project tokens.
const Ui = preload("res://scenes/ui/campus_ui.gd")

static func layer(state: String) -> String:
	return "daily" if state == "day" else state

static func palette(state: String) -> Dictionary:
	return Ui.colors(layer(state))

static func accent(state: String) -> Color:
	var p := palette(state)
	return Color(p.accent_primary if state == "day" else p.cyan)

static func surface(state: String, margin: int = 18) -> StyleBoxFlat:
	var style := Ui.panel_style(layer(state), "quiet")
	style.bg_color = Color(palette(state).surface, .97)
	style.border_color = accent(state).lerp(style.bg_color, .55)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(margin)
	return style

static func panel(parent: Node, state: String, margin: int = 18) -> PanelContainer:
	var item := PanelContainer.new()
	item.set_meta("navigation_panel", margin)
	item.add_theme_stylebox_override("panel", surface(state, margin))
	parent.add_child(item)
	return item

static func label(parent: Node, value: String, pixels: int = 20, muted := false) -> Label:
	var item := Ui.label(value, pixels)
	item.set_meta("navigation_muted", muted)
	parent.add_child(item)
	return item

static func button(parent: Node, value: String, primary := false) -> Button:
	var item := Button.new()
	item.text = value
	item.custom_minimum_size = Vector2(72, 48 if not primary else 56)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_theme_font_size_override("font_size", 20)
	item.set_meta("navigation_primary", primary)
	parent.add_child(item)
	return item

static func style_button(item: Button, state: String) -> void:
	var p := palette(state)
	var ink := Color(p.text_primary)
	var colour := accent(state)
	var primary: bool = item.get_meta("navigation_primary", false)
	for mode in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := surface(state, 12)
		var selected := item.toggle_mode and item.button_pressed
		if primary:
			style.bg_color = colour
		elif selected or mode in ["hover", "pressed", "hover_pressed"]:
			style.bg_color = colour.lerp(Color(p.surface), .83 if state == "day" else .87)
		style.border_color = colour if selected or primary or mode != "normal" else colour.lerp(Color(p.surface), .70)
		if mode == "disabled":
			style.bg_color = Color(p.surface)
			style.border_color.a = .3
		if mode == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = ink
			style.set_border_width_all(3)
		else:
			style.set_border_width_all(2 if selected else 1)
		item.add_theme_stylebox_override(mode, style)
	var text_colour := Color(Ui.colors("daily").text_primary) if primary else ink
	for mode in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		item.add_theme_color_override(mode, text_colour)
	item.add_theme_color_override("font_disabled_color", ink * Color(1, 1, 1, .4))

static func apply(root: Node, state: String) -> void:
	if root is PanelContainer and root.has_meta("navigation_panel"):
		root.add_theme_stylebox_override("panel", surface(state, root.get_meta("navigation_panel")))
	if root is Button and root.has_meta("navigation_primary"):
		style_button(root, state)
	if root is Label and root.has_meta("navigation_muted"):
		var p := palette(state)
		var colour := Color(p.text_primary)
		if root.get_meta("navigation_muted"):
			colour = Color(p.text_secondary) if state == "day" else colour.lerp(Color(p.surface), .28)
		root.add_theme_color_override("font_color", colour)
	for child in root.get_children(): apply(child, state)

static func focus_loop(buttons: Array[Button]) -> void:
	for i in range(buttons.size()):
		buttons[i].focus_next = buttons[i].get_path_to(buttons[(i+1) % buttons.size()])
		buttons[i].focus_previous = buttons[i].get_path_to(buttons[(i-1+buttons.size()) % buttons.size()])
		buttons[i].focus_neighbor_bottom = buttons[i].focus_next
		buttons[i].focus_neighbor_top = buttons[i].focus_previous
		buttons[i].focus_neighbor_right = buttons[i].focus_next
		buttons[i].focus_neighbor_left = buttons[i].focus_previous

static func reveal(item: Control) -> void:
	if item.has_meta("navigation_tween"):
		var old: Tween = item.get_meta("navigation_tween")
		if old.is_valid(): old.kill()
	item.modulate.a = .55
	var tween := item.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	item.set_meta("navigation_tween", tween)
	var timing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/animation.json"))
	tween.tween_property(item, "modulate:a", 1.0, float(timing.durations_ms.normal) / 1000.0)
