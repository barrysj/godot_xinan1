extends PanelContainer
## Shared native controls for route, visits, narrative and memory pages.
signal action(id: String)
var column: VBoxContainer
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).daily

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = StyleBoxFlat.new()
	background.bg_color = Color(palette.background)
	add_theme_stylebox_override("panel",background)
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	var margin = MarginContainer.new()
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,36)
	add_child(margin)
	var scroll = ScrollContainer.new()
	margin.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",18)
	scroll.add_child(column)

func clear(title: String, detail: String) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	text(title,32)
	text(detail,21)

func text(value: String, font_size: int = 22) -> void:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color(palette.text_primary))
	column.add_child(label)

func button(label: String, id: String, enabled: bool = true) -> void:
	var item = Button.new()
	item.text = label
	item.custom_minimum_size.y = 58
	item.add_theme_font_size_override("font_size",24)
	item.disabled = not enabled
	item.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	item.custom_minimum_size.x = 320
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(palette.surface_blue if state in ["hover","pressed"] else palette.surface)
		style.border_color = Color(palette.accent_primary if enabled else palette.text_secondary)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		item.add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		item.add_theme_color_override(state,Color(palette.text_primary))
	item.add_theme_color_override("font_disabled_color",Color(palette.text_secondary))
	item.pressed.connect(func(): action.emit(id))
	column.add_child(item)

func route(journey) -> void:
	clear(journey.Regions.NAMES[journey.data.region],"逻辑地图占位 · 空间关系待真实校园图核对\n单向路线，每层选择一处；本局内容等级 %d" % journey.data.level)
	for i in range(journey.data.map.size()):
		var names = []
		for place in journey.data.map[i]: names.append(journey.Regions.PLACES[place])
		text(("→ " if i == journey.data.step else "   ")+" / ".join(names),24)
	for i in range(journey.data.map[journey.data.step].size()):
		var place = journey.data.map[journey.data.step][i]
		button(journey.Regions.PLACES[place].split("〔")[0],"enter:"+str(i))
	button("返回基地","base")

func location(journey) -> void:
	var visit: Dictionary = journey.visit.data
	clear(journey.Regions.PLACES[visit.place],"静态场景占位 · 照片与回忆完全可选。守卫战胜利后可继续调查，再主动离开。")
	if visit.place == "library":
		text("LIBRARY / 记忆阅览室",28)
		var placeholder = PanelContainer.new()
		placeholder.custom_minimum_size.y = 150
		var surface = StyleBoxFlat.new()
		surface.bg_color = Color(palette.surface_blue)
		surface.border_color = Color(palette.accent_primary)
		surface.set_border_width_all(2)
		placeholder.add_theme_stylebox_override("panel",surface)
		var caption = Label.new()
		caption.text = "图书馆静态环境 · 待概念与资产批准\n真实照片保留原图，点击查看；不会要求读完才能离开。"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color",Color(palette.text_primary))
		caption.add_theme_font_size_override("font_size",22)
		placeholder.add_child(caption)
		column.add_child(placeholder)
		var memory = preload("res://resources/content/library_memory.tres")
		text(memory.title+" · "+memory.source_note,18)
	for spot in visit.hotspots:
		var labels = {"battle":"挑战守卫","memory":"查看回忆","person":"人物事件","system":"系统线索"}
		var done: bool = visit.guard_won if spot.kind == "battle" else visit.viewed.has(spot.id)
		text(labels[spot.kind]+(" · 已完成" if done else " · 可调查"),19)
		if visit.place == "library" and spot.kind == "memory" and preload("res://resources/content/library_memory.tres").photograph != null:
			button("查看原照","photo")
		else: button(labels[spot.kind],"spot:"+spot.id,not (spot.kind == "battle" and done))
	button("离开地点","leave",journey.visit.can_leave())
	button("返回基地","base")

func photograph(memory, enlarged: bool = false, back: String = "visit") -> void:
	clear(memory.title,memory.description+"\n来源："+memory.source_note)
	if memory.photograph != null:
		var picture = TextureRect.new()
		picture.texture = memory.photograph
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size.y = 1080 if enlarged else 540
		column.add_child(picture)
		button("缩小原照" if enlarged else "放大原照","photo_fit" if enlarged else "photo_zoom")
	button("返回档案" if back == "memories" else "返回地点",back)
