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
