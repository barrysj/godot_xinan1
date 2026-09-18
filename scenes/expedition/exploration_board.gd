extends Control
## Library exploration board with a configurable approved environment background.

signal picked(index: int)
signal layout_changed
const Hotspot = preload("res://scenes/expedition/exploration_hotspot.gd")
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const DEFAULT_ENVIRONMENT_STATE := "anomaly"
const DEFAULT_ENVIRONMENT_VIEWPOINT := "atrium-down"
const CYAN = Color("00f0ff")
const MAGENTA = Color("ff2daa")
const INK = Color("f7fbff")
const POSITIONS = {
	"memory":Vector2(0.18, 0.68),
	"person":Vector2(0.36, 0.34),
	"system":Vector2(0.61, 0.68),
	"battle":Vector2(0.82, 0.34),
}
const TITLES = {
	"memory":"校园记忆",
	"person":"人物事件",
	"system":"借阅终端",
	"battle":"守卫战",
}
const ART = {
	"memory":"res://assets/art/ui/m1_exploration_ui/memory.png",
	"person":"res://assets/art/ui/m1_exploration_ui/character.png",
	"system":"res://assets/art/ui/m1_exploration_ui/terminal.png",
	"battle":"res://assets/art/ui/m1_exploration_ui/guardian.png",
}

var journey
var selected := -1
var environment_state: String = DEFAULT_ENVIRONMENT_STATE
var environment_viewpoint: String = DEFAULT_ENVIRONMENT_VIEWPOINT
var environment_texture: Texture2D
var buttons: Array[Button] = []
var captions: Array[Label] = []

func _ready() -> void:
	custom_minimum_size = Vector2(820, 680)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	clip_contents = true
	resized.connect(_layout)
	if environment_texture == null:
		_load_environment_texture()
	_build()

func set_environment_variant(state: String, viewpoint: String) -> bool:
	var path := ExplorationSkin.library_environment_path(state, viewpoint)
	if path.is_empty():
		return false
	environment_state = state
	environment_viewpoint = viewpoint
	environment_texture = ExplorationSkin.texture(path)
	queue_redraw()
	return true

func environment_variant() -> Dictionary:
	return {
		"state": environment_state,
		"viewpoint": environment_viewpoint,
		"path": ExplorationSkin.library_environment_path(environment_state, environment_viewpoint),
	}

func _load_environment_texture() -> void:
	var path := ExplorationSkin.library_environment_path(environment_state, environment_viewpoint)
	if path.is_empty():
		return
	environment_texture = ExplorationSkin.texture(path)

func _build() -> void:
	if journey == null:
		return
	for i in range(journey.visit.data.hotspots.size()):
		var spot: Dictionary = journey.visit.data.hotspots[i]
		var item := Hotspot.new()
		item.kind = spot.kind
		item.artwork = ExplorationSkin.texture(ART[spot.kind])
		item.completed = _completed(spot)
		item.tooltip_text = TITLES[spot.kind] + "；点击查看详情"
		item.pressed.connect(_pick.bind(i))
		add_child(item)
		buttons.append(item)
		var caption := Label.new()
		caption.text = _caption(spot)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_size_override("font_size", 18)
		caption.add_theme_color_override("font_color", INK)
		caption.add_theme_stylebox_override("normal", _caption_style())
		add_child(caption)
		captions.append(caption)
	for i in range(buttons.size()):
		buttons[i].focus_next = buttons[(i + 1) % buttons.size()].get_path()
		buttons[i].focus_previous = buttons[(i + buttons.size() - 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_right = buttons[(i + 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_left = buttons[(i + buttons.size() - 1) % buttons.size()].get_path()
	_layout()
	if not buttons.is_empty():
		buttons[0].grab_focus()

func _pick(index: int) -> void:
	set_selected(index)
	picked.emit(index)

func set_selected(index: int) -> void:
	selected = index
	for i in range(buttons.size()):
		buttons[i].selected = i == index
		buttons[i].queue_redraw()
	queue_redraw()

func refresh() -> void:
	for i in range(buttons.size()):
		var spot: Dictionary = journey.visit.data.hotspots[i]
		buttons[i].completed = _completed(spot)
		buttons[i].queue_redraw()
		captions[i].text = _caption(spot)
	queue_redraw()

func hotspot_rect(index: int) -> Rect2:
	if index < 0 or index >= buttons.size():
		return Rect2()
	return buttons[index].get_rect()

func hotspot_button(index: int) -> Button:
	return buttons[index] if index >= 0 and index < buttons.size() else null

func _layout() -> void:
	if journey == null:
		return
	for i in range(buttons.size()):
		var spot: Dictionary = journey.visit.data.hotspots[i]
		var center: Vector2 = size * Vector2(POSITIONS[spot.kind])
		buttons[i].size = Vector2(118, 118)
		buttons[i].position = center - buttons[i].size / 2.0
		captions[i].size = Vector2(190, 34)
		captions[i].position = center + Vector2(-95, 61)
	queue_redraw()
	layout_changed.emit()

func _completed(spot: Dictionary) -> bool:
	return journey.visit.data.guard_won if spot.kind == "battle" else journey.visit.data.viewed.has(spot.id)

func _caption(spot: Dictionary) -> String:
	if spot.kind == "battle" and journey.visit.data.guard_won:
		return "守卫已解除"
	if spot.kind != "battle" and journey.visit.data.viewed.has(spot.id):
		return TITLES[spot.kind] + " · 已查看"
	return TITLES[spot.kind]

func _caption_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.08, 0.90)
	style.border_color = Color(0.16, 0.34, 0.45, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(5)
	return style

func _draw() -> void:
	if environment_texture == null:
		draw_style_box(_surface(), Rect2(Vector2.ZERO, size))
		# Keep the original schematic as a safe fallback if a formal background is unavailable.
		for level in range(4):
			var y := 118.0 + level * 92.0
			var inset := 34.0 + level * 30.0
			draw_polyline(PackedVector2Array([
				Vector2(inset, y), Vector2(size.x * 0.32, y + 32),
				Vector2(size.x * 0.50, y + 12), Vector2(size.x * 0.68, y + 32),
				Vector2(size.x - inset, y),
			]), Color(0.25, 0.47, 0.62, 0.32), 3, true)
			draw_line(Vector2(inset, y + 8), Vector2(size.x - inset, y + 8), Color(0.0, 0.94, 1.0, 0.13), 2)
		for i in range(6):
			var shelf := Rect2(Vector2(size.x * (0.07 + i * 0.15), 72), Vector2(size.x * 0.105, 38))
			draw_rect(shelf, Color(0.18, 0.28, 0.38, 0.65))
			for book in range(5):
				draw_line(shelf.position + Vector2(9 + book * 13, 5), shelf.position + Vector2(9 + book * 13, 33), Color(0.37, 0.69, 0.76, 0.38), 2)
		var desk := Rect2(size * Vector2(0.42, 0.47), size * Vector2(0.18, 0.10))
		draw_rect(desk, Color(0.18, 0.24, 0.33, 0.78))
		draw_rect(desk.grow(-7), Color(0.0, 0.94, 1.0, 0.18), false, 2)
	else:
		draw_texture_rect_region(environment_texture, Rect2(Vector2.ZERO, size), _cover_source_rect(environment_texture.get_size()))
		var tint := Color(0.02, 0.04, 0.08, 0.20)
		if environment_state == "anomaly":
			tint = Color(0.035, 0.02, 0.10, 0.16)
		draw_rect(Rect2(Vector2.ZERO, size), tint, true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.94, 1.0, 0.25), false, 1.0)
	# Restrained signal interference inherited from the approved concept.
	for segment in [Rect2(size.x * 0.02, size.y * 0.22, 86, 4), Rect2(size.x * 0.88, size.y * 0.25, 110, 4), Rect2(size.x * 0.04, size.y * 0.84, 72, 3)]:
		draw_rect(segment, Color(0.35, 0.16, 0.95, 0.34))
		draw_rect(Rect2(segment.position + Vector2(18, 7), Vector2(segment.size.x * 0.55, 2)), Color(0.0, 0.94, 1.0, 0.28))
	var title_panel := Rect2(20, 18, 300, 70)
	draw_rect(title_panel, Color(0.025, 0.04, 0.08, 0.90))
	draw_line(title_panel.position, title_panel.position + Vector2(34, 0), CYAN, 2)
	draw_string(FONT, title_panel.position + Vector2(16, 29), "图书馆", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, INK)
	var step := int(journey.data.get("step", 0)) + 1
	draw_string(FONT, title_panel.position + Vector2(16, 55), "探索 · 第 %d / 4 站" % step, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b7c9d7"))
	var signal_panel := Rect2(size.x - 190, 18, 170, 42)
	draw_rect(signal_panel, Color(0.025, 0.04, 0.08, 0.88))
	draw_line(signal_panel.position + Vector2(12, 21), signal_panel.position + Vector2(38, 21), MAGENTA, 2)
	draw_string(FONT, signal_panel.position + Vector2(50, 27), "信号干扰", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
	var footer := "出口已开放 · 可以离开或继续调查" if journey.visit.can_leave() else "出口封锁 · 战胜守卫并领取奖励"
	var footer_width := 380.0 if journey.visit.can_leave() else 350.0
	draw_rect(Rect2(20, size.y - 58, footer_width, 38), Color(0.025, 0.04, 0.08, 0.92))
	draw_circle(Vector2(34, size.y - 39), 4, Color("95e6b1") if journey.visit.can_leave() else MAGENTA)
	draw_string(FONT, Vector2(48, size.y - 31), footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)

func _cover_source_rect(texture_size: Vector2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(Vector2.ZERO, texture_size)
	var scale := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var source_size := size / scale
	return Rect2((texture_size - source_size) * 0.5, source_size)

func _surface() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08101d")
	style.border_color = Color(0.0, 0.94, 1.0, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
