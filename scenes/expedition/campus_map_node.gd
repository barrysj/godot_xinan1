extends Button
## A location thumbnail, focus ring and short name attached to the campus itself.
const NavSkin = preload("res://scenes/expedition/campus_navigation_skin.gd")
var thumbnail: Texture2D
var number := ""
var state := "day"
var name_label: Label
var badge: Label
var photo: TextureRect

func _ready() -> void:
	custom_minimum_size = Vector2(180, 136)
	size = custom_minimum_size
	toggle_mode = true
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	tooltip_text = text
	for mode in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(mode, StyleBoxEmpty.new())
	for mode in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		add_theme_color_override(mode, Color.TRANSPARENT)
	photo = TextureRect.new()
	photo.position = Vector2(52, 12)
	photo.size = Vector2(76, 76)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_SCALE
	photo.mouse_filter = MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://scenes/expedition/campus_node_crop.gdshader")
	photo.material = material
	add_child(photo)
	set_thumbnail(thumbnail)
	name_label = Label.new()
	name_label.text = text
	name_label.position = Vector2(0, 100)
	name_label.size = Vector2(180, 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(name_label)
	badge = Label.new()
	badge.text = number
	badge.position = Vector2(112, 66)
	badge.size = Vector2(28, 28)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 16)
	badge.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(badge)
	for event in [mouse_entered, mouse_exited, focus_entered, focus_exited]: event.connect(queue_redraw)
	toggled.connect(func(_on: bool): queue_redraw())
	set_navigation_state(state)

func set_thumbnail(source: Texture2D) -> void:
	thumbnail = source
	if photo == null or source == null: return
	photo.texture = source

func set_navigation_state(value: String) -> void:
	state = value
	if name_label == null: return
	var style := NavSkin.surface(state, 4)
	var brand := NavSkin.palette("brand")
	style.border_color = Color(brand.yellow if button_pressed else brand.white)
	style.set_border_width_all(2 if button_pressed else 1)
	style.set_corner_radius_all(7)
	name_label.add_theme_stylebox_override("normal", style)
	name_label.add_theme_color_override("font_color", Color(NavSkin.palette(state).text_primary))
	var badge_style := NavSkin.surface(state, 1)
	badge_style.bg_color = Color(brand.white)
	badge_style.border_color = Color(brand.black)
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("normal", badge_style)
	badge.add_theme_color_override("font_color", Color(brand.black))
	queue_redraw()

func _draw() -> void:
	var at := Vector2(90, 50)
	var brand := NavSkin.palette("brand")
	var ink := Color(brand.black)
	var paper := Color(brand.white)
	var accent := Color(brand.yellow) if button_pressed else paper
	var hot := is_hovered() or has_focus()
	# Opaque dark moat isolates the ring from lake colours and emissive map details.
	draw_circle(at, 49 if button_pressed or hot else 47, ink)
	draw_circle(at, 43, accent, false, 4 if button_pressed else 3, true)
	if button_pressed:
		draw_circle(at, 48, accent, false, 2, true)
		var check_at := Vector2(90, -4)
		draw_circle(check_at, 15, ink)
		draw_circle(check_at, 12, accent)
		draw_polyline(PackedVector2Array([check_at+Vector2(-6,-1), check_at+Vector2(-1,4), check_at+Vector2(6,-5)]), ink, 2.5, true)
	elif is_hovered(): draw_circle(at, 48, paper, false, 2, true)
	if has_focus():
		# Keyboard focus has four brackets; mouse hover keeps a circular outline.
		for index in range(4):
			var angle := PI/4 + index*PI/2
			draw_arc(at, 54, angle-.18, angle+.18, 10, ink, 6, true)
			draw_arc(at, 54, angle-.18, angle+.18, 10, paper, 2, true)

func _has_point(point: Vector2) -> bool:
	# Transparent margins must not intercept neighbouring geographic nodes.
	return point.distance_to(Vector2(90,50)) <= 54 or (name_label != null and Rect2(name_label.position, name_label.size).has_point(point))
