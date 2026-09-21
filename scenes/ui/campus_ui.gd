extends RefCounted
class_name CampusUi
## Shared style helpers for the M1 player-facing UI.

const COLORS_PATH := "res://data/visual/colors.json"

static var _colors: Dictionary = {}

## Base-only material: native geometry, shared palette, no raster text or gloss.
static func hub_surface(state: String = "normal", primary: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var accent := Color(colors("daily").accent_primary)
	style.bg_color = Color(colors("night").surface,0.90)
	style.border_color = Color(colors("daily").text_secondary,0.85)
	if primary:
		style.bg_color = accent
		style.border_color = accent
	if state == "hover":
		style.bg_color = style.bg_color.lightened(0.10)
		style.border_color = accent
	elif state == "pressed":
		style.bg_color = style.bg_color.darkened(0.12)
	elif state == "disabled":
		style.bg_color = Color(colors("night").surface,0.65)
		style.border_color.a = 0.3
	elif state == "focus":
		style.bg_color = Color.TRANSPARENT
		style.border_color = Color(colors("night").text_primary) if primary else accent
	style.set_border_width_all(2 if state == "focus" else 1)
	style.set_corner_radius_all(10)
	style.corner_detail = 1
	style.set_content_margin_all(18)
	return style

static func apply_hub_button(item: Button, primary: bool = false) -> void:
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := hub_surface(state,primary)
		style.set_content_margin_all(12)
		item.add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		item.add_theme_color_override(state,Color(colors("daily").text_primary if primary else colors("night").text_primary))
	item.add_theme_color_override("font_disabled_color",Color(colors("night").text_primary,0.4))

static func colors(layer: String = "daily") -> Dictionary:
	if _colors.is_empty():
		_colors = JSON.parse_string(FileAccess.get_file_as_string(COLORS_PATH))
	return _colors.get(layer, _colors.daily)

static func panel_style(layer: String = "daily", emphasis: String = "normal") -> StyleBoxFlat:
	var palette := colors(layer)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(palette.surface)
	style.border_color = Color(palette.accent_primary if layer == "daily" else palette.cyan)
	style.set_border_width_all(1 if emphasis == "quiet" else 2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	if emphasis == "quiet":
		style.bg_color = Color(palette.surface_blue if layer == "daily" else palette.background, 0.94)
	elif emphasis == "strong":
		style.border_color = Color(palette.highlight)
	return style

static func button_style(layer: String, state: String, semantic: String = "primary") -> StyleBoxFlat:
	var palette := colors(layer)
	var style := StyleBoxFlat.new()
	var accent := Color(palette.accent_primary if layer == "daily" else palette.cyan)
	var surface := Color(palette.surface)
	if semantic == "reward": accent = Color(palette.highlight)
	elif semantic == "danger": accent = Color(colors("anomaly").error)
	if state in ["hover", "pressed"]:
		style.bg_color = accent.darkened(0.16) if layer != "daily" else Color(palette.surface_blue)
	else:
		style.bg_color = surface
	style.border_color = Color(palette.highlight) if state == "focus" else accent
	style.set_border_width_all(3 if state == "focus" else 2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	if state == "disabled":
		style.bg_color = surface.darkened(0.04)
		style.border_color = Color(palette.text_secondary if layer == "daily" else palette.text_primary, 0.35)
	return style

static func apply_button(button: Button, layer: String = "daily", semantic: String = "primary") -> void:
	var palette := colors(layer)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, button_style(layer, state, semantic))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color(palette.text_primary))
	button.add_theme_color_override("font_disabled_color", Color(palette.text_secondary if layer == "daily" else palette.text_primary, 0.48))

static func apply_panel(panel: Control, layer: String = "daily", emphasis: String = "normal") -> void:
	panel.add_theme_stylebox_override("panel", panel_style(layer, emphasis))

static func label(value: String, font_size: int, layer: String = "daily", muted := false) -> Label:
	var item := Label.new()
	var palette := colors(layer)
	item.text = value
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", Color(palette.text_secondary if muted else palette.text_primary))
	return item
