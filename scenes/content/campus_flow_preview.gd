extends Control
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
const Rules = preload("res://game/run/campus_flow_rules.gd")
const Map = preload("res://scenes/content/campus_flow_preview_map.gd")
var selector: OptionButton
var overview: VBoxContainer
var stages_scroll: ScrollContainer
var status: Label
var detail: Label
var board: Control
var flow: Dictionary = {}
func _ready() -> void:
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	var background := ColorRect.new()
	background.color = Color("102231")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,22)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",22)
	margin.add_child(row)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 350
	side.add_theme_constant_override("separation",14)
	row.add_child(side)
	_label(side,"区域流程预览",28)
	_label(side,"同一份区域配置 · 不读写玩家存档",16)
	selector = OptionButton.new()
	for region in Rules.REGIONS: selector.add_item(Catalog.snapshot(region).get("title",region))
	selector.item_selected.connect(func(index): load_region(Rules.REGIONS[index]))
	side.add_child(selector)
	var refresh := Button.new()
	refresh.text = "刷新配置"
	refresh.pressed.connect(func(): load_region(Rules.REGIONS[selector.selected]))
	side.add_child(refresh)
	status = _label(side,"",17)
	detail = _label(side,"点击站点查看已有内容引用",17)
	stages_scroll = ScrollContainer.new()
	stages_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stages_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(stages_scroll)
	overview = VBoxContainer.new()
	overview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview.add_theme_constant_override("separation",7)
	stages_scroll.add_child(overview)
	_label(side,"配置资源：\nresources/campaign/regions/\n\n数组 Stages 决定站次；\n同站 Choices 构成分支。",16)
	board = Map.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(board)
	board.place_picked.connect(inspect_stop)
	var selected: Variant = null
	if FileAccess.file_exists("res://.godot/campus-flow-preview.json"):
		selected = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/campus-flow-preview.json"))
	if selected is Dictionary and Rules.validate_snapshot(selected,str(selected.get("region",""))).is_empty():
		set_flow(selected,"检查器预览（包含未保存修改）")
	else:
		load_region("library")
	if "--flow-preview-check" in OS.get_cmdline_user_args():
		await preload("res://scenes/content/campus_flow_check.gd").new().run(self)
func _label(parent: Node, value: String, pixels: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_color_override("font_color",Color("e8f3f6"))
	parent.add_child(label)
	return label
func load_region(region: String) -> void:
	var resource = ResourceLoader.load(Catalog.PATHS[region],"",ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	var errors: Array[String] = resource.validate() if resource is CampusRegionFlow else ["区域资源无法读取"]
	if not errors.is_empty():
		status.text = "配置无效：\n"+"\n".join(errors)
		status.modulate = Color("ffb295")
		flow = {}
		board.flow = {}
		board.queue_redraw()
		_clear_stages()
		detail.text = "请修正配置后刷新"
		return
	set_flow(resource.snapshot(),"已保存配置 · 校验通过")
func set_flow(value: Dictionary, label: String) -> void:
	flow = value.duplicate(true)
	selector.select(Rules.REGIONS.find(flow.region))
	status.text = label+" · %d 站" % flow.layers.size()
	status.modulate = Color("94dab4")
	_clear_stages()
	for i in range(flow.layers.size()):
		_label(overview,"第 %d 站%s" % [i+1," · 终点" if i == flow.layers.size()-1 else ""],20)
		for id in flow.layers[i]:
			var choice := Button.new()
			choice.text = flow.stops[id].title
			choice.tooltip_text = "站点："+id
			choice.set_meta("stop_id",id)
			choice.pressed.connect(inspect_stop.bind(id))
			overview.add_child(choice)
	board.flow = flow
	board.selected_place = ""
	board.queue_redraw()
	detail.text = "点击清单或地图站点，查看敌阵、强度与热点模板"
func _clear_stages() -> void:
	for child in overview.get_children():
		overview.remove_child(child)
		child.queue_free()
func inspect_stop(id: String) -> void:
	if not flow.stops.has(id): return
	var stop: Dictionary = flow.stops[id]
	detail.text = "%s · %s\n敌阵：%s\n强度：%.2f\n热点模板：%s" % [stop.title,id,stop.encounter_id,stop.power,stop.hotspot_template]
	board.selected_place = id
	board.queue_redraw()
