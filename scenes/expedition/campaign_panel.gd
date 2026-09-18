extends PanelContainer
## Shared native controls for route, visits, narrative and memory pages.
signal action(id: String)
const ExplorationBoard = preload("res://scenes/expedition/exploration_board.gd")
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
const LIBRARY_ENVIRONMENT_STATE := "anomaly"
const LIBRARY_ENVIRONMENT_VIEWPOINT := "atrium-down"
var column: VBoxContainer
var palette: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).daily
var anomaly: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json")).anomaly
var exploration_stage: Control
var exploration_board: Control
var exploration_popup: PanelContainer
var exploration_popup_box: VBoxContainer
var exploration_detail_index := -1

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
	_clear_column()
	text(title,32)
	text(detail,21)

func _clear_column() -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	exploration_stage = null
	exploration_board = null
	exploration_popup = null
	exploration_popup_box = null
	exploration_detail_index = -1

func text(value: String, font_size: int = 22, parent: Control = null) -> void:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color(palette.text_primary))
	(column if parent == null else parent).add_child(label)

func button(label: String, id: String, enabled: bool = true, parent: Control = null) -> void:
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
	(column if parent == null else parent).add_child(item)

func row() -> HBoxContainer:
	var result = HBoxContainer.new()
	result.add_theme_constant_override("separation",18)
	column.add_child(result)
	return result

func home(progress, chosen_supply: bool) -> void:
	clear("校园修复站","你是这座虚拟校园的管理员。前代系统正在回滚新建内容；收回三台记忆终端，才能修正它的指令。")
	if progress.load_blocked:
		text(progress.error_message)
		return
	terminal_progress(progress.campaign.terminals)
	var primary = _detail_box()
	text("当前目标 · "+progress.Campaign.objective(progress.campaign),26,primary)
	if not progress.active_run.is_empty():
		text("有一段尚未结束的探索。继续会回到已保存的地点或战前。",19,primary)
		button("继续探索","continue",true,primary)
	if not progress.campaign.prologue_done:
		text("先带四名同学突破校门封锁，学习部署与领奖。",19,primary)
		button("前往校门","prologue",true,primary)
	elif not progress.campaign.routes_acquired:
		text("封锁已解除。让档案员取回三条路线：立即完成，不消耗资源。",19,primary)
		button("取回路线","tutorial",true,primary)
	else:
		text("选择目的地 · 推荐从图书馆开始",23)
		var routes = row()
		for region in ["library","region_b","region_c"]:
			button({"library":"图书馆","region_b":"第二终端","region_c":"第三终端"}[region],"region:"+region,true,routes)
	if progress.campaign.terminals.size() == 3 and not progress.campaign.restored: button("接入终端","finale")
	if progress.campaign.restored:
		text("校园已恢复。你可以重访各地，或重看结尾。")
		button("重看结尾","ending")
	text("修复资源 %d · 校园后勤" % progress.points,21)
	var secondary = row()
	button("回忆档案","memories",true,secondary)
	button("校园成长","growth",true,secondary)
	button("普通派遣","dispatch",true,secondary)
	if progress.supply_unlocked:
		text("出发补给："+("携带厚笔记本" if chosen_supply else "未携带"),19)
		button("切换补给","supply")
	button("主菜单","menu")

func terminal_progress(terminals: Array) -> void:
	var strip = row()
	for region in ["library","region_b","region_c"]:
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style = StyleBoxFlat.new()
		style.bg_color = Color("DCEFEA") if terminals.has(region) else Color(palette.surface_blue)
		style.border_color = Color("3D8F78") if terminals.has(region) else Color("AEC6D0")
		style.set_border_width_all(2)
		style.set_content_margin_all(18)
		panel.add_theme_stylebox_override("panel",style)
		strip.add_child(panel)
		text({"library":"图书馆终端","region_b":"第二终端","region_c":"第三终端"}[region]+("\n已回收 · 区域稳定" if terminals.has(region) else "\n未回收 · 通路受阻"),22,panel)

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
	for state in ["normal","hover","pressed","disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = texture
		box.set_content_margin_all(8)
		if state == "pressed": box.modulate_color = Color(0.65,0.75,0.8)
		elif state == "disabled": box.modulate_color = Color(0.35,0.43,0.48,0.55)
		item.add_theme_stylebox_override(state,box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("d0faff")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(5)
	item.add_theme_stylebox_override("focus",focus)
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		item.add_theme_color_override(color_name,Color("102333"))
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
