extends Control
## Presentation of a draft loadout. The original hub owns selection and transactions.
signal action(id: String)
const Ui = preload("res://scenes/ui/campus_ui.gd")
const ChoiceSkin = preload("res://scenes/expedition/choice_skin.gd")
const Art = preload("res://scenes/ui/preparation_art.gd")
const Content = preload("res://game/content/content_db.gd")
var model: Dictionary
var sheet: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	theme = Theme.new()
	theme.default_font = ChoiceSkin.font("body")
	var background := TextureRect.new()
	background.texture = preload("res://assets/art/backgrounds/m1_campus_hub/lecture-hall.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.08,0.16,0.19,0.52)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	sheet = Control.new()
	sheet.size = Vector2(1180,660)
	add_child(sheet)
	var paper := NinePatchRect.new()
	paper.texture = preload("res://assets/art/ui/dispatch/asset_001/panel.png")
	paper.patch_margin_left = 100
	paper.patch_margin_right = 100
	paper.patch_margin_top = 130
	paper.patch_margin_bottom = 100
	paper.mouse_filter = MOUSE_FILTER_IGNORE
	sheet.add_child(paper)
	paper.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	sheet.add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,32)
	margin.add_theme_constant_override("margin_top",44)
	margin.add_theme_constant_override("margin_bottom",40)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label(heading,"出发准备",28)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	_button(heading,"返回基地","base")
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",24)
	body.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	left.add_theme_constant_override("separation",12)
	body.add_child(left)
	var picture := TextureRect.new()
	picture.texture = preload("res://assets/art/ui/event_choice/reward.png")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size = Vector2(300,180)
	picture.size_flags_vertical = SIZE_EXPAND_FILL
	picture.mouse_filter = MOUSE_FILTER_IGNORE
	left.add_child(picture)
	_label(left,"可用点数  %d / %d" % [model.remaining,model.points],23)
	_label(left,"携带格子  %d / %d" % [model.selected_items.size(),model.slots],18)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation",8)
	left.add_child(slots)
	for i in model.slots:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(94,94)
		slot.add_theme_stylebox_override("panel",ChoiceSkin.texture_style(ChoiceSkin.ASSETS.card,12,6))
		slots.add_child(slot)
		var box := VBoxContainer.new()
		slot.add_child(box)
		if i < model.selected_items.size():
			Art.icon(box,model.selected_items[i],48)
			_button(box,"放回","unpack:"+model.selected_items[i])
		else:
			var empty := _label(box,"空位",16)
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.size_flags_vertical = SIZE_EXPAND_FILL
	var right := VBoxContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",10)
	body.add_child(right)
	if model.select_party:
		_label(right,"出发队员  %d / 2" % model.selected_party.size(),22)
		var people := HBoxContainer.new()
		people.add_theme_constant_override("separation",8)
		right.add_child(people)
		for id in model.characters:
			var person = Content.character(Content.role_index(id))
			var selected: bool = model.selected_party.has(id)
			var card := VBoxContainer.new()
			card.size_flags_horizontal = SIZE_EXPAND_FILL
			people.add_child(card)
			var portrait := TextureRect.new()
			portrait.texture = person.portrait
			portrait.custom_minimum_size = Vector2(72,48)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.mouse_filter = MOUSE_FILTER_IGNORE
			card.add_child(portrait)
			var choose := _button(card,person.display_name,"starter:"+id,selected or model.selected_party.size() < 2)
			choose.toggle_mode = true
			choose.button_pressed = selected
			choose.tooltip_text = person.description+"\n"+("已选，点击取消。" if selected else "先取消一名已选队员。" if model.selected_party.size() == 2 else "选择此同学出发。")
		_label(right,"第二、第三节点各邀请一位同伴。",15)
	else: _label(right,"终局行动 · 沿用四人编队",22)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",10)
	right.add_child(grid)
	for item in model.items:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		panel.size_flags_vertical = SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel",ChoiceSkin.texture_style(ChoiceSkin.ASSETS.card if item.unlocked else ChoiceSkin.ASSETS.card_disabled,16,12))
		grid.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",6)
		panel.add_child(box)
		var row := HBoxContainer.new()
		box.add_child(row)
		Art.icon(row,item.id,40)
		var name_label := _label(row,item.name+" · %d 点" % item.cost,18)
		name_label.size_flags_horizontal = SIZE_EXPAND_FILL
		var text := _label(box,item.description if item.unlocked else "完成对应派遣后开放。",14)
		text.custom_minimum_size.x = 240
		text.size_flags_vertical = SIZE_EXPAND_FILL
		var carry := _button(box,"携带" if item.unlocked else "未解锁","prep:"+item.id,item.enabled)
		carry.tooltip_text = item.reason
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",20)
	column.add_child(footer)
	var explanation := _label(footer,"准备点数每次新探索重置；续玩不补充物品。",15)
	explanation.size_flags_horizontal = SIZE_EXPAND_FILL
	var depart := _button(footer,"出发","depart",model.can_depart)
	depart.custom_minimum_size.x = 150
	resized.connect(_layout)
	_layout()
	var focus_id: String = model.get("focus_id","")
	if not focus_id.is_empty():
		for button in find_children("*","Button",true,false):
			if button.get_meta("action_id","") == focus_id and not button.disabled: button.grab_focus.call_deferred(); break

func _layout() -> void:
	if sheet == null: return
	var factor := minf(size.x/1280.0,size.y/720.0)
	sheet.scale = Vector2.ONE*factor
	sheet.position = (size-sheet.size*factor)*0.5

func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Ui.label(value,font_size)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, title: String, id: String, enabled: bool = true) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 34
	button.set_meta("action_id",id)
	button.disabled = not enabled
	Ui.apply_button(button)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		button.add_theme_stylebox_override(state,style)
	button.add_theme_font_size_override("font_size",17)
	button.pressed.connect(func(): action.emit(id))
	parent.add_child(button)
	return button
