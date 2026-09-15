extends PanelContainer
## Shared native controls for route, visits, narrative and memory pages.
signal action(id: String)
var column: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = StyleBoxFlat.new()
	background.bg_color = Color("181820")
	add_theme_stylebox_override("panel",background)
	add_theme_font_override("font",preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
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
	column.add_child(label)

func button(label: String, id: String, enabled: bool = true) -> void:
	var item = Button.new()
	item.text = label
	item.custom_minimum_size.y = 58
	item.add_theme_font_size_override("font_size",24)
	item.disabled = not enabled
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
	for spot in visit.hotspots:
		var labels = {"battle":"挑战守卫","memory":"查看回忆","person":"人物事件","system":"系统线索"}
		var done: bool = visit.guard_won if spot.kind == "battle" else visit.viewed.has(spot.id)
		text(labels[spot.kind]+(" · 已完成" if done else " · 可调查"),19)
		button(labels[spot.kind],"spot:"+spot.id,not (spot.kind == "battle" and done))
	button("离开地点","leave",journey.visit.can_leave())
	button("返回基地","base")
