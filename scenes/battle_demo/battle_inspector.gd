extends Control
## Contextual information and equipment exchange; no persistent side notebook.
const Icon = preload("res://scenes/team/object_icon.gd")
var game: Control
var canvas: Control
var panel: PanelContainer
var heading: Label
var summary: Label
var description: Label
var gear_row: HBoxContainer
var gear_button: Button
var gear_name: Label
var pinned := false
var focus_side := -1
var focus_key := -1
var observed: Dictionary = {}
var bag: PanelContainer
var shade: ColorRect
var bag_items: HBoxContainer
var bag_description: Label
var bag_heading: Label
var equip_button: Button
var bag_role := -1
var picked_item := "none"
var rendered_inventory := ""
var pointer := Vector2(-1000, -1000)
var theme_surface: Color
var theme_ink: Color
var theme_accent: Color

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	theme = preload("res://resources/theme/theme-main.tres")
	var colors = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json"))
	theme_surface = Color(colors.daily.surface)
	theme_ink = Color(colors.daily.text_primary)
	theme_accent = Color(colors.brand.cyan)
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	panel = _panel(Vector2(260, 0))
	canvas.add_child(panel)
	var column = _column(panel)
	var top = HBoxContainer.new()
	column.add_child(top)
	heading = _label("", 21)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	var close = _button("收起", close_info)
	top.add_child(close)
	summary = _label("", 17)
	column.add_child(summary)
	description = _label("", 16)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 228
	column.add_child(description)
	gear_row = HBoxContainer.new()
	column.add_child(gear_row)
	gear_button = Icon.new()
	gear_button.custom_minimum_size = Vector2(58, 58)
	gear_button.pressed.connect(open_bag)
	gear_row.add_child(gear_button)
	gear_name = _label("", 16)
	gear_row.add_child(gear_name)
	shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.4)
	shade.size = Vector2(1280, 720)
	canvas.add_child(shade)
	bag = _panel(Vector2(640, 350))
	bag.position = Vector2(320, 180)
	canvas.add_child(bag)
	var contents = _column(bag)
	var bar = HBoxContainer.new()
	contents.add_child(bar)
	bag_heading = _label("背包 · 装备交换", 23)
	bag_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(bag_heading)
	bar.add_child(_button("关闭", close_bag))
	bag_items = HBoxContainer.new()
	bag_items.add_theme_constant_override("separation", 16)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 130)
	contents.add_child(scroll)
	scroll.add_child(bag_items)
	bag_description = _label("", 18)
	bag_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bag_description.custom_minimum_size = Vector2(600, 95)
	contents.add_child(bag_description)
	equip_button = _button("装备", exchange)
	contents.add_child(equip_button)
	bag.hide()
	shade.hide()
	panel.hide()

func _panel(minimum: Vector2) -> PanelContainer:
	var result = PanelContainer.new()
	result.custom_minimum_size = minimum
	var style = StyleBoxFlat.new()
	style.bg_color = theme_surface
	style.border_color = theme_accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	result.add_theme_stylebox_override("panel", style)
	return result

func _column(parent: Control) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	parent.add_child(box)
	return box

func _label(value: String, font_size: int) -> Label:
	var result = Label.new()
	result.text = value
	result.add_theme_color_override("font_color", theme_ink)
	result.add_theme_font_size_override("font_size", font_size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _button(title: String, callback: Callable) -> Button:
	var result = Button.new()
	result.text = title
	result.pressed.connect(callback)
	return result

func active() -> bool:
	return not game.paused and not game.leaving and not is_instance_valid(game.get("team_panel")) and not is_instance_valid(game.get("codex_panel")) and game.get("preview_elapsed") == null and (game.get("screen") == null or game.get("screen") == "battle")

func _process(_delta: float) -> void:
	visible = active()
	if not visible:
		close_info()
		close_bag()
		return
	var factor = minf(size.x / 1280, size.y / 720)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - Vector2(1280, 720) * factor) / 2
	if not pinned and not bag.visible and not (panel.visible and Rect2(panel.position, panel.size).has_point(pointer)):
		observed = pick(pointer)
	if is_instance_valid(game.deployment) and game.deployment.dragging:
		close_info()
	if pinned:
		observed = {}
		for unit in game.units:
			if unit.side == focus_side and (unit.role if unit.side == 0 else unit.slot) == focus_key:
				observed = unit
		if observed.is_empty(): close_info()
	refresh()

func pick(point: Vector2) -> Dictionary:
	var ordered = game.units.duplicate()
	ordered.sort_custom(func(a,b): return game._unit_center(a).y > game._unit_center(b).y)
	for unit in ordered:
		var feet: Vector2 = game._unit_center(unit) + Vector2(0,13)
		if Rect2(feet + Vector2(-44,-105),Vector2(88,136)).has_point(point): return unit
	return {}

func show_unit(unit: Dictionary, detailed: bool) -> void:
	observed = unit
	pinned = detailed
	if unit.is_empty(): close_info(); return
	focus_side = unit.side
	focus_key = unit.role if unit.side == 0 else unit.slot
	if detailed:
		game.inspected_enemy_slot = unit.slot if unit.side == 1 else -1
		if unit.side == 0: game.selected = unit.role
	refresh()

func close_info() -> void:
	pinned = false
	observed = {}
	if panel != null: panel.hide()

func refresh() -> void:
	panel.visible = not observed.is_empty()
	if observed.is_empty(): return
	heading.text = observed.name
	summary.text = "生命 %d / %d\n攻击 %d   护盾 %d" % [maxi(0, observed.hp), observed.max_hp, observed.atk, observed.shield]
	description.visible = pinned
	description.text = "%s · 每 %d 次出手\n%s\n间隔 %.2fs · 射程 %.1f 格" % [observed.skill.display_name, observed.skill.attacks_to_trigger, observed.skill.description, observed.interval, observed.attack_range]
	gear_row.visible = pinned and observed.side == 0
	if gear_row.visible:
		var id: String = game._worn_item(observed.role)
		gear_button.glyph = id
		gear_button.queue_redraw()
		gear_button.tooltip_text = "装备栏：点击查看描述和背包"
		var item = game.Content.gear(id)
		gear_name.text = "装备栏\n" + (item.display_name if item != null else "空槽")
	panel.reset_size()
	var feet: Vector2 = game._unit_center(observed)
	# Prefer the open central lane; clamp vertically inside the battlefield.
	var wanted = Vector2((1280 - panel.size.x) / 2, feet.y - panel.size.y / 2)
	if feet.x > 500 and feet.x < 784:
		wanted.x = feet.x + 60 if feet.x < 640 else feet.x - panel.size.x - 60
	panel.position = Vector2(clampf(wanted.x, 30, 1250 - panel.size.x), clampf(wanted.y, 100, 603 - panel.size.y))

func blocks_event(event: InputEvent) -> bool:
	if not active(): return false
	if bag.visible: return true
	if not (event is InputEventMouseButton or event is InputEventMouseMotion): return false
	var point: Vector2 = canvas.get_global_transform().affine_inverse() * event.position
	return panel.visible and Rect2(panel.position, panel.size).has_point(point)

func _input(event: InputEvent) -> void:
	if not active(): return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and (pinned or bag.visible):
		if bag.visible: close_bag()
		else: close_info()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseMotion or event is InputEventMouseButton): return
	pointer = canvas.get_global_transform().affine_inverse() * event.position
	if bag.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not Rect2(bag.position, bag.size).has_point(pointer):
			close_bag()
			get_viewport().set_input_as_handled()
		return
	if blocks_event(event): return
	var point: Vector2 = canvas.get_global_transform().affine_inverse() * event.position
	if event is InputEventMouseMotion and not pinned:
		show_unit(pick(point), false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var unit = pick(point)
		if unit.is_empty(): close_info()
		else:
			show_unit(unit, true)
			if game.phase != "prepare": get_viewport().set_input_as_handled()

func open_bag() -> void:
	if observed.is_empty() or observed.side != 0: return
	bag_role = observed.role
	picked_item = game._worn_item(bag_role)
	bag.show()
	shade.show()
	_refresh_bag()

func _refresh_bag() -> void:
	bag_heading.text = "背包 · " + game.ROLES[bag_role]
	for child in bag_items.get_children():
		bag_items.remove_child(child)
		child.queue_free()
	var inventory: Dictionary = game._gear_inventory()
	var ids = ["none"] + inventory.keys()
	for id in ids:
		var column = VBoxContainer.new()
		bag_items.add_child(column)
		var icon = Icon.new()
		icon.glyph = "remove" if id == "none" else id
		icon.custom_minimum_size = Vector2(76,76)
		icon.pressed.connect(func(): picked_item = id; _refresh_bag())
		icon.toggle_mode = true
		icon.button_pressed = picked_item == id
		var item = game.Content.gear(id)
		icon.tooltip_text = "卸下装备" if item == null else item.display_name
		column.add_child(icon)
		column.add_child(_label("空槽" if item == null else item.display_name,14))
		var owner: int = inventory.get(id,-1)
		column.add_child(_label("背包" if owner < 0 else game.ROLES[owner],13))
	var item = game.Content.gear(picked_item)
	var owner: int = inventory.get(picked_item,-1)
	bag_description.text = ("空槽\n将当前装备放回背包。" if item == null else item.display_name + "\n" + item.description)
	if owner >= 0 and owner != bag_role:
		bag_description.text += "\n交换给「%s」，原穿戴者「%s」的槽位会腾空。" % [game.ROLES[bag_role],game.ROLES[owner]]
	if game.phase != "prepare": bag_description.text += "\n战斗中可查看，返回整备后交换。"
	equip_button.text = "卸下" if picked_item == "none" else ("转移" if owner >= 0 and owner != bag_role else "装备")
	equip_button.disabled = game.phase != "prepare" or picked_item == game._worn_item(bag_role)

func exchange() -> void:
	if game._equip_item(picked_item, bag_role):
		close_bag()
		_process(0)

func close_bag() -> void:
	if bag != null: bag.hide()
	if shade != null: shade.hide()
