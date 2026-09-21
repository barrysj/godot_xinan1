extends PanelContainer
## Shared native controls for route, visits, narrative and memory pages.
signal action(id: String)
const MEMORY_TERMINAL_VIEW = preload("res://scenes/expedition/memory_terminal_view.gd")
const ExplorationBoard = preload("res://scenes/expedition/exploration_board.gd")
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
const Journey = preload("res://game/run/campaign_journey.gd")
const CampusUi = preload("res://scenes/ui/campus_ui.gd")
const HUB_ICON_PATHS := {
	"codex": "res://assets/art/ui/m1_campus_hub/runtime/icon_codex.png",
	"dispatch": "res://assets/art/ui/m1_campus_hub/runtime/icon_dispatch.png",
	"growth": "res://assets/art/ui/m1_campus_hub/runtime/icon_growth.png",
	"memory": "res://assets/art/ui/m1_campus_hub/runtime/icon_memory.png",
	"resource": "res://assets/art/ui/m1_campus_hub/runtime/icon_resource.png",
}
const LIBRARY_ENVIRONMENT_STATE := "anomaly"
const LIBRARY_ENVIRONMENT_VIEWPOINT := "atrium-down"
var column: VBoxContainer
var page_margin: MarginContainer
var page_scroll: ScrollContainer
var home_root: Control
var home_overlay: Control
var home_return_focus: Control
var default_parent: Control
var hub_icon_textures: Dictionary = {}
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).daily
var anomaly: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).anomaly
var exploration_stage: Control
var exploration_board: Control
var exploration_popup: PanelContainer
var exploration_popup_box: VBoxContainer
var exploration_detail_index := -1
var environment_preview_board: Control
var environment_preview_status: Label
var environment_preview_state := "anomaly"
var environment_preview_viewpoint := "atrium-down"
var environment_preview_state_buttons: Array[Button] = []
var environment_preview_viewpoint_buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = StyleBoxFlat.new()
	background.bg_color = Color(palette.background)
	add_theme_stylebox_override("panel",background)
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	page_margin = MarginContainer.new()
	page_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]: page_margin.add_theme_constant_override("margin_"+side,32)
	add_child(page_margin)
	page_scroll = ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_margin.add_child(page_scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",18)
	page_scroll.add_child(column)
	default_parent = column
	home_root = Control.new()
	home_root.name = "HomeRoot"
	home_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_root.hide()
	add_child(home_root)

func clear(title: String, detail: String) -> void:
	_show_standard_page()
	_clear_column()
	text(title,32)
	text(detail,21)

func _show_standard_page() -> void:
	close_home_overlay(false)
	home_root.hide()
	page_margin.show()
	default_parent = column

func _show_home_page() -> void:
	close_home_overlay(false)
	page_margin.hide()
	home_root.show()
	default_parent = home_root
	for child in home_root.get_children():
		home_root.remove_child(child)
		child.queue_free()

func _clear_column() -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	exploration_stage = null
	exploration_board = null
	exploration_popup = null
	exploration_popup_box = null
	exploration_detail_index = -1
	environment_preview_board = null
	environment_preview_status = null
	environment_preview_state_buttons.clear()
	environment_preview_viewpoint_buttons.clear()

func text(value: String, font_size: int = 22, parent: Control = null) -> void:
	var label := CampusUi.label(value,font_size,"night" if home_root.visible else "daily")
	(default_parent if parent == null else parent).add_child(label)

func button(label: String, id: String, enabled: bool = true, parent: Control = null) -> Button:
	var item = Button.new()
	item.text = label
	item.set_meta("action_id",id)
	item.custom_minimum_size.y = 58
	item.add_theme_font_size_override("font_size",24)
	item.disabled = not enabled
	item.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	item.custom_minimum_size.x = 320
	CampusUi.apply_button(item,"daily")
	if is_instance_valid(home_root) and home_root.visible:
		_apply_home_button(item)
	item.pressed.connect(func(): action.emit(id))
	(default_parent if parent == null else parent).add_child(item)
	return item

func _hub_icon(id: String) -> Texture2D:
	if hub_icon_textures.has(id): return hub_icon_textures[id]
	var path: String = HUB_ICON_PATHS.get(id, "")
	if path.is_empty(): return null
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			hub_icon_textures[id] = imported
			return imported
	var bytes := FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	if bytes.is_empty() or image.load_png_from_buffer(bytes) != OK:
		push_warning("基地图标读取失败：" + path)
		return null
	var texture := ImageTexture.create_from_image(image)
	hub_icon_textures[id] = texture
	return texture

func _home_surface() -> StyleBoxFlat:
	return CampusUi.hub_surface()

func _apply_home_button(item: Button) -> void:
	CampusUi.apply_hub_button(item)

func _home_icon_button(label: String, id: String, icon_id: String, parent: Control) -> Button:
	var item := button(label,id,true,parent)
	item.custom_minimum_size = Vector2(116,116)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_theme_font_size_override("font_size",21)
	item.icon = _hub_icon(icon_id)
	item.set_meta("icon_asset_path",HUB_ICON_PATHS.get(icon_id,""))
	item.expand_icon = true
	item.add_theme_constant_override("icon_max_width",36)
	item.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	item.alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.add_theme_constant_override("icon_separation",14)
	_apply_home_button(item)
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		item.add_theme_color_override(color_name,Color("F6F8FA"))
	return item

func _resource_status(points: int) -> void:
	var panel := PanelContainer.new()
	panel.name = "ResourceStatus"
	panel.custom_minimum_size = Vector2(230,58)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := _home_surface()
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel",style)
	default_parent.add_child(panel)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation",12)
	panel.add_child(status_row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(36,36)
	icon.texture = _hub_icon("resource")
	icon.set_meta("icon_asset_path",HUB_ICON_PATHS.resource)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(icon)
	var label := Label.new()
	label.text = "修复资源 %d" % points
	label.add_theme_font_size_override("font_size",20)
	label.add_theme_color_override("font_color",Color("F6F8FA"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_row.add_child(label)

func action_button(id: String) -> Button:
	for candidate in find_children("*","Button",true,false):
		if candidate.get_meta("action_id","") == id:
			return candidate as Button
	return null

func row() -> HBoxContainer:
	var result = HBoxContainer.new()
	result.add_theme_constant_override("separation",18)
	default_parent.add_child(result)
	return result

func home(progress, chosen_supply: bool) -> void:
	_show_home_page()
	var backdrop := TextureRect.new()
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes("res://design/concepts/m1-campus-hub-ui/m1_campus_hub_ui/014/lecture-hall.png")
	if image.load_png_from_buffer(bytes) == OK:
		backdrop.texture = ImageTexture.create_from_image(image)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_root.add_child(backdrop)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]: safe.add_theme_constant_override("margin_"+side,32)
	home_root.add_child(safe)
	var page := VBoxContainer.new()
	safe.add_child(page)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",16)
	page.add_child(top)
	var location := _floating_card(top)
	location.get_parent().custom_minimum_size.x = 240
	location.add_theme_constant_override("separation",4)
	location.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	text("校园修复站",26,location)
	text("阶梯教室",18,location)
	var top_space := Control.new()
	top_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_space)
	default_parent = top
	_resource_status(progress.points)
	top.get_child(top.get_child_count()-1).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var menu := button("菜单","hub_menu",true,top)
	menu.custom_minimum_size = Vector2(100,58)
	menu.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(space)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation",24)
	page.add_child(bottom)
	var mission := _floating_card(bottom)
	mission.get_parent().custom_minimum_size.x = 440
	mission.get_parent().name = "HomeMission"
	text("当前目标",18,mission)
	text(progress.Campaign.objective(progress.campaign).split(" · ")[0],26,mission)
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation",18)
	mission.add_child(progress_row)
	text("记忆终端 %d / 3" % progress.campaign.terminals.size(),18,progress_row)
	var indicators := ""
	for i in range(3): indicators += "●  " if i < progress.campaign.terminals.size() else "○  "
	text(indicators,18,progress_row)
	for label in progress_row.get_children(): label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if progress.load_blocked:
		text(progress.error_message,18,mission)
	elif not progress.active_run.is_empty():
		button("继续探索","continue",true,mission)
	elif not progress.campaign.prologue_done:
		button("前往校门","prologue",true,mission)
	elif not progress.campaign.routes_acquired:
		button("取回路线","tutorial",true,mission)
	elif progress.campaign.terminals.size() == 3 and not progress.campaign.restored:
		button("接入终端","finale",true,mission)
	else:
		var explore := button("探索","choose_region",true,mission)
		explore.pressed.connect(func(): _home_routes(progress))
	if not progress.active_run.is_empty() and progress.campaign.routes_acquired:
		var choose := button("选择区域","choose_region",true,mission)
		choose.pressed.connect(func(): _home_routes(progress))
	if progress.campaign.restored: button("重看结尾","ending",true,mission)
	if progress.supply_unlocked:
		text("补给："+("厚笔记本" if chosen_supply else "未携带"),17,mission)
		button("切换补给","supply",true,mission)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(gap)
	var utilities := VBoxContainer.new()
	utilities.size_flags_vertical = Control.SIZE_SHRINK_END
	utilities.add_theme_constant_override("separation",12)
	bottom.add_child(utilities)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	utilities.add_child(grid)
	for entry in [["成长","growth","growth"],["派遣","dispatch","dispatch"],["回忆","memories","memory"],["图鉴","codex","codex"]]:
		var item := _home_icon_button(entry[0],entry[1],entry[2],grid)
		item.custom_minimum_size = Vector2(116,116)
		_apply_home_button(item)
	default_parent = utilities
	var primary: Button = mission.find_children("*","Button",true,false)[0] if not mission.find_children("*","Button",true,false).is_empty() else menu
	if primary != menu:
		CampusUi.apply_hub_button(primary,true)
		primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_focus_home_action.call_deferred(primary)

func _focus_home_action(item: Button) -> void:
	if is_instance_valid(item) and item.is_inside_tree() and item.is_visible_in_tree():
		item.grab_focus()

func _floating_card(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var style := _home_surface()
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	panel.add_child(box)
	return box

func _home_routes(progress) -> void:
	var box := _home_dialog("选择区域")
	for region in ["library","region_b","region_c"]:
		button({"library":"图书馆","region_b":"第二终端","region_c":"第三终端"}[region],"region:"+region,true,box)
	var back := button("返回基地","hub_close",true,box)
	back.pressed.connect(close_home_overlay)
	_focus_home_action.call_deferred(box.get_child(1))

func show_home_menu() -> void:
	var box := _home_dialog("基地菜单")
	var back := button("返回基地","hub_close",true,box)
	back.pressed.connect(close_home_overlay)
	button("主菜单","menu",true,box)
	var reset := button("重开存档","reset_profile",true,box)
	reset.add_theme_color_override("font_color",Color(CampusUi.colors("semantic").danger))
	reset.tooltip_text = "备份旧档后重新开始，下一步需要确认。"
	_focus_home_action.call_deferred(back)

func show_home_reset_confirmation(error_message: String = "") -> void:
	var box := _home_dialog("重开存档")
	box.get_parent().custom_minimum_size.x = 460
	text("将清空主线、角色解锁、回忆、资源、成长、派遣和当前探索。设置保留。确认后先备份旧档，再从序章开始。",20,box)
	if not error_message.is_empty(): text(error_message,18,box)
	var cancel := button("取消","reset_cancel",true,box)
	var confirm := button("确认重开","reset_confirm",true,box)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		confirm.add_theme_color_override(state,Color(CampusUi.colors("semantic").danger))
	_focus_home_action.call_deferred(cancel)

func _home_dialog(title: String) -> VBoxContainer:
	close_home_overlay(false)
	home_return_focus = get_viewport().gui_get_focus_owner()
	for item in home_root.find_children("*","Button",true,false): item.focus_mode = Control.FOCUS_NONE
	home_overlay = ColorRect.new()
	home_overlay.name = "HomeOverlay"
	home_overlay.color = Color(0,0,0,0.35)
	home_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_root.add_child(home_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_overlay.add_child(center)
	var box := _floating_card(center)
	text(title,26,box)
	return box

func close_home_overlay(restore_focus: bool = true) -> void:
	if not is_instance_valid(home_overlay): return
	home_overlay.get_parent().remove_child(home_overlay)
	home_overlay.queue_free()
	home_overlay = null
	for item in home_root.find_children("*","Button",true,false): item.focus_mode = Control.FOCUS_ALL
	if restore_focus and is_instance_valid(home_return_focus): _focus_home_action.call_deferred(home_return_focus)

func _legacy_home_layout(progress, chosen_supply: bool) -> void:
	_show_home_page()
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]: safe.add_theme_constant_override("margin_"+side,32)
	home_root.add_child(safe)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation",20)
	safe.add_child(page)
	var header := PanelContainer.new()
	CampusUi.apply_panel(header,"daily","quiet")
	header.custom_minimum_size.y = 86
	page.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation",20)
	header.add_child(header_row)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(heading)
	heading.add_child(CampusUi.label("校园修复站",32,"daily"))
	heading.add_child(CampusUi.label("阶梯教室据点 · 当前 AI 值班中",17,"daily",true))
	var objective_chip := PanelContainer.new()
	CampusUi.apply_panel(objective_chip,"daily","strong")
	objective_chip.custom_minimum_size = Vector2(440,0)
	header_row.add_child(objective_chip)
	var objective_label := CampusUi.label(progress.Campaign.objective(progress.campaign),19,"daily")
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_chip.add_child(objective_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",20)
	page.add_child(body)
	var mission := _home_card(body,"探索任务",Vector2(372,0))
	var stage := _home_stage(body,progress)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var facilities := _home_card(body,"基地功能",Vector2(372,0))
	default_parent = facilities
	if progress.load_blocked:
		text(progress.error_message,18,mission)
		return
	text("当前目标",18,mission)
	text(progress.Campaign.objective(progress.campaign),23,mission)
	if not progress.active_run.is_empty():
		text("已有探索进度，可从保存的地点或战前继续。",17,mission)
		button("继续探索","continue",true,mission)
	if not progress.campaign.prologue_done:
		text("先突破校门封锁，完成部署与领奖教学。",17,mission)
		button("前往校门","prologue",true,mission)
	elif not progress.campaign.routes_acquired:
		text("封锁已解除，取回校园路线资料。",17,mission)
		button("取回路线","tutorial",true,mission)
	else:
		text("选择目的地",18,mission)
		var routes := VBoxContainer.new()
		routes.add_theme_constant_override("separation",10)
		mission.add_child(routes)
		for region in ["library","region_b","region_c"]:
			var route_button := button({"library":"图书馆","region_b":"第二终端","region_c":"第三终端"}[region],"region:"+region,true,routes)
			route_button.custom_minimum_size.x = 0
			route_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if progress.campaign.terminals.size() == 3 and not progress.campaign.restored: button("接入终端","finale",true,mission)
	if progress.campaign.restored:
		text("校园已恢复，可重访各地。",17,mission)
		button("重看结尾","ending",true,mission)
	default_parent = facilities
	_resource_status(progress.points)
	var secondary := GridContainer.new()
	secondary.columns = 2
	secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secondary.add_theme_constant_override("h_separation",10)
	secondary.add_theme_constant_override("v_separation",10)
	facilities.add_child(secondary)
	_home_icon_button("回忆","memories","memory",secondary)
	_home_icon_button("成长","growth","growth",secondary)
	_home_icon_button("派遣","dispatch","dispatch",secondary)
	_home_icon_button("图鉴","codex","codex",secondary)
	if progress.supply_unlocked:
		text("出发补给 · "+("厚笔记本" if chosen_supply else "未携带"),17,facilities)
		var supply_button := button("切换补给","supply",true,facilities)
		supply_button.custom_minimum_size.x = 0
		supply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var menu_button := button("主菜单","menu",true,facilities)
	menu_button.custom_minimum_size.x = 0
	menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_focus_first_home_action.call_deferred()

func _home_card(parent: Control, title: String, minimum: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	CampusUi.apply_panel(panel,"daily")
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	panel.add_child(box)
	box.add_child(CampusUi.label(title,25,"daily"))
	return box

func _home_stage(parent: Control, progress) -> PanelContainer:
	var stage := PanelContainer.new()
	stage.name = "CampusStage"
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	CampusUi.apply_panel(stage,"daily","quiet")
	parent.add_child(stage)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation",16)
	stage.add_child(content)
	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer_top)
	var ai_status := PanelContainer.new()
	CampusUi.apply_panel(ai_status,"daily","strong")
	ai_status.custom_minimum_size = Vector2(0,76)
	ai_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(ai_status)
	var ai_row := HBoxContainer.new()
	ai_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ai_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_row.add_theme_constant_override("separation",12)
	ai_status.add_child(ai_row)
	var ai_icon := TextureRect.new()
	ai_icon.texture = _hub_icon("notification")
	ai_icon.custom_minimum_size = Vector2(42,42)
	ai_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ai_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ai_row.add_child(ai_icon)
	var ai_label := CampusUi.label("当前 AI · 修复流程待命",20,"daily")
	ai_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	ai_label.custom_minimum_size.x = 240
	ai_row.add_child(ai_label)
	var terminals := HBoxContainer.new()
	terminals.add_theme_constant_override("separation",10)
	content.add_child(terminals)
	terminal_progress(progress.campaign.terminals,terminals)
	var hint := CampusUi.label("阶梯教室布景将在概念批准后替换此展示层",16,"daily",true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)
	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer_bottom)
	return stage

func _focus_first_home_action() -> void:
	if not is_instance_valid(home_root) or not home_root.visible: return
	for candidate in home_root.find_children("*","Button",true,false):
		if not candidate.disabled and candidate.visible:
			candidate.grab_focus()
			return

func terminal_progress(terminals: Array, parent: Control = null) -> void:
	var strip: HBoxContainer
	if parent == null:
		strip = row()
	else:
		strip = parent as HBoxContainer
	for region in ["library","region_b","region_c"]:
		var view = MEMORY_TERMINAL_VIEW.new()
		view.setup(region, terminals.has(region), "compact")
		strip.add_child(view)

func terminal_reveal(region: String) -> void:
	var view = MEMORY_TERMINAL_VIEW.new()
	view.setup(region, true, "reveal")
	column.add_child(view)

func terminal_finale(terminals: Array, stage: int) -> void:
	text("终端阵列", 24)
	var strip = row()
	for region in ["library","region_b","region_c"]:
		var view = MEMORY_TERMINAL_VIEW.new()
		view.setup(region, terminals.has(region), "finale", stage)
		strip.add_child(view)

func _board(journey, mode: String) -> Control:
	var board = preload("res://scenes/expedition/campaign_board.gd").new()
	board.journey = journey
	board.mode = mode
	column.add_child(board)
	return board

func _detail_box(parent: Control = null) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(palette.surface)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel",style)
	(column if parent == null else parent).add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	return box

func rewards(offers: Array) -> void:
	clear("选择一份战利品","训练立即强化对应同学；装备放入背包，下一场整备时分配。本区域有效，领奖后回到原地点。")
	var cards = row()
	var db = preload("res://game/content/content_db.gd")
	for i in range(offers.size()):
		var offer = offers[i]
		var card = _detail_box(cards)
		var picture = TextureRect.new()
		picture.custom_minimum_size = Vector2(90,100)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if offer.operation == "gear": picture.texture = db.gear(offer.target).icon
		elif offer.operation == "train": picture.texture = db.character(db.role_index(offer.target)).portrait
		card.add_child(picture)
		text(offer.title,26,card)
		text(offer.description,21,card)
		text("存入背包 · 整备时装备" if offer.operation == "gear" else "对应同学 · 立即生效",18,card)
		button("选取","reward:"+str(i),true,card)

func _empty(box: Control) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func route(journey) -> void:
	var current = "基地" if journey.data.visited.is_empty() else journey.Regions.PLACES[journey.data.visited.back()]
	clear(journey.Regions.NAMES[journey.data.region],"当前位置："+current+"。目标：前往终点，取回记忆终端。每站先突破守卫封锁，再继续前进。")
	var board = _board(journey,"route")
	var detail = _detail_box()
	board.picked.connect(func(index): _route_detail(journey,index,detail))
	_route_detail(journey,0,detail)
	button("返回基地","base")

func _route_detail(journey, index: int, detail: Control) -> void:
	_empty(detail)
	var place = journey.data.map[journey.data.step][index]
	text("下一站 · "+journey.Regions.PLACES[place],24,detail)
	text("这是终点：突破守卫后离开，即可带回终端。" if journey.data.step == 3 else "在这里击败守卫、领取奖励后，可以继续调查或离开前往下一站。",19,detail)
	button("前往","enter:"+str(index),true,detail)

func location(journey, prologue: bool = false) -> void:
	var visit: Dictionary = journey.visit.data
	if visit.place == "library":
		_library_location(journey,prologue)
		return
	var goal = "出口已开放：继续调查，或离开前往下一站。" if journey.visit.can_leave() else "当前目标：挑战守卫，领取奖励，解除出口封锁。"
	if journey.visit.can_leave() and journey.data.step == 3: goal = "终端已可回收：离开地点，将终端与同行伙伴带回基地。"
	clear(journey.Regions.PLACES[visit.place],goal)
	if journey.data.has("last_reward"): text("已获得 · "+str(journey.data.last_reward),19)
	if prologue: text("当前 AI：管理员，前代系统正在回滚我们新建的校园。先带四名同学突破校门封锁，再取回通往记忆终端的路线。",20)
	var board = _board(journey,"location")
	var detail = _detail_box()
	board.picked.connect(func(index): _spot_detail(journey,index,detail))
	_spot_detail(journey,0,detail)
	var actions = row()
	button("离开地点","leave",journey.visit.can_leave(),actions)
	button("返回基地","base",true,actions)

func library_environment_preview() -> void:
	_clear_column()
	environment_preview_state = "anomaly"
	environment_preview_viewpoint = "atrium-down"
	text("图书馆环境预览",32)
	text("只读预览，不写入存档。切换状态与视角，检查九张正式背景在探索界面中的实际效果。",19)
	var state_row := row()
	state_row.custom_minimum_size.y = 56
	_preview_group_label("状态",state_row)
	for state in ExplorationSkin.LIBRARY_ENVIRONMENT_STATES:
		var label: String = {"daily":"日常","night":"夜间","anomaly":"异变"}[state]
		environment_preview_state_buttons.append(_preview_button(label,"state:"+state,state_row))
	var viewpoint_row := row()
	viewpoint_row.custom_minimum_size.y = 56
	_preview_group_label("视角",viewpoint_row)
	for viewpoint in ExplorationSkin.LIBRARY_ENVIRONMENT_VIEWPOINTS:
		var label: String = {"atrium-down":"中庭","window-corridor":"窗边","shelf-to-atrium":"书架"}[viewpoint]
		environment_preview_viewpoint_buttons.append(_preview_button(label,"viewpoint:"+viewpoint,viewpoint_row))
	environment_preview_status = _exploration_label("",17)
	environment_preview_status.custom_minimum_size.y = 30
	environment_preview_status.add_theme_color_override("font_color",Color(palette.text_primary))
	column.add_child(environment_preview_status)
	var preview_journey := Journey.new()
	preview_journey.begin("library",3)
	preview_journey.enter(0,[])
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(820,680)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(stage)
	environment_preview_board = ExplorationBoard.new()
	environment_preview_board.journey = preview_journey
	environment_preview_board.set_environment_variant(environment_preview_state,environment_preview_viewpoint)
	environment_preview_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(environment_preview_board)
	_update_environment_preview()
	button("返回基地","base")

func _preview_group_label(label: String, parent: Control) -> void:
	var item := _exploration_label(label,18)
	item.add_theme_color_override("font_color",Color(palette.text_primary))
	item.custom_minimum_size = Vector2(64,48)
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(item)

func _preview_button(label: String, id: String, parent: Control) -> Button:
	var item := Button.new()
	item.text = label
	item.custom_minimum_size = Vector2(132,48)
	item.add_theme_font_size_override("font_size",18)
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(anomaly.background if state in ["hover","pressed"] else anomaly.surface)
		style.border_color = Color(anomaly.cyan)
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		item.add_theme_stylebox_override(state,style)
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		item.add_theme_color_override(color_name,Color(anomaly.text_primary))
	item.pressed.connect(func(): _preview_action(id))
	parent.add_child(item)
	return item

func _preview_action(id: String) -> void:
	var parts := id.split(":",false,1)
	if parts.size() != 2 or not is_instance_valid(environment_preview_board):
		return
	if parts[0] == "state": environment_preview_state = parts[1]
	elif parts[0] == "viewpoint": environment_preview_viewpoint = parts[1]
	else: return
	if environment_preview_board.set_environment_variant(environment_preview_state,environment_preview_viewpoint):
		_update_environment_preview()

func _update_environment_preview() -> void:
	if not is_instance_valid(environment_preview_status):
		return
	var state_label: String = {"daily":"日常","night":"夜间","anomaly":"异变"}[environment_preview_state]
	var viewpoint_label: String = {"atrium-down":"中庭俯视","window-corridor":"窗边走廊","shelf-to-atrium":"书架望中庭"}[environment_preview_viewpoint]
	environment_preview_status.text = "当前：" + state_label + " · " + viewpoint_label

func _library_location(journey, prologue: bool) -> void:
	_clear_column()
	exploration_stage = Control.new()
	exploration_stage.custom_minimum_size = Vector2(820, maxf(size.y - 72.0, 680.0))
	exploration_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(exploration_stage)
	exploration_board = ExplorationBoard.new()
	exploration_board.journey = journey
	assert(exploration_board.set_environment_variant(LIBRARY_ENVIRONMENT_STATE,LIBRARY_ENVIRONMENT_VIEWPOINT))
	exploration_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exploration_stage.add_child(exploration_board)
	exploration_board.picked.connect(func(index): _open_library_detail(journey,index))
	exploration_board.layout_changed.connect(_place_exploration_popup)
	if prologue:
		var prologue_hint := _exploration_label("当前 AI：先突破封锁，胜利并领奖后出口才会开放。",17)
		prologue_hint.position = Vector2(24,96)
		prologue_hint.size = Vector2(560,32)
		exploration_stage.add_child(prologue_hint)
	if journey.data.has("last_reward"):
		var reward_hint := _exploration_label("已获得 · " + str(journey.data.last_reward),17)
		reward_hint.position = Vector2(24,96)
		reward_hint.size = Vector2(720,32)
		exploration_stage.add_child(reward_hint)
	_build_exploration_popup()
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.offset_left = -444
	actions.offset_top = -70
	actions.offset_right = -20
	actions.offset_bottom = -14
	exploration_stage.add_child(actions)
	_exploration_button("离开地点","leave",journey.visit.can_leave(),actions,198)
	_exploration_button("返回基地","base",true,actions,198)
	exploration_stage.resized.connect(_place_exploration_popup)

func _build_exploration_popup() -> void:
	exploration_popup = PanelContainer.new()
	exploration_popup.custom_minimum_size = Vector2(410,230)
	var panel_style := StyleBoxTexture.new()
	panel_style.texture = ExplorationSkin.texture("res://assets/art/ui/m1_exploration_ui/panel.png")
	panel_style.texture_margin_left = 42
	panel_style.texture_margin_right = 42
	panel_style.texture_margin_top = 28
	panel_style.texture_margin_bottom = 28
	panel_style.set_content_margin_all(28)
	panel_style.content_margin_top = 42
	panel_style.content_margin_bottom = 42
	exploration_popup.add_theme_stylebox_override("panel",panel_style)
	exploration_stage.add_child(exploration_popup)
	exploration_popup_box = VBoxContainer.new()
	exploration_popup_box.add_theme_constant_override("separation",12)
	exploration_popup.add_child(exploration_popup_box)
	exploration_popup.hide()

func _open_library_detail(journey, index: int) -> void:
	if index < 0 or index >= journey.visit.data.hotspots.size():
		return
	exploration_detail_index = index
	exploration_board.set_selected(index)
	_empty(exploration_popup_box)
	var visit: Dictionary = journey.visit.data
	var spot: Dictionary = visit.hotspots[index]
	var titles = {"battle":"封锁守卫","memory":"校园记忆","person":"人物事件","system":"借阅终端"}
	var lines = {
		"battle":"守卫阻止我们继续前进。进入整备后开战；胜利并领取奖励，出口才会开放。",
		"memory":"读取这处地点的系统记录，保存到回忆档案。属于虚拟校园故事，可以跳过。",
		"person":"发明家愿意协助修复。交谈后本区域临时加入，成功完成区域后永久解锁。",
		"system":"调查前代系统仍在执行的早期目标，了解三台记忆终端的作用。"}
	var header := HBoxContainer.new()
	exploration_popup_box.add_child(header)
	var heading := _exploration_label(titles[spot.kind],25)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := Button.new()
	close.text = "×"
	close.flat = true
	close.custom_minimum_size = Vector2(44,44)
	close.tooltip_text = "关闭"
	close.add_theme_font_size_override("font_size",24)
	close.add_theme_color_override("font_color",Color(anomaly.text_primary))
	close.add_theme_color_override("font_hover_color",Color(anomaly.cyan))
	close.pressed.connect(_close_library_detail)
	header.add_child(close)
	var description: String = "封锁已经解除，奖励已领取。现在可以离开，其他调查不会阻挡出口。" if spot.kind == "battle" and visit.reward_taken else str(lines[spot.kind])
	exploration_popup_box.add_child(_exploration_label(description,19,true))
	var hint: String = "必经战斗 · 胜利后需领取奖励" if spot.kind == "battle" else "可选调查 · 不影响离场条件"
	var hint_label := _exploration_label(hint,16)
	hint_label.add_theme_color_override("font_color",Color("b7c9d7"))
	exploration_popup_box.add_child(hint_label)
	var labels = {"battle":"挑战","memory":"读取","person":"交谈","system":"调查"}
	var is_photo: bool = spot.kind == "memory" and preload("res://resources/content/library_memory.tres").photograph != null
	var action_id: String = "photo" if is_photo else "spot:" + spot.id
	var primary := _exploration_button("查看" if is_photo else labels[spot.kind],action_id,not (spot.kind == "battle" and visit.guard_won),exploration_popup_box,128)
	primary.size_flags_horizontal = Control.SIZE_SHRINK_END
	primary.focus_neighbor_top = close.get_path()
	close.focus_neighbor_bottom = primary.get_path()
	exploration_popup.show()
	exploration_popup.reset_size()
	_place_exploration_popup()
	primary.grab_focus()

func _place_exploration_popup() -> void:
	if not is_instance_valid(exploration_popup) or not exploration_popup.visible or not is_instance_valid(exploration_board):
		return
	var source: Rect2 = exploration_board.hotspot_rect(exploration_detail_index)
	if source.size == Vector2.ZERO:
		return
	var required: Vector2 = exploration_popup.get_combined_minimum_size()
	exploration_popup.size = Vector2(maxf(required.x,410),maxf(required.y,230))
	var target: Vector2 = source.position + Vector2(source.size.x + 26,-44)
	if source.get_center().x > exploration_stage.size.x * 0.64:
		target.x = source.position.x - exploration_popup.size.x - 26
	target = target.clamp(Vector2(24,96),exploration_stage.size - exploration_popup.size - Vector2(24,86))
	exploration_popup.position = target

func _close_library_detail() -> void:
	var previous := exploration_detail_index
	exploration_detail_index = -1
	if is_instance_valid(exploration_popup):
		exploration_popup.hide()
	if is_instance_valid(exploration_board):
		exploration_board.set_selected(-1)
		var previous_button: Button = exploration_board.hotspot_button(previous)
		if previous_button != null:
			previous_button.grab_focus()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(exploration_popup) or not exploration_popup.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_close_library_detail()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not exploration_popup.get_global_rect().has_point(event.position):
			_close_library_detail()

func _exploration_label(value: String, font_size: int, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color(anomaly.text_primary))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 340
	return label

func _exploration_button(label: String, id: String, enabled: bool, parent: Control, width: float) -> Button:
	var item := Button.new()
	item.text = label
	item.disabled = not enabled
	item.custom_minimum_size = Vector2(width,50)
	item.add_theme_font_size_override("font_size",20)
	var texture := ExplorationSkin.texture("res://assets/art/ui/m1_exploration_ui/button.png")
	for state in ["normal","hover","pressed","disabled","focus"]:
		var box := StyleBoxTexture.new()
		box.texture = texture
		box.texture_margin_left = 28
		box.texture_margin_right = 28
		box.texture_margin_top = 12
		box.texture_margin_bottom = 12
		box.set_content_margin_all(8)
		if state == "pressed": box.modulate_color = Color(0.65,0.75,0.8)
		elif state == "disabled": box.modulate_color = Color(0.35,0.43,0.48,0.55)
		elif state in ["hover","focus"]: box.modulate_color = Color(1.08,1.08,1.08)
		item.add_theme_stylebox_override(state,box)
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		item.add_theme_color_override(color_name,Color("f7fbff"))
	item.add_theme_color_override("font_disabled_color",Color("8999a3"))
	item.pressed.connect(func(): action.emit(id))
	parent.add_child(item)
	return item

func _spot_detail(journey, index: int, detail: Control) -> void:
	_empty(detail)
	var visit: Dictionary = journey.visit.data
	var spot = visit.hotspots[index]
	var titles = {"battle":"封锁守卫","memory":"校园系统记录","person":"发明家 · 同行伙伴","system":"记忆终端线索"}
	var lines = {
		"battle":"守卫阻止我们继续前进。进入整备，部署四名同学后开战；胜利后选择一份奖励。",
		"memory":"读取这处地点的系统记录，保存到回忆档案。属于虚拟校园故事；不影响通关，可以跳过。",
		"person":"发明家愿意协助修复。交谈后本区域临时加入，成功完成区域后永久解锁。",
		"system":"调查前代系统为何阻止修复，了解三台记忆终端的作用。可以跳过。"}
	text(titles[spot.kind],24,detail)
	text("封锁已经解除，奖励已领取。现在可以离开，其他调查不会阻挡出口。" if spot.kind == "battle" and visit.reward_taken else lines[spot.kind],19,detail)
	var labels = {"battle":"挑战守卫","memory":"读取记录","person":"交谈","system":"调查终端"}
	var is_photo: bool = visit.place == "library" and spot.kind == "memory" and preload("res://resources/content/library_memory.tres").photograph != null
	button("查看原照" if is_photo else labels[spot.kind],"photo" if is_photo else "spot:"+spot.id,not (spot.kind == "battle" and visit.guard_won),detail)

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
