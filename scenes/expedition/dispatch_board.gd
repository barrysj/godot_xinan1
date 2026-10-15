extends Control
## Presentation-only board; CampusProgress owns all permanent transactions.
signal closed
const Catalog = preload("res://game/meta/dispatch_catalog.gd")
const Staff = preload("res://game/meta/meta_catalog.gd")
var CAMPUS: Texture2D = load(Catalog.DATA.maps.campus.texture)
var CITY: Texture2D = load(Catalog.DATA.maps.city.texture)
const PANEL = preload("res://assets/art/ui/dispatch/asset_001/panel.png")
const CampusUi = preload("res://scenes/ui/campus_ui.gd")
const Art = preload("res://scenes/ui/dispatch_art.gd")
var PLACES: Array = Catalog.places()
var progress: RefCounted
var outside := false
var selected_place := "library"
var selected_staff := ""
var staff_picker: ColorRect
var staff_slot: Button
var busy := false
var map: Control
var campus_image: TextureRect
var city_image: TextureRect
var pins: Array[Button] = []
var details: VBoxContainer
var resources: Label
var navigation: HBoxContainer
var result_layer: ColorRect
var movement: Tween
var travel_marker: Control
var travel_figure: TextureRect
var travel_label: Label
var travel_elapsed := 0.0
var map_legend: Label
var road_labels: Array[Label] = []
var map_zoom := 1.0
var touches: Dictionary = {}
var body: BoxContainer
var side_panel: PanelContainer
var annotation_layer: Control
var layout_root: MarginContainer

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	var background := ColorRect.new()
	background.color = Color("edf4f3")
	add_child(background)
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	layout_root = margin
	add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_" + edge,32)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",20)
	margin.add_child(column)
	navigation = HBoxContainer.new()
	navigation.add_theme_constant_override("separation",16)
	column.add_child(navigation)
	_label(navigation,"校园派遣",34)
	_button(navigation,"校内",func(): switch_map(false))
	_button(navigation,"校外",func(): switch_map(true))
	resources = _label(navigation,"",22)
	resources.size_flags_horizontal = SIZE_EXPAND_FILL
	resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_button(navigation,"返回基地",func():
		if not busy: closed.emit())
	body = BoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",24)
	column.add_child(body)
	map = Control.new()
	map.size_flags_horizontal = SIZE_EXPAND_FILL
	map.size_flags_stretch_ratio = 2.7
	map.clip_contents = true
	body.add_child(map)
	city_image = _image(CITY)
	campus_image = _image(CAMPUS)
	annotation_layer = Control.new()
	annotation_layer.mouse_filter = MOUSE_FILTER_IGNORE
	map.add_child(annotation_layer)
	annotation_layer.draw.connect(_draw_annotations)
	for entry in Catalog.DATA.maps.city.get("labels", []):
		var road := _label(map,entry.title,18)
		road.add_theme_color_override("font_outline_color",Color.WHITE)
		road.add_theme_constant_override("outline_size",5)
		road_labels.append(road)
	for place in PLACES:
		var pin := _button(map,place.name,func():
			if busy: return
			if place.id == "qingshuihe": switch_map(false)
			else:
				selected_place = place.id
				_refresh())
		pin.tooltip_text = "点击查看此处的永久解锁委托"
		pins.append(pin)
	travel_marker = Control.new()
	travel_marker.mouse_filter = MOUSE_FILTER_IGNORE
	map.add_child(travel_marker)
	travel_figure = TextureRect.new()
	travel_figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	travel_figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	travel_figure.size = Vector2(100,150)
	travel_figure.position = Vector2(-50,-146)
	travel_figure.mouse_filter = MOUSE_FILTER_IGNORE
	travel_marker.add_child(travel_figure)
	travel_label = _label(travel_marker,"",22)
	travel_label.position = Vector2(-55,4)
	travel_label.add_theme_color_override("font_shadow_color",Color.WHITE)
	travel_label.add_theme_constant_override("shadow_offset_x",2)
	travel_label.add_theme_constant_override("shadow_offset_y",2)
	travel_marker.hide()
	map_legend = _label(map,"",18)
	map_legend.add_theme_color_override("font_shadow_color",Color.WHITE)
	map_legend.add_theme_constant_override("shadow_offset_x",2)
	map_legend.add_theme_constant_override("shadow_offset_y",2)
	var panel := PanelContainer.new()
	side_panel = panel
	_skin_panel(panel)
	panel.custom_minimum_size.x = 420
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(panel)
	var padding := MarginContainer.new()
	for edge in ["left","right","top","bottom"]: padding.add_theme_constant_override("margin_"+edge,22)
	padding.add_theme_constant_override("margin_top",70)
	# Keep scrolling cards inside the painted paper, clear of the bottom frame.
	padding.add_theme_constant_override("margin_bottom",64)
	panel.add_child(padding)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	padding.add_child(scroll)
	details = VBoxContainer.new()
	details.size_flags_horizontal = SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",16)
	scroll.add_child(details)
	_label(column,"滚轮 / 双指缩放切换校内外 · 点击地点查看委托",18)
	map.resized.connect(_layout_map)
	resized.connect(_responsive_layout)
	_responsive_layout.call_deferred()
	pins[0].grab_focus.call_deferred()
	_layout_map.call_deferred()
	_refresh()
	if not progress.pending_dispatch_result.is_empty(): _show_result.call_deferred()

func _image(texture: Texture2D) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = MOUSE_FILTER_IGNORE
	map.add_child(image)
	return image

func _label(parent: Node, value: String, font_size: int = 22) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("203d48"))
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size",22)
	CampusUi.apply_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _skin_panel(panel: PanelContainer) -> void:
	var style := StyleBoxTexture.new()
	style.texture = PANEL
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		style.set_texture_margin(side,100)
		style.set_expand_margin(side,0)
	style.texture_margin_top = 130
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: style.set_content_margin(side,18)
	style.modulate_color = Color.WHITE
	panel.add_theme_stylebox_override("panel",style)

func _responsive_layout() -> void:
	var portrait := size.x < size.y * 1.15
	var ui_scale := 2.0 if portrait else 1.0
	layout_root.set_anchors_and_offsets_preset(PRESET_TOP_LEFT)
	layout_root.scale = Vector2.ONE * ui_scale
	layout_root.size = size / ui_scale
	if is_instance_valid(staff_picker):
		var center := staff_picker.get_child(0) as CenterContainer
		center.scale = Vector2.ONE * ui_scale
		center.size = size / ui_scale
	body.vertical = portrait
	side_panel.custom_minimum_size = Vector2(0,480) if portrait else Vector2(420,0)
	side_panel.size_flags_vertical = SIZE_EXPAND_FILL
	side_panel.size_flags_stretch_ratio = 1.5 if portrait else 1.0
	map.size_flags_stretch_ratio = 1.0 if portrait else 2.7
	map.custom_minimum_size.y = 380 if portrait else 0
	map.size_flags_vertical = SIZE_EXPAND_FILL
	_layout_map.call_deferred()

func _layout_map() -> void:
	if busy: return
	var rect := _map_rect()
	for entry in [[city_image,CITY],[campus_image,CAMPUS]]:
		var bounds := _texture_rect(entry[1],map_zoom if (entry[0] == city_image) == outside else 1.0)
		entry[0].size = bounds.size
		entry[0].position = bounds.position
		entry[0].scale = Vector2.ONE
	campus_image.modulate.a = 0 if outside else 1
	city_image.visible = outside
	for i in pins.size():
		pins[i].visible = bool(PLACES[i].outside) == outside
		pins[i].size = pins[i].get_combined_minimum_size() + Vector2(20,0)
		var point: Vector2 = rect.position + rect.size * PLACES[i].point
		var offset := Vector2(30,-75)
		if PLACES[i].id == "qingshuihe": offset = Vector2(-180,-60)
		if PLACES[i].id == "gym": offset = Vector2(-160,28)
		pins[i].position = (point + offset).clamp(Vector2(8,8),(map.size-pins[i].size-Vector2(8,45)).max(Vector2(8,8)))
	map_legend.text = "成都 · 缩放查看校园" if outside else "清水河校区 · 缩小查看校外"
	map_legend.position = Vector2(16,map.size.y-36)
	annotation_layer.queue_redraw()

func _draw_annotations() -> void:
	if busy: return
	var rect := _map_rect()
	for i in pins.size():
		if not pins[i].visible: continue
		var point: Vector2 = rect.position + rect.size * PLACES[i].point
		var box := Rect2(pins[i].position,pins[i].size)
		var end := point.clamp(box.position,box.end)
		var ink := Color("147b92") if PLACES[i].id == selected_place else Color("597f86")
		annotation_layer.draw_line(point,end,Color.WHITE,6.0,true)
		annotation_layer.draw_line(point,end,ink,2.5,true)
		annotation_layer.draw_circle(point,8,Color.WHITE)
		annotation_layer.draw_circle(point,5,ink)

func _city_campus_point() -> Vector2:
	for place in PLACES:
		if place.id == "qingshuihe": return place.point
	return Vector2(0.25,0.2)

func _texture_rect(texture: Texture2D, zoom: float = 1.0) -> Rect2:
	var canvas := Vector2(texture.get_size())
	var extent := canvas * minf(map.size.x/canvas.x,map.size.y/canvas.y) * zoom
	return Rect2((map.size-extent)*0.5,extent)

func _map_rect() -> Rect2:
	return _texture_rect(CITY if outside else CAMPUS,map_zoom)

func zoom_map(factor: float) -> void:
	if busy or is_instance_valid(staff_picker) or is_instance_valid(result_layer) or factor <= 0: return
	map_zoom = clampf(map_zoom*factor,0.65,1.5)
	if (not outside and map_zoom <= 0.74) or (outside and map_zoom >= 1.34):
		switch_map(not outside)
	else: _layout_map()

func _lock_controls(locked: bool) -> void:
	for control in find_children("*","BaseButton",true,false):
		if is_instance_valid(result_layer) and result_layer.is_ancestor_of(control): continue
		if is_instance_valid(staff_picker) and staff_picker.is_ancestor_of(control): continue
		if locked:
			if not control.has_meta("dispatch_disabled"): control.set_meta("dispatch_disabled",control.disabled)
			control.disabled = true
		elif control.has_meta("dispatch_disabled"):
			control.disabled = control.get_meta("dispatch_disabled")
			control.remove_meta("dispatch_disabled")

func _process(delta: float) -> void:
	if not is_instance_valid(travel_marker) or not travel_marker.visible: return
	travel_elapsed += delta
	travel_figure.position.y = -146.0-absf(sin(travel_elapsed*9.0))*7.0

func switch_map(city: bool) -> void:
	if busy or outside == city or is_instance_valid(staff_picker) or is_instance_valid(result_layer): return
	busy = true
	city_image.show()
	touches.clear()
	_lock_controls(true)
	for pin in pins: pin.hide()
	annotation_layer.queue_redraw()
	var campus_rect := _texture_rect(CAMPUS)
	var city_rect := _texture_rect(CITY)
	var anchor := city_rect.position + city_rect.size * _city_campus_point()
	var small := Vector2.ONE*0.10
	if not city:
		campus_image.size = campus_rect.size
		campus_image.scale = small
		campus_image.position = anchor-campus_rect.size*0.05
		campus_image.modulate.a = 0
	movement = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	movement.tween_property(campus_image,"scale",small if city else Vector2.ONE,0.85)
	movement.tween_property(campus_image,"position",anchor-campus_image.size*0.05 if city else campus_rect.position,0.85)
	movement.tween_property(campus_image,"size",campus_rect.size,0.85)
	movement.tween_property(campus_image,"modulate:a",0.0 if city else 1.0,0.85)
	movement.tween_property(city_image,"size",city_rect.size,0.85)
	movement.tween_property(city_image,"position",city_rect.position,0.85)
	await movement.finished
	outside = city
	map_zoom = 1.0
	busy = false
	_lock_controls(false)
	selected_place = ""
	for place in PLACES:
		if place.outside == city and place.id != "qingshuihe":
			selected_place = place.id
			if place.id == ("chunxi" if city else "library"): break
	_layout_map()
	_refresh()

func _icon(parent: Node, source: Variant, extent: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(source) if source is String else source
	picture.custom_minimum_size = Vector2(extent,extent)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _symbol(index: int) -> AtlasTexture:
	var symbol := AtlasTexture.new()
	symbol.atlas = load("res://assets/art/ui/dispatch/asset_005/icons.png")
	var cell := symbol.atlas.get_size() / 2.0
	symbol.region = Rect2(Vector2(index % 2, index / 2) * cell, cell)
	return symbol

func _reward_icon(task: Dictionary) -> Texture2D:
	if task.kind == "preparation" or task.kind == "item": return load("res://assets/art/ui/preparation/asset_001/%s.png" % task.value)
	return _symbol({"feature":1,"character":3,"buff":2}.get(task.kind,1))

func _card(parent: Node, selected: bool = false) -> VBoxContainer:
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e3f2f2") if selected else Color("f7faf7")
	style.border_color = Color("55aabd") if selected else Color("d2e1df")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: style.set_content_margin(side,14)
	frame.add_theme_stylebox_override("panel",style)
	parent.add_child(frame)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	frame.add_child(content)
	return content

func _refresh() -> void:
	resources.text = "修复资源  %d" % progress.points
	annotation_layer.queue_redraw()
	for child in details.get_children():
		details.remove_child(child)
		child.queue_free()
	for place in PLACES:
		if place.id == selected_place: _label(details,place.name,28)
	_label(details,"派遣人员 · %d/1" % (0 if selected_staff.is_empty() else 1),18)
	var crew := HBoxContainer.new()
	crew.add_theme_constant_override("separation",14)
	details.add_child(crew)
	staff_slot = _button(crew,"",_open_staff_picker)
	staff_slot.custom_minimum_size = Vector2(84,84)
	# The painted socket already supplies its frame. Keep the hit target, not a second box.
	for state in ["normal","hover","pressed","disabled","focus"]:
		staff_slot.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	staff_slot.add_theme_color_override("icon_normal_color",Color.WHITE)
	staff_slot.add_theme_color_override("icon_hover_color",Color(1.15,1.15,1.15))
	staff_slot.add_theme_color_override("icon_focus_color",Color(1.15,1.15,1.15))
	staff_slot.add_theme_color_override("icon_pressed_color",Color(0.75,0.9,0.95))
	staff_slot.icon = load("res://assets/art/ui/dispatch/asset_007/staff_slot.png") if selected_staff.is_empty() else Art.portrait(selected_staff)
	staff_slot.expand_icon = true
	staff_slot.add_theme_constant_override("icon_max_width",84)
	staff_slot.tooltip_text = "安排人员" if selected_staff.is_empty() else "更换人员"
	var staff_info := VBoxContainer.new()
	staff_info.size_flags_vertical = SIZE_SHRINK_CENTER
	crew.add_child(staff_info)
	_label(staff_info,"待安排" if selected_staff.is_empty() else Staff.find(Staff.STAFF,selected_staff).name,22)
	_label(staff_info,"点击空位选择人员" if selected_staff.is_empty() else "点击头像更换",16)
	var assignments: Array = Catalog.at_location(selected_place)
	if assignments.is_empty(): _label(details,"此处暂无委托",20)
	for task in assignments:
		var done: bool = progress.commission_unlocks.has(task.id)
		var card := _card(details)
		var reward := HBoxContainer.new()
		reward.add_theme_constant_override("separation",14)
		card.add_child(reward)
		_icon(reward,_reward_icon(task),84)
		var heading := VBoxContainer.new()
		heading.size_flags_horizontal = SIZE_EXPAND_FILL
		reward.add_child(heading)
		_label(heading,{"feature":"功能开放","preparation":"准备池","character":"人物解锁","item":"物品出现池","buff":"探索效果"}.get(task.kind,"永久解锁"),16)
		var title := _label(heading,task.name,24)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label(heading,"已解锁" if done else "永久解锁",16)
		var description := _label(card,task.description,18)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var footer := HBoxContainer.new()
		footer.add_theme_constant_override("separation",10)
		card.add_child(footer)
		_icon(footer,_symbol(0),40)
		var price := _label(footer,"免费" if task.cost == 0 else str(int(task.cost)),24)
		price.size_flags_horizontal = SIZE_EXPAND_FILL
		price.tooltip_text = "修复资源消耗"
		var reason: String = progress.commission_reason(task.id,selected_staff)
		var action := _button(footer,"已完成" if done else "派遣",func(): execute(task.id))
		action.set_meta("action_id","commission:"+task.id)
		action.icon = _symbol(1)
		action.expand_icon = true
		action.add_theme_constant_override("icon_max_width",26)
		action.custom_minimum_size.x = 126
		action.disabled = not reason.is_empty() or busy
		if not reason.is_empty() and not done and reason != "请选择派遣人员":
			var status := _label(card,reason,16)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _open_staff_picker() -> void:
	if busy or is_instance_valid(result_layer) or is_instance_valid(staff_picker): return
	touches.clear()
	staff_picker = ColorRect.new()
	staff_picker.color = Color(0.08,0.16,0.20,0.65)
	add_child(staff_picker)
	staff_picker.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_lock_controls(true)
	var center := CenterContainer.new()
	staff_picker.add_child(center)
	center.scale = layout_root.scale
	center.size = size / center.scale
	var panel := PanelContainer.new()
	CampusUi.apply_panel(panel)
	panel.custom_minimum_size = Vector2(500,0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	panel.add_child(margin)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation",14)
	margin.add_child(list)
	_label(list,"安排人员",28)
	_label(list,"选择一名后勤成员 · 当前能力相同",18)
	var choices: Array[Button] = []
	for person in Staff.STAFF:
		var choose := _button(list,person.name + (" · 已安排" if person.id == selected_staff else ""),func():
			selected_staff = person.id
			_close_staff_picker()
			_refresh()
			staff_slot.grab_focus.call_deferred()
			staff_slot.modulate = Color(0.78,1.0,1.0)
			staff_slot.create_tween().tween_property(staff_slot,"modulate",Color.WHITE,0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
		choose.icon = Art.portrait(person.id)
		choose.expand_icon = true
		choose.add_theme_constant_override("icon_max_width",64)
		choose.custom_minimum_size.y = 88
		choose.set_meta("staff",person.id)
		choices.append(choose)
	choices.append(_button(list,"取消",_close_staff_picker))
	for i in choices.size():
		choices[i].focus_next = choices[(i+1)%choices.size()].get_path()
		choices[i].focus_previous = choices[(i-1+choices.size())%choices.size()].get_path()
		choices[i].focus_neighbor_bottom = choices[i].focus_next
		choices[i].focus_neighbor_top = choices[i].focus_previous
	choices[0].grab_focus()

func _close_staff_picker() -> void:
	if not is_instance_valid(staff_picker): return
	staff_picker.queue_free()
	staff_picker = null
	_lock_controls(false)
	staff_slot.grab_focus()

func execute(id: String) -> void:
	if busy or is_instance_valid(staff_picker) or not progress.execute_commission(id,selected_staff): return
	busy = true
	_refresh()
	_lock_controls(true)
	var result: Dictionary = progress.pending_dispatch_result.duplicate(true)
	var rect := _map_rect()
	var target := rect.get_center()
	for place in PLACES:
		if place.id == result.location: target = rect.position + rect.size * place.point
	var start := rect.position + rect.size * (_city_campus_point() if outside else Vector2(0.5,0.82))
	travel_label.text = Staff.find(Staff.STAFF,selected_staff).name.right(2) + "  出发"
	travel_figure.texture = Art.portrait(selected_staff)
	travel_figure.flip_h = target.x < start.x
	travel_elapsed = 0
	travel_marker.position = start
	travel_marker.show()
	movement = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movement.tween_property(travel_marker,"position",target,1.15)
	movement.tween_callback(func(): travel_label.text = "完成委托")
	movement.tween_interval(0.35)
	movement.tween_callback(func():
		travel_label.text = "正在归队"
		travel_figure.flip_h = not travel_figure.flip_h)
	movement.tween_property(travel_marker,"position",start,1.15)
	await movement.finished
	travel_marker.hide()
	busy = false
	_show_result()

func _show_result() -> void:
	if progress.pending_dispatch_result.is_empty() or is_instance_valid(result_layer): return
	var result: Dictionary = progress.pending_dispatch_result.duplicate(true)
	var task := Catalog.find(result.commission)
	result_layer = ColorRect.new()
	result_layer.color = Color(0.08,0.16,0.20,0.75)
	add_child(result_layer)
	result_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_lock_controls(true)
	var center := CenterContainer.new()
	result_layer.add_child(center)
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	_skin_panel(panel)
	panel.custom_minimum_size = Vector2(640,360)
	center.add_child(panel)
	var padding := MarginContainer.new()
	for edge in ["left","right","top","bottom"]: padding.add_theme_constant_override("margin_"+edge,36)
	padding.add_theme_constant_override("margin_top",64)
	panel.add_child(padding)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",24)
	padding.add_child(content)
	_label(content,"派遣成果",32)
	var staff_row := HBoxContainer.new()
	content.add_child(staff_row)
	var returned := TextureRect.new()
	returned.texture = Art.portrait(result.staff_ids[0])
	returned.custom_minimum_size = Vector2(110,110)
	returned.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	returned.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	returned.mouse_filter = MOUSE_FILTER_IGNORE
	staff_row.add_child(returned)
	_label(staff_row,Staff.find(Staff.STAFF,result.staff_ids[0]).name+"已归队",22)
	var reward := HBoxContainer.new()
	content.add_child(reward)
	_icon(reward,_reward_icon(task),86)
	_label(reward,task.name + " · 已解锁",27)
	var description := _label(content,task.description,22)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var receipt := HBoxContainer.new()
	content.add_child(receipt)
	_icon(receipt,_symbol(0),40)
	_label(receipt,"%d  ·  成果已保存" % task.cost,20)
	var confirm := _button(content,"收下成果",func():
		if progress.acknowledge_dispatch_result(result.id):
			result_layer.queue_free()
			result_layer = null
			_lock_controls(false)
			_refresh())
	confirm.focus_next = confirm.get_path()
	confirm.focus_previous = confirm.get_path()
	confirm.grab_focus()

func _input(event: InputEvent) -> void:
	if is_instance_valid(staff_picker):
		if event.is_action_pressed("ui_cancel"):
			_close_staff_picker()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if not event.pressed: touches.erase(event.index)
		elif not busy and not is_instance_valid(result_layer) and map.get_global_rect().has_point(event.position): touches[event.index] = event.position
	if busy or is_instance_valid(result_layer): return
	if event is InputEventMouseButton and event.pressed and map.get_global_rect().has_point(event.position):
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_WHEEL_UP]:
			zoom_map(pow(0.90 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1.0/0.90,maxf(0.1,event.factor)))
			get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture and map.get_global_rect().has_point(event.position):
		zoom_map(event.factor)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and touches.has(event.index):
		var before: Array = touches.values()
		touches[event.index] = event.position
		if touches.size() == 2:
			var after: Array = touches.values()
			var old_distance: float = before[0].distance_to(before[1])
			if old_distance > 12: zoom_map(after[0].distance_to(after[1])/old_distance)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not busy and not is_instance_valid(result_layer): closed.emit()

