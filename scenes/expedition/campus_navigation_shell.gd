extends Control
## Full-screen map with a fixed action rail and a scrollable information area.
const NavSkin = preload("res://scenes/expedition/campus_navigation_skin.gd")
var rail: PanelContainer
var body: VBoxContainer
var footer: VBoxContainer
var tools: HBoxContainer
var heading: Label
var subtitle: Label
var rail_title: Label
var title_panel: PanelContainer
var utility: HBoxContainer
var utility_panel: PanelContainer
var scroll: ScrollContainer
var content_height := 390.0
var state := "day"

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var safe := MarginContainer.new()
	safe.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(safe)
	safe.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: safe.add_theme_constant_override("margin_"+edge, 24)
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 24)
	safe.add_child(row)
	var left := VBoxContainer.new()
	left.mouse_filter = MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(left)
	title_panel = NavSkin.panel(left, state, 14)
	title_panel.size_flags_horizontal = SIZE_SHRINK_BEGIN
	title_panel.custom_minimum_size.x = 480
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 5)
	title_panel.add_child(titles)
	heading = NavSkin.label(titles, "校园地图", 30)
	subtitle = NavSkin.label(titles, "选择一条路线，向记忆终端前进。", 18, true)
	var space := Control.new()
	space.mouse_filter = MOUSE_FILTER_IGNORE
	space.size_flags_vertical = SIZE_EXPAND_FILL
	left.add_child(space)
	var toolbox := NavSkin.panel(left, state, 12)
	toolbox.size_flags_horizontal = SIZE_SHRINK_BEGIN
	toolbox.custom_minimum_size.x = 320
	var tool_stack := VBoxContainer.new()
	toolbox.add_child(tool_stack)
	tools = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	tool_stack.add_child(tools)
	NavSkin.label(tool_stack, "滚轮缩放 · 拖动地图", 16, true)
	var right := VBoxContainer.new()
	right.mouse_filter = MOUSE_FILTER_IGNORE
	right.add_theme_constant_override("separation", 16)
	row.add_child(right)
	utility_panel = NavSkin.panel(right, state, 10)
	utility_panel.size_flags_horizontal = SIZE_SHRINK_END
	utility_panel.hide()
	utility = HBoxContainer.new()
	utility.add_theme_constant_override("separation", 8)
	utility_panel.add_child(utility)
	var right_space := Control.new()
	right_space.mouse_filter = MOUSE_FILTER_IGNORE
	right_space.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(right_space)
	rail = NavSkin.panel(right, state, 20)
	rail.custom_minimum_size.x = 360
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	rail.add_child(stack)
	rail_title = NavSkin.label(stack, "路线信息", 24)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 300
	scroll.follow_focus = true
	stack.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	footer = VBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	stack.add_child(footer)
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	if rail == null: return
	rail.custom_minimum_size.x = clampf(size.x * .22, 320, 380)
	scroll.custom_minimum_size.y = minf(content_height, maxf(220, size.y * .42))
	title_panel.custom_minimum_size.x = minf(480, maxf(260, size.x - rail.custom_minimum_size.x - 96))

func set_state(value: String) -> void:
	state = value
	utility_panel.visible = utility.get_child_count() > 0
	NavSkin.apply(self, state)
