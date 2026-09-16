extends Control
const CardView = preload("res://scenes/holo_card/holo_card_view.gd")
var grid: GridContainer
var scroll: ScrollContainer
var detail_panel: Control
var active_card: Control
var selected_button: Button

func _ready() -> void:
	scroll = ScrollContainer.new()
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",20)
	grid.add_theme_constant_override("v_separation",16)
	scroll.add_child(grid)
	refresh()

func card_resources() -> Array:
	return [load("res://assets/art/holo_cards/class_photo/card.tres")]

func refresh() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for visual in card_resources():
		var tile = Button.new()
		tile.custom_minimum_size = Vector2(280,265)
		tile.tooltip_text = visual.title + "\n" + visual.caption
		var box = VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(box)
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var image = TextureRect.new()
		image.custom_minimum_size = Vector2(260,225)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var review = visual.resource_path.get_base_dir().path_join("review.png")
		image.texture = load(review) if ResourceLoader.exists(review) else visual.photo
		box.add_child(image)
		var label = Label.new()
		label.text = visual.title
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color",Color("181820"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
		tile.pressed.connect(open_card.bind(visual,tile))
		grid.add_child(tile)
	if grid.get_child_count() == 0:
		var empty = Label.new()
		empty.text = "暂无闪卡"
		grid.add_child(empty)

func open_card(visual: Resource, source: Button) -> void:
	close_card(false)
	selected_button = source
	scroll.hide()
	detail_panel = Control.new()
	add_child(detail_panel)
	detail_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_card = CardView.new()
	active_card.visual = visual
	active_card.position = Vector2(180,0)
	active_card.size = Vector2(544,476)
	detail_panel.add_child(active_card)
	var info = VBoxContainer.new()
	info.position = Vector2(770,18)
	info.size = Vector2(390,440)
	info.add_theme_font_size_override("font_size",18)
	info.add_theme_constant_override("separation",12)
	detail_panel.add_child(info)
	for text in [visual.title,visual.subtitle,visual.caption,visual.edition,"移动鼠标或拖动卡片改变角度\n方向键倾斜 · Esc 返回列表"]:
		var label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(label)
	for item in [["照片光",active_card.set_photo_effects_enabled],["框流光",active_card.set_frame_effects_enabled],["静态",active_card.set_reduced_motion]]:
		var toggle = CheckButton.new()
		toggle.text = item[0]
		toggle.button_pressed = item[0] != "静态"
		toggle.toggled.connect(item[1])
		info.add_child(toggle)
	var reset = Button.new()
	reset.text = "复位"
	reset.pressed.connect(active_card.reset_view)
	info.add_child(reset)
	var back = Button.new()
	back.text = "返回列表"
	back.pressed.connect(close_card)
	info.add_child(back)
	active_card.grab_focus()

func close_card(restore_focus := true) -> bool:
	if not is_instance_valid(detail_panel): return false
	remove_child(detail_panel)
	detail_panel.queue_free()
	detail_panel = null
	active_card = null
	scroll.show()
	if restore_focus and is_instance_valid(selected_button): selected_button.grab_focus()
	return true
