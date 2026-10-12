extends Control
## Navigation requests only; the campaign controller saves before changing the view.
signal scene_requested(id: String)
signal focus_layout_changed
const Scenes = preload("res://game/run/place_scenes.gd")
const Ui = preload("res://scenes/ui/campus_ui.gd")
const PIN = preload("res://assets/art/ui/place_scenes/scene.svg")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var scenes: Array = []
var current := ""
const ALL_FLOORS := 99
var floor_index := ALL_FLOORS
var floor_picker: OptionButton
var minimap: Control
var map_buttons: Dictionary = {}
var scene_buttons: Dictionary = {}
var navigation_row: HBoxContainer
var strip: PanelContainer
var strip_heading: Label
var scene_choices: HBoxContainer
var scene_scroll: ScrollContainer
var highlighted := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var map_panel := PanelContainer.new()
	map_panel.name = "PlaceMinimap"
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_panel.offset_left = -326
	map_panel.offset_right = -20
	map_panel.offset_top = 84
	map_panel.offset_bottom = 376
	map_panel.add_theme_stylebox_override("panel",Ui.hub_surface())
	add_child(map_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	map_panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := Ui.label("地点小地图",18,"night")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	floor_picker = OptionButton.new()
	floor_picker.add_theme_font_size_override("font_size",16)
	Ui.apply_hub_button(floor_picker)
	heading.add_child(floor_picker)
	var floors: Array = []
	for scene in scenes:
		if not floors.has(int(scene.floor)): floors.append(int(scene.floor))
	floors.sort()
	floor_picker.add_item("全部楼层")
	floor_picker.set_item_metadata(0,ALL_FLOORS)
	for value in floors:
		floor_picker.add_item(Scenes.floor_label(value))
		floor_picker.set_item_metadata(floor_picker.item_count-1,value)
		if value == floor_index: floor_picker.select(floor_picker.item_count-1)
	floor_picker.item_selected.connect(func(index):
		floor_index = int(floor_picker.get_item_metadata(index))
		_layout_map())
	minimap = Control.new()
	minimap.custom_minimum_size = Vector2(260,170)
	minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(minimap)
	minimap.draw.connect(_draw_map)
	minimap.resized.connect(_layout_map)
	for scene in scenes:
		var item := Button.new()
		item.text = str(scenes.find(scene)+1)
		item.tooltip_text = "%s · %s%s" % [scene.title,Scenes.floor_label(int(scene.floor))," · 当前场景" if scene.id == current else ""]
		item.custom_minimum_size = Vector2(34,34)
		item.add_theme_font_size_override("font_size",16)
		_style(item,int(scene.floor),scene.id == current)
		item.pressed.connect(func(): scene_requested.emit(scene.id))
		_connect_highlight(item,scene.id)
		minimap.add_child(item)
		map_buttons[scene.id] = item
	column.add_child(Ui.label("点击场景切换 · 相对位置示意",13,"night"))
	strip = PanelContainer.new()
	strip.name = "SceneNavigation"
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	strip.offset_left = 20
	strip.offset_right = 620
	strip.offset_top = -152
	strip.offset_bottom = -80
	var surface := Ui.hub_surface()
	surface.set_content_margin_all(8)
	strip.add_theme_stylebox_override("panel",surface)
	add_child(strip)
	navigation_row = HBoxContainer.new()
	navigation_row.add_theme_constant_override("separation",8)
	strip.add_child(navigation_row)
	strip_heading = Ui.label("探索场景",18,"night")
	strip_heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	strip_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	navigation_row.add_child(strip_heading)
	scene_scroll = ScrollContainer.new()
	scene_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scene_scroll.follow_focus = true
	navigation_row.add_child(scene_scroll)
	scene_choices = HBoxContainer.new()
	scene_choices.add_theme_constant_override("separation",8)
	scene_scroll.add_child(scene_choices)
	for scene in scenes:
		var item := _button(scene.title,PIN)
		_style(item,int(scene.floor),scene.id == current)
		item.tooltip_text = "%d · %s · %s%s" % [scenes.find(scene)+1,scene.title,Scenes.floor_label(int(scene.floor))," · 当前场景" if scene.id == current else ""]
		item.pressed.connect(func(): scene_requested.emit(scene.id))
		_connect_highlight(item,scene.id)
		scene_choices.add_child(item)
		scene_buttons[scene.id] = item
	resized.connect(_layout_strip)
	scene_choices.minimum_size_changed.connect(_layout_strip)
	_layout_strip()
	_layout_map()
	if scene_buttons.has(current): scene_scroll.ensure_control_visible.call_deferred(scene_buttons[current])

func _layout_strip() -> void:
	if not is_instance_valid(scene_choices): return
	var content_width := 16+strip_heading.get_combined_minimum_size().x+8+scene_choices.get_combined_minimum_size().x
	strip.size.x = minf(content_width,maxf(240,size.x-40))

func _connect_highlight(item: Button, id: String) -> void:
	item.mouse_entered.connect(func(): _highlight(id))
	item.mouse_exited.connect(func(): _highlight(""))
	item.focus_entered.connect(func(): _highlight(id))
	item.focus_exited.connect(func(): _highlight(""))

func _highlight(id: String) -> void:
	highlighted = id
	for scene in scenes:
		for item in [map_buttons.get(scene.id),scene_buttons.get(scene.id)]:
			if item != null: _style(item,int(scene.floor),scene.id == current or scene.id == highlighted)
	if is_instance_valid(minimap): minimap.queue_redraw()

func set_current(id: String) -> void:
	current = id
	_highlight(highlighted)
	for scene in scenes:
		var hint := "%s · %s%s" % [scene.title,Scenes.floor_label(int(scene.floor))," · 当前场景" if scene.id == current else ""]
		map_buttons[scene.id].tooltip_text = hint
		scene_buttons[scene.id].tooltip_text = hint
	scene_scroll.ensure_control_visible(scene_buttons[id])

func _button(title: String, icon: Texture2D) -> Button:
	var item := Button.new()
	item.text = title
	item.icon = icon
	item.expand_icon = true
	item.add_theme_constant_override("icon_max_width",22)
	item.add_theme_font_size_override("font_size",18)
	item.custom_minimum_size = Vector2(104,48)
	Ui.apply_hub_button(item)
	return item

static func floor_color(value: int) -> Color:
	# Stable color per floor; labels remain available for color-blind players.
	var base := Color(Ui.colors("brand").cyan)
	return Color.from_hsv(fposmod(base.h+float(value)*0.115,1.0),0.48,0.95)

func _style(item: Button, floor_value: int, active: bool) -> void:
	Ui.apply_hub_button(item)
	var color := floor_color(floor_value)
	for state in ["normal","hover","pressed","focus"]:
		var style := Ui.hub_surface(state)
		style.set_content_margin_all(6)
		style.border_color = Color.WHITE if state == "focus" else color
		style.set_border_width_all(3 if active or state == "focus" else 1)
		style.bg_color = color.darkened(0.60 if active else 0.86)
		item.add_theme_stylebox_override(state,style)
	item.add_theme_color_override("icon_normal_color",color)

func _point(scene: Dictionary) -> Vector2:
	return Vector2(25,25)+Vector2(scene.position[0],scene.position[1])*(minimap.size-Vector2(50,50))

func _layout_map() -> void:
	if not is_instance_valid(minimap): return
	for scene in scenes:
		var item: Button = map_buttons.get(scene.id)
		if item == null: continue
		item.visible = floor_index == ALL_FLOORS or int(scene.floor) == floor_index
		item.size = Vector2(34,34)
		item.position = _point(scene)-item.size/2
	floor_picker.add_theme_color_override("font_color",Color(Ui.colors("night").text_primary) if floor_index == ALL_FLOORS else floor_color(floor_index))
	minimap.queue_redraw()
	focus_layout_changed.emit()

func _draw_map() -> void:
	var color := floor_color(0 if floor_index == ALL_FLOORS else floor_index)
	for i in range(1,5):
		minimap.draw_line(Vector2(minimap.size.x*i/5,0),Vector2(minimap.size.x*i/5,minimap.size.y),Color(color,0.10),1)
		minimap.draw_line(Vector2(0,minimap.size.y*i/5),Vector2(minimap.size.x,minimap.size.y*i/5),Color(color,0.10),1)
	# These are the actual sequential passages configured by Scenes order.
	for i in range(scenes.size()-1):
		var a: Dictionary = scenes[i]
		var b: Dictionary = scenes[i+1]
		if floor_index != ALL_FLOORS and (int(a.floor) != floor_index or int(b.floor) != floor_index): continue
		minimap.draw_line(_point(a),_point(b),Color(0.65,0.82,0.88,0.26),2,true)
	for scene in scenes:
		if floor_index != ALL_FLOORS and int(scene.floor) != floor_index: continue
		var point := _point(scene)
		var tint := floor_color(int(scene.floor))
		if scene.id == current: minimap.draw_arc(point,23,0,TAU,32,Color.WHITE,3,true)
		if scene.id == highlighted: minimap.draw_arc(point,27,0,TAU,32,tint,2,true)
		minimap.draw_rect(Rect2(point+Vector2(-61,23),Vector2(122,24)),Color(0.025,0.04,0.08,0.94))
		minimap.draw_string(FONT,point+Vector2(-61,41),scene.title+" · "+Scenes.floor_label(int(scene.floor)),HORIZONTAL_ALIGNMENT_CENTER,122,16,tint)
