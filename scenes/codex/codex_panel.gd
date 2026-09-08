extends Control
signal closed
const Catalog = preload("res://game/codex/codex_catalog.gd")
var content: Control
var listing: VBoxContainer
var detail: RichTextLabel
var heading: Label
var category = 0
var selected_entry = 0
var tabs: Array[Button] = []
var exit_button: Button
var portrait: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	z_index = 100
	var theme_resource = Theme.new()
	theme_resource.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	theme_resource.default_font_size = 22
	for state in ["normal","hover","pressed","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("fff9ee") if state == "normal" else Color("ef7184")
		style.border_color = Color("181820")
		style.set_border_width_all(3)
		style.skew = Vector2(-0.06,0)
		theme_resource.set_stylebox(state,"Button",style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		theme_resource.set_color(state,"Button",Color("181820"))
	theme = theme_resource
	var background = preload("res://scenes/ui/comic_backdrop.gd").new()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = Control.new()
	add_child(content)
	var title = Label.new()
	title.text = "校园图鉴"
	title.position = Vector2(40,24)
	title.add_theme_font_size_override("font_size",32)
	content.add_child(title)
	var subtitle = Label.new()
	subtitle.text = "认识同伴与校园异变 · 当前版本全部条目开放查阅"
	subtitle.position = Vector2(42,72)
	subtitle.add_theme_font_size_override("font_size",18)
	content.add_child(subtitle)
	exit_button = button("返回",close_guide)
	exit_button.position = Vector2(1075,32)
	exit_button.size = Vector2(160,52)
	content.add_child(exit_button)
	for i in range(5):
		var tab = button(Catalog.CATEGORIES[i],select_category.bind(i))
		tab.position = Vector2(40+i*242,117)
		tab.size = Vector2(230,54)
		tab.toggle_mode = true
		content.add_child(tab)
		tabs.append(tab)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(40,193)
	scroll.size = Vector2(350,476)
	content.add_child(scroll)
	listing = VBoxContainer.new()
	listing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listing.add_theme_constant_override("separation",10)
	scroll.add_child(listing)
	var panel = ColorRect.new()
	panel.color = Color("fff9ee")
	panel.position = Vector2(412,193)
	panel.size = Vector2(828,476)
	content.add_child(panel)
	heading = Label.new()
	heading.position = Vector2(440,214)
	heading.size = Vector2(760,51)
	heading.add_theme_color_override("font_color",Color("181820"))
	heading.add_theme_font_size_override("font_size",30)
	content.add_child(heading)
	portrait = TextureRect.new()
	portrait.position = Vector2(1137,205)
	portrait.size = Vector2(64,64)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	content.add_child(portrait)
	detail = RichTextLabel.new()
	detail.position = Vector2(442,281)
	detail.size = Vector2(766,360)
	detail.add_theme_color_override("default_color",Color("181820"))
	content.add_child(detail)
	resized.connect(layout)
	layout()
	select_category(0)
	exit_button.grab_focus()

func button(text_value: String, action: Callable) -> Button:
	var item = Button.new()
	item.text = text_value
	item.custom_minimum_size = Vector2(0,54)
	item.pressed.connect(action)
	return item

func layout() -> void:
	var factor = minf(size.x/1280.0,size.y/720.0)
	content.scale = Vector2.ONE*factor
	content.position = (size-Vector2(1280,720)*factor)/2

func select_category(index: int) -> void:
	category = index
	for i in range(tabs.size()): tabs[i].button_pressed = i == index
	for child in listing.get_children():
		listing.remove_child(child)
		child.queue_free()
	var entries = Catalog.entries(index)
	for i in range(entries.size()):
		var item = button(entries[i].name,select_entry.bind(i))
		item.toggle_mode = true
		listing.add_child(item)
	select_entry(0)

func select_entry(index: int) -> void:
	selected_entry = index
	var entry: Dictionary = Catalog.entries(category)[index]
	heading.text = entry.name
	portrait.visible = entry.has("icon")
	if portrait.visible:
		var cells = [Vector2i(1,8),Vector2i(3,7),Vector2i(0,7),Vector2i(2,7),Vector2i(3,8)]
		if category == 1: cells = [Vector2i(4,7),Vector2i(0,9),Vector2i(1,9),Vector2i(4,8),Vector2i(4,9)]
		var atlas = AtlasTexture.new()
		atlas.atlas = preload("res://assets/pixel/kenney/tiny-dungeon.png")
		atlas.region = Rect2(Vector2(cells[entry.icon])*16,Vector2(16,16))
		portrait.texture = atlas
	if entry.get("texture") != null:
		portrait.visible = true
		portrait.texture = entry.texture
	detail.text = entry.tag + "\n\n" + entry.body
	detail.scroll_to_line(0)
	for i in range(listing.get_child_count()): listing.get_child(i).button_pressed = i == index

func close_guide() -> void:
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ggt_debug_pause_game"):
		if event is InputEventKey and event.echo: return
		get_viewport().set_input_as_handled()
		close_guide()
