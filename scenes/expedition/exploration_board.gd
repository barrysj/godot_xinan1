extends Control
## Shared location exploration with approved backgrounds and hotspot controls.

signal picked(index: int)
signal layout_changed
signal scene_requested(id: String)
signal passage_requested
const PlaceScenes = preload("res://game/run/place_scenes.gd")
const SceneNavigation = preload("res://scenes/expedition/place_scene_navigation.gd")
const Hotspot = preload("res://scenes/expedition/exploration_hotspot.gd")
const PassageHotspot = preload("res://scenes/expedition/passage_hotspot.gd")
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const Feedback = preload("res://scenes/expedition/exploration_feedback.gd")
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
var environment_path := ""
var location_title := "图书馆"
var buttons: Array[Button] = []
var scene_navigation: Control
var scene_title := ""
var passage_hotspot: Button
var passage_exit_title := ""
var room_layout: Dictionary = {}
var has_room_layout := false
var previous_background: Texture2D
var transition_alpha := 0.0
var transition_tween: Tween
var footer_buttons: Array[Control] = []

func configure_place_scenes() -> bool:
	var scene: Dictionary = journey.current_scene()
	if scene.is_empty(): return false
	has_room_layout = scene.has("layout")
	room_layout = scene.get("layout",{})
	if not set_campus_environment(PlaceScenes.path(scene),journey.title(str(journey.visit.data.place))): return false
	scene_title = "%s · %s" % [scene.title,PlaceScenes.floor_label(int(scene.floor))]
	scene_navigation = SceneNavigation.new()
	scene_navigation.scenes = PlaceScenes.entries(journey.stop())
	scene_navigation.current = scene.id
	scene_navigation.scene_requested.connect(func(id: String): scene_requested.emit(id))
	return true

func _ready() -> void:
	custom_minimum_size = Vector2(820, 680)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	clip_contents = true
	resized.connect(_layout)
	if environment_texture == null:
		_load_environment_texture()
	_build()
	if scene_navigation != null:
		passage_hotspot = PassageHotspot.new()
		passage_hotspot.name = "PassageHotspot"
		passage_hotspot.pressed.connect(func(): passage_requested.emit())
		add_child(passage_hotspot)
		_refresh_passage()
		add_child(scene_navigation)
		scene_navigation.focus_layout_changed.connect(_wire_focus)
		_layout()

func set_environment_variant(state: String, viewpoint: String) -> bool:
	var path := ExplorationSkin.library_environment_path(state, viewpoint)
	if path.is_empty():
		return false
	environment_state = state
	environment_viewpoint = viewpoint
	environment_path = path
	location_title = "图书馆"
	environment_texture = ExplorationSkin.texture(path)
	queue_redraw()
	return true

func set_campus_environment(path: String, title: String, state: String = "anomaly") -> bool:
	if path.is_empty() or not ResourceLoader.exists(path): return false
	environment_texture = ExplorationSkin.texture(path)
	if environment_texture == null: return false
	environment_path = path
	environment_state = state
	environment_viewpoint = "campus"
	location_title = title
	queue_redraw()
	return true

func environment_variant() -> Dictionary:
	return {
		"state": environment_state,
		"viewpoint": environment_viewpoint,
		"path": environment_path if not environment_path.is_empty() else ExplorationSkin.library_environment_path(environment_state, environment_viewpoint),
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
		item.visible = not has_room_layout or room_layout.has(spot.kind)
		item.tooltip_text = {"battle":"封锁守卫", "memory":"校园记忆", "person":"同行伙伴", "system":"记忆终端线索"}[spot.kind]
		item.artwork = ExplorationSkin.texture(ART[spot.kind])
		item.completed = _completed(spot)
		item.set_motion_index(i)
		item.pressed.connect(_pick.bind(i))
		add_child(item)
		buttons.append(item)
	for i in range(buttons.size()):
		buttons[i].focus_next = buttons[(i + 1) % buttons.size()].get_path()
		buttons[i].focus_previous = buttons[(i + buttons.size() - 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_right = buttons[(i + 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_left = buttons[(i + buttons.size() - 1) % buttons.size()].get_path()
	_layout()
	for item in buttons:
		if item.visible:
			item.grab_focus()
			break

func change_scene() -> void:
	# Preserve the HUD and floor filter; only scene-dependent controls are updated.
	var old_texture := environment_texture
	var scene: Dictionary = journey.current_scene()
	set_campus_environment(PlaceScenes.path(scene),location_title)
	has_room_layout = scene.has("layout")
	room_layout = scene.get("layout",{})
	scene_title = "%s · %s" % [scene.title,PlaceScenes.floor_label(int(scene.floor))]
	selected = -1
	for item in buttons:
		item.visible = not has_room_layout or room_layout.has(item.kind)
		item.selected = false
	scene_navigation.set_current(scene.id)
	_refresh_passage()
	_layout()
	Feedback.play(self)
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not focused.is_visible_in_tree() or (focused is BaseButton and focused.disabled):
		scene_navigation.scene_buttons[scene.id].grab_focus()
	if transition_tween != null: transition_tween.kill()
	previous_background = old_texture
	transition_alpha = 1.0
	transition_tween = create_tween()
	transition_tween.tween_method(func(value: float): transition_alpha = value; queue_redraw(),1.0,0.0,Feedback.seconds("scene_transition")).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition_tween.tween_callback(func(): previous_background = null)

func _wire_focus() -> void:
	if scene_navigation == null or not is_instance_valid(scene_navigation.floor_picker): return
	var chain: Array[Control] = []
	for item in buttons:
		if item.visible: chain.append(item)
	if is_instance_valid(passage_hotspot) and not passage_hotspot.disabled: chain.append(passage_hotspot)
	chain.append(scene_navigation.floor_picker)
	for item in scene_navigation.map_buttons.values():
		if item.visible: chain.append(item)
	chain.append_array(scene_navigation.scene_buttons.values())
	for item in footer_buttons:
		if is_instance_valid(item) and item.visible and not item.disabled: chain.append(item)
	for i in range(chain.size()):
		var before := chain[(i+chain.size()-1)%chain.size()].get_path()
		var after := chain[(i+1)%chain.size()].get_path()
		chain[i].focus_previous = before
		chain[i].focus_next = after
		chain[i].focus_neighbor_left = before
		chain[i].focus_neighbor_right = after
		chain[i].focus_neighbor_top = before
		chain[i].focus_neighbor_bottom = after

func _pick(index: int) -> void:
	Feedback.play(self)
	set_selected(index)
	picked.emit(index)

func set_selected(index: int) -> void:
	selected = index
	for i in range(buttons.size()):
		buttons[i].selected = i == index
		buttons[i].queue_redraw()
	queue_redraw()

func refresh() -> void:
	_refresh_passage()
	for i in range(buttons.size()):
		var spot: Dictionary = journey.visit.data.hotspots[i]
		if not buttons[i].completed and _completed(spot): buttons[i].celebrate()
		buttons[i].completed = _completed(spot)
		buttons[i].queue_redraw()
	queue_redraw()

func _refresh_passage() -> void:
	if not is_instance_valid(passage_hotspot): return
	var target: Dictionary = journey.passage()
	if passage_hotspot.disabled and target.get("action") == "leave" and target.get("enabled",false): passage_hotspot.celebrate()
	passage_hotspot.destination = str(target.get("title","通路"))
	passage_hotspot.tooltip_text = str(target.get("hint",""))
	passage_hotspot.disabled = not target.get("enabled",false)
	if target.get("action") == "leave" and not passage_exit_title.is_empty():
		passage_hotspot.destination = passage_exit_title
		if not passage_hotspot.disabled: passage_hotspot.tooltip_text = "离开地点，返回"+passage_exit_title
	passage_hotspot.queue_redraw()

func hotspot_rect(index: int) -> Rect2:
	if index < 0 or index >= buttons.size():
		return Rect2()
	return buttons[index].get_rect()

func hotspot_button(index: int) -> Button:
	return buttons[index] if index >= 0 and index < buttons.size() else null

func _layout() -> void:
	if journey == null:
		return
	if is_instance_valid(passage_hotspot):
		passage_hotspot.size = Vector2(128,150)
		passage_hotspot.position = Vector2(size.x-174,clampf(size.y*0.65,440,size.y-240))-passage_hotspot.size/2
		if room_layout.has("passage"): passage_hotspot.position = _layout_point(room_layout.passage)-passage_hotspot.size/2
	for i in range(buttons.size()):
		var spot: Dictionary = journey.visit.data.hotspots[i]
		var center: Vector2 = size * Vector2(POSITIONS[spot.kind])
		if scene_navigation != null:
			center = Vector2(30,130)+Vector2(maxf(390,size.x-390),maxf(230,size.y-330))*Vector2(POSITIONS[spot.kind])
		buttons[i].size = Vector2(118, 118)
		if room_layout.has(spot.kind): center = _layout_point(room_layout[spot.kind])
		buttons[i].position = center - buttons[i].size / 2.0
	_wire_focus()
	queue_redraw()
	layout_changed.emit()

func _layout_point(value: Array) -> Vector2:
	var texture_size := environment_texture.get_size()
	var reference_size := Vector2(1920,1080)
	var reference_crop := reference_size/maxf(reference_size.x/texture_size.x,reference_size.y/texture_size.y)
	var source_point := (texture_size-reference_crop)/2+Vector2(value[0],value[1])*reference_crop
	var crop := _cover_source_rect(texture_size)
	return ((source_point-crop.position)/crop.size*size).clamp(Vector2(70,110),size-Vector2(70,180))

func _completed(spot: Dictionary) -> bool:
	return journey.visit.data.guard_won if spot.kind == "battle" else journey.visit.data.viewed.has(spot.id)

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
		if previous_background != null and transition_alpha > 0:
			draw_texture_rect_region(previous_background,Rect2(Vector2.ZERO,size),_cover_source_rect(previous_background.get_size()),Color(1,1,1,transition_alpha))
		var tint := Color(0.02, 0.04, 0.08, 0.20)
		if environment_state == "anomaly":
			tint = Color(0.035, 0.02, 0.10, 0.16)
		draw_rect(Rect2(Vector2.ZERO, size), tint, true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.94, 1.0, 0.25), false, 1.0)
	# Restrained signal interference inherited from the approved concept.
	for segment in [Rect2(size.x * 0.02, size.y * 0.22, 86, 4), Rect2(size.x * 0.88, size.y * 0.25, 110, 4), Rect2(size.x * 0.04, size.y * 0.84, 72, 3)]:
		draw_rect(segment, Color(0.35, 0.16, 0.95, 0.34))
		draw_rect(Rect2(segment.position + Vector2(18, 7), Vector2(segment.size.x * 0.55, 2)), Color(0.0, 0.94, 1.0, 0.28))
	var title_panel := Rect2(20, 18, maxf(300,FONT.get_string_size(location_title,HORIZONTAL_ALIGNMENT_LEFT,-1,25).x+32), 70)
	draw_rect(title_panel, Color(0.025, 0.04, 0.08, 0.90))
	draw_line(title_panel.position, title_panel.position + Vector2(34, 0), CYAN, 2)
	draw_string(FONT, title_panel.position + Vector2(16, 29), location_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, INK)
	var step := int(journey.data.get("step", 0)) + 1
	var subtitle := scene_title if not scene_title.is_empty() else "探索 · 第 %d 站" % step
	draw_string(FONT, title_panel.position + Vector2(16, 55), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b7c9d7"))
	var signal_panel := Rect2(size.x - 190, 18, 170, 42)
	draw_rect(signal_panel, Color(0.025, 0.04, 0.08, 0.88))
	draw_line(signal_panel.position + Vector2(12, 21), signal_panel.position + Vector2(38, 21), MAGENTA, 2)
	draw_string(FONT, signal_panel.position + Vector2(50, 27), "信号干扰" if environment_state == "anomaly" else "信号稳定", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
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
