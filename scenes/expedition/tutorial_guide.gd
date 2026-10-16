extends Control
## Follows real controls; never replaces their input or gameplay transactions.
var game
var target_rect := Rect2()
var step_id := ""
var hold := false
var skipped := false
var dismissed_steps := {}
var formation_dismissed := false
var departure_item_count := -1
var battle_step := 0
var initial_formation: Array = []
var battle_ref
var clock := 0.0
var card: PanelContainer
var heading: Label
var description: RichTextLabel
var target: Control
var investigated := false
var presented := false
var skip_button: Button
var focus_regions: Array[Rect2] = []
var connector := PackedVector2Array()

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 90
	theme = preload("res://resources/theme/theme-main.tres")
	card = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f5edda")
	style.border_color = Color("c69d54")
	style.set_border_width_all(1)
	style.border_width_left = 5
	style.set_corner_radius_all(8)
	for side in ["left","right","top","bottom"]: style.set("content_margin_"+side,18)
	card.add_theme_stylebox_override("panel",style)
	card.mouse_filter = MOUSE_FILTER_STOP
	add_child(card)
	var box := VBoxContainer.new()
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation",8)
	card.add_child(box)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("76501f"))
	box.add_child(heading)
	description = preload("res://scenes/ui/glossary_text.gd").make("",20,true)
	description.add_theme_font_size_override("font_size",20)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var skip := Button.new()
	skip_button = skip
	skip.text = "下一步"
	skip.size_flags_horizontal = SIZE_SHRINK_END
	for state in ["normal","hover","pressed","focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("e2c990") if state == "normal" else Color("d7b66f")
		button_style.set_corner_radius_all(5)
		button_style.set_content_margin_all(7)
		if state == "focus":
			button_style.bg_color = Color.TRANSPARENT
			button_style.border_color = Color("76501f")
			button_style.set_border_width_all(2)
		skip.add_theme_stylebox_override(state,button_style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		skip.add_theme_color_override(state,Color("46351e"))
	skip.pressed.connect(_next_step)
	box.add_child(skip)
	hide()

func _next_step() -> void:
	dismissed_steps[step_id] = true
	match step_id:
		"prep_unpack": dismissed_steps["prep_carry"] = true
		"formation", "formation_slot": formation_dismissed = true
		"pause", "resume": battle_step = 2
		"speed": battle_step = 3
		"item", "item_type", "item_use":
			battle_step = 4
			if not game.code_panel.selected_item.is_empty(): game.code_panel._select_item("")
		"hack", "hack_release":
			battle_step = 5
			game.code_panel._hide_program_preview()
	hold = false
	hide()
	update()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func point(control: Control, id: String, title: String, body: String) -> void:
	if not is_instance_valid(control) or not control.is_visible_in_tree(): return
	target = control
	present(_control_bounds(control),id,title,body)

func _control_bounds(control: Control) -> Rect2:
	return get_global_transform_with_canvas().affine_inverse()*control.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,control.size)

func logical(rect: Rect2, id: String, title: String, body: String) -> void:
	present(get_global_transform_with_canvas().affine_inverse()*game.get_global_transform_with_canvas()*Rect2(game.origin+rect.position*game.scale_factor,rect.size*game.scale_factor),id,title,body)

func present(rect: Rect2, id: String, title: String, body: String) -> void:
	if dismissed_steps.has(id):
		hold = false
		return
	if rect.size.x < 1 or rect.size.y < 1: return
	presented = true
	target_rect = rect.grow(7)
	if step_id != id:
		clock = 0
		step_id = id
	heading.text = "操作指引 · " + title
	description.set_copy(body)
	var width := minf(450,size.x-32)
	card.custom_minimum_size.x = width
	card.size.x = width
	card.reset_size()
	var x := clampf(rect.get_center().x-width/2,16,size.x-width-16)
	var y := rect.position.y-card.size.y-64
	if y < 180: y = rect.end.y+64
	if y+card.size.y > size.y-16:
		y = clampf(rect.position.y-card.size.y-64,16,size.y-card.size.y-16)
	if rect.get_center().y < size.y*0.75:
		if rect.end.x+width+80 < size.x and rect.get_center().x < size.x*0.35:
			x = rect.end.x+64
			y = clampf(rect.get_center().y-card.size.y/2,180,size.y-card.size.y-16)
		elif rect.position.x-width-80 > 0 and rect.get_center().x > size.x*0.65:
			x = rect.position.x-width-64
			y = clampf(rect.get_center().y-card.size.y/2,180,size.y-card.size.y-16)
	# Keep the program effect and target picker readable during confirmation.
	if id == "hack_release":
		var preview: Control = game.code_panel.program_preview
		var bounds := _control_bounds(preview)
		if bounds.end.x+width+48 < size.x:
			x = bounds.end.x+32
			y = clampf(rect.get_center().y-card.size.y/2,16,size.y-card.size.y-16)
	card.position = _readable_position(Vector2(x,y))
	focus_regions.assign([target_rect.grow(3)])
	var details: Control = game.code_panel.program_preview
	if details.is_visible_in_tree() and id in ["hack", "hack_release"]:
		focus_regions.append(_control_bounds(details))
	if id in ["item_type","item_use"]:
		focus_regions.append(_control_bounds(game.code_panel.item_controls.supply.card))
	_update_connector()
	queue_redraw()
	show()

func _readable_position(preferred: Vector2) -> Vector2:
	var protected: Array[Rect2] = [target_rect.grow(12)]
	var preview: Control = game.code_panel.program_preview
	if preview.is_visible_in_tree(): protected.append(_control_bounds(preview).grow(12))
	if is_instance_valid(game.campaign_panel.exploration_popup) and game.campaign_panel.exploration_popup.visible:
		protected.append(_control_bounds(game.campaign_panel.exploration_popup).grow(12))
	# Protect visible prose and actions, including dynamically created dispatch UI.
	for node in game.find_children("*", "Control", true, false):
		if is_ancestor_of(node) or not node.is_visible_in_tree(): continue
		if game.screen == "battle": continue
		if node is Label or node is RichTextLabel or node is BaseButton:
			protected.append(_control_bounds(node).grow(8))
	var gap := 36.0
	var detail_bounds := Rect2()
	if preview.is_visible_in_tree(): detail_bounds = _control_bounds(preview)
	if step_id in ["item_type","item_use"]:
		detail_bounds = _control_bounds(game.code_panel.item_controls.supply.card)
		protected.append(detail_bounds.grow(12))
	var candidates: Array[Vector2] = [
		Vector2(target_rect.get_center().x-card.size.x/2,target_rect.position.y-card.size.y-gap),
		Vector2(target_rect.get_center().x-card.size.x/2,target_rect.end.y+gap),
		Vector2(target_rect.position.x-card.size.x-gap,target_rect.get_center().y-card.size.y/2),
		Vector2(target_rect.end.x+gap,target_rect.get_center().y-card.size.y/2),preferred]
	if detail_bounds.has_area():
		candidates.push_front(Vector2(detail_bounds.end.x+gap,target_rect.get_center().y-card.size.y/2))
		candidates.push_front(Vector2(detail_bounds.position.x-card.size.x-gap,target_rect.get_center().y-card.size.y/2))
	for column in [0.0,0.25,0.5,0.75,1.0]:
		for row in [0.0,0.25,0.5,0.75,1.0]:
			candidates.append(Vector2(16+(size.x-card.size.x-32)*column,16+(size.y-card.size.y-32)*row))
	var best := preferred
	var best_score := INF
	for candidate in candidates:
		candidate = candidate.clamp(Vector2(16,16),(size-card.size-Vector2(16,16)).max(Vector2(16,16)))
		var bounds := Rect2(candidate,card.size)
		var score := bounds.get_center().distance_squared_to(target_rect.get_center())*0.01
		if detail_bounds.has_area() and bounds.end.x > detail_bounds.position.x-12 and bounds.position.x < detail_bounds.end.x+12:
			score += 1000000
		for blocked in protected:
			var overlap := bounds.intersection(blocked)
			if overlap.has_area(): score += overlap.get_area()*100
		if score < best_score:
			best_score = score
			best = candidate
	return best

func action(root: Node, prefix: String) -> Control:
	if not is_instance_valid(root): return null
	for child in root.find_children("*","Button",true,false):
		if child.is_visible_in_tree() and not child.disabled and str(child.get_meta("action_id","")).begins_with(prefix): return child
	return null

func caption(root: Node, text: String) -> Control:
	if not is_instance_valid(root): return null
	for child in root.find_children("*","Button",true,false):
		if child.is_visible_in_tree() and not child.disabled and child.text == text: return child
	return null

func update() -> void:
	presented = false
	hold = false
	target = null
	_resolve_step()
	if not presented: hide()
	# z_index only changes drawing; GUI picking follows sibling order.
	if visible and get_index() != get_parent().get_child_count()-1:
		get_parent().move_child(self,-1)

func _resolve_step() -> void:
	if not GGT_GameConfig.config.get_value("game","tutorial_enabled",true): return
	if skipped or game.debug_enabled or game.progress.load_blocked: return
	if game.pause_overlay.visible or is_instance_valid(game.campaign_panel.home_overlay): return
	if game.screen == "battle" and game.campaign_mode == "prologue":
		battle()
		return
	var panel = game.campaign_panel
	if not game.progress.campaign.prologue_done or (game.campaign_mode == "prologue" and game.screen != "base"):
		if game.screen == "campaign" and game.journey.data.get("screen") == "visit":
			explore()
			return
		if game.screen == "report":
			logical(Rect2(405,587,470,66),"report","领取战利品","战斗结束啦。继续查看战利品，领取后才能离开校门。")
			return
		for entry in [["strategy:","strategy","选择队伍","任选一个方向。教学会沿用你选择的队伍和破解程序。"],["prologue","prologue","前往校门","从校门开始，先探索热点，再解除守卫封锁。"],["continue","continue","继续教学","回到已保存的位置，继续探索与战斗。"],["reward_owner:","owner","选择归属","为这份战利品选择一名同学。"],["reward:","reward","选择战利品","点击一项奖励完成整备，再返回校门出口。"],["event:","event","探索热点","选择一个回应，完成这次调查。"],["visit","visit","返回热点","查看完毕，回到地图继续探索。"]]:
			var found := action(panel,entry[0])
			if found != null:
				point(found,entry[1],entry[2],entry[3]); return
		return
	if game.progress.campaign.story_flags.get("tutorial_route_selected",false) or not game.progress.campaign.terminals.is_empty(): return
	if game.screen == "dispatch_board" and (not game.progress.campaign.routes_acquired or game.progress.active_run.is_empty()):
		dispatch(); return
	if not game.progress.campaign.routes_acquired:
		point(action(panel,"tutorial"),"dispatch","进入派遣","点击教学派遣，在图书馆完成免费的「出发准备」委托。")
		return
	if not game.progress.active_run.is_empty(): return
	var preview = game.get_node_or_null("CampaignMapRegionPreview")
	if is_instance_valid(preview):
		if preview.board.selected_route < 0:
			for button in preview.route_buttons:
				if button.is_visible_in_tree():
					point(button,"route","选择路线","点击任意一条区域路线。三条路线可自由选择先后顺序。")
					return
		else:
			point(preview.select_button,"route_confirm","确认路线","这条路线已高亮。点击开始探索，随后选择队伍并准备出发。")
		return
	var strategy := action(panel,"strategy:")
	if strategy != null:
		point(strategy,"first_strategy","选择队伍","选择本次探索的队伍方向，接着进入出发准备。")
		return
	if game.screen == "departure":
		for entry in [
			["prep_points","准备点数","携带物品需要花费准备点数；卡片上的数字是单件花费。点数不足时无法继续携带。点击下一步查看格子。"],
			["prep_slots","携带格子","每件物品占一个格子；重复携带也分别占格。点数和空格都足够，才能带上。点击下一步查看解锁条件。"],
			["prep_locked","未解锁物品","灰色卡片尚未解锁，不能携带。先在基地完成对应派遣，之后便能在这里选择。点击下一步试选物品。"]]:
			if dismissed_steps.has(entry[0]): continue
			for control in panel.find_children("*","Control",true,false):
				if control.is_visible_in_tree() and control.get_meta("guide_id","") == entry[0]:
					point(control,entry[0],entry[1],entry[2]); return
		if departure_item_count < 0: departure_item_count = game.departure_items.size()
		if game.departure_items.size() > departure_item_count: dismissed_steps["prep_carry"] = true
		var packed := action(panel,"unpack:")
		if not dismissed_steps.has("prep_carry"):
			var carry := action(panel,"prep:")
			if carry != null:
				point(carry,"prep_carry","携带物品","点击携带：左侧点数减少，物品进入一个空格。不想携带也可以点下一步。")
				return
		if packed != null and not dismissed_steps.has("prep_unpack"):
			point(packed,"prep_unpack","调整物品","已携带的物品显示在左侧。点击放回会恢复点数并腾出格子，可重新选择；保留当前选择请点下一步。")
			return
		point(action(panel,"depart"),"depart","开始探索","选好两名同学与携带物品，点击出发，开始这条路线。")
		return
	point(action(panel,"map_region"),"campus","打开校园地图","出发准备已解锁！点击探索，打开校园地图选择第一条路线。")

func explore() -> void:
	var panel = game.campaign_panel
	var board = panel.exploration_board
	if not is_instance_valid(board): return
	if game.journey.visit.can_leave():
		point(board.passage_hotspot,"leave","返回基地","奖励已领取，出口已开放。点击出口返回基地，学习派遣。")
		return
	if is_instance_valid(panel.exploration_popup) and panel.exploration_popup.visible:
		var index: int = panel.exploration_detail_index
		var spot: Dictionary = game.journey.visit.data.hotspots[index]
		if spot.kind != "battle": investigated = true
		point(action(panel.exploration_popup,"spot:"),"hotspot_action","进入战斗" if spot.kind == "battle" else "调查热点","点击挑战进入战前整备。" if spot.kind == "battle" else "点击执行调查。热点先显示简要信息，再展开详情与操作。")
		return
	investigated = investigated or not game.journey.visit.data.viewed.is_empty()
	var wanted := "battle" if investigated else "memory"
	for button in board.buttons:
		if button.kind == wanted and button.is_visible_in_tree():
			point(button,"hotspot_"+wanted,"挑战守卫" if investigated else "探索热点","点击守卫热点，查看详情并进入战斗。" if investigated else "地图上发光的标记是可探索热点。悬停查看简要信息，点击展开详情。")
			return
	for button in board.buttons:
		if button.is_visible_in_tree():
			point(button,"hotspot","探索热点","点击地图热点查看详情，守卫热点可以进入战斗。")
			return

func battle() -> void:
	var hud = game.code_panel
	var sim = game.simulation
	if battle_ref != sim:
		battle_ref = sim
		battle_step = 0
		initial_formation.clear()
		formation_dismissed = false
		dismissed_steps.clear()
	if game.phase == "prepare":
		battle_step = 0
		if initial_formation.is_empty(): initial_formation = game.formation.duplicate()
		if not formation_dismissed and (initial_formation == game.formation or 6-game.formation.count(-1) != game._deployment_limit()):
			if game.deployment.selected_role >= 0 and game.deployment.mode in [1,3]:
				var slot: int = game.formation.find(-1)
				if slot < 0: slot = (game.formation.find(game.deployment.selected_role)+1)%6
				logical(game._slot_rect(0,slot),"formation_slot","选择阵位","点击高亮格子部署或换位。靠敌人一侧为前排，远程与支援通常放后排。")
			else:
				point(game.deployment.cards.values()[0],"formation","排列阵型","点击角色卡，再点击我方格子换位；也可以直接拖动卡片。近战适合前排，远程与支援适合后排。")
		else:
			point(game.deployment.start_button,"start","开始战斗","阵型已调整。部署满四人后点击开战，同学会自动移动和攻击。")
		return
	if game.phase != "battle": return
	if battle_step >= 2 and game.paused:
		hold = true
		point(hud.pause_control,"resume_extra","恢复战斗","当前是手动暂停。点击继续战斗，再完成当前教学操作。")
		return
	if battle_step == 0:
		hold = true
		if game.paused: battle_step = 1
		point(hud.pause_control,"pause","暂停战斗","点击暂停，给自己一点思考时间。P 也可以切换暂停；Esc 打开菜单。")
	elif battle_step == 1:
		hold = true
		if not game.paused: battle_step = 2
		point(hud.pause_control,"resume","继续战斗","再次点击恢复战斗。教学操作期间会暂缓推进，不必着急。")
	elif battle_step == 2:
		hold = true
		if not is_equal_approx(game.speed,1.0): battle_step = 3
		point(hud.speed_up,"speed","调整速度","点击右侧加号加速，左侧减号减速；中间显示当前倍率，范围为 0.5～2 倍。")
	elif battle_step == 3:
		hold = true
		if sim.item_uses.has("supply") or sim.items.get("supply",0) == 0:
			battle_step = 4
		elif hud.selected_item != "supply":
			point(hud.item_controls.supply.icon,"item","使用物品","点击左侧代码补给，查看效果并选择要补充的代码类型。")
		else:
			var picker = hud.item_controls.supply.destination
			var kind := "purple" if sim.loadout.has("redirect") else "blue"
			var index: int = game.CodeCatalog.RULES.types.keys().find(kind)
			if picker.selected != index:
				point(picker.get_child(index),"item_type","选择补给类型","为这套队伍补充权限代码。其余代码会随自动战斗积攒。" if kind == "purple" else "为追踪破解补充数据代码。指令代码会随普通攻击积攒。")
			else:
				point(hud.item_controls.supply.button,"item_use","确认使用","点击使用补充所选代码。物品有数量限制，请留意图标上的库存。")
	elif battle_step == 4:
		if not sim.program_uses.is_empty(): battle_step = 5; return
		var ready := ""
		for id in sim.loadout:
			if id != "repair" and sim.program_error(id).is_empty(): ready = id; break
		if ready.is_empty() and sim.elapsed > 10 and sim.program_error("repair").is_empty(): ready = "repair"
		if ready.is_empty():
			point(hud.bank_labels.purple if sim.loadout.has("redirect") else hud.bank_labels.blue,"codes","积攒代码","战斗会自动积攒代码：角色普攻产出对应颜色，验证可追加数据，护盾实际吸收产出权限。把鼠标移离技能详情，让战斗继续。")
		else:
			hold = true
			if hud.preview_program_id == ready and hud.preview_pinned:
				point(hud.preview_release,"hack_release","释放破解","代码已足够。确认目标与消耗后点击释放，完成第一次破解！")
			else:
				point(hud.program_controls[ready].button,"hack","使用破解","亮起的程序已经可以释放。点击程序，查看目标与代码消耗。")

func dispatch() -> void:
	var board = game.dispatch_board
	if not is_instance_valid(board) or board.busy: return
	if is_instance_valid(board.result_layer):
		point(caption(board.result_layer,"收下成果"),"receipt","领取成果","首次派遣已完成，出发准备与校园路线已永久开放。点击收下成果。")
	elif game.progress.campaign.routes_acquired:
		point(caption(board.navigation,"返回基地"),"dispatch_back","返回基地","带着路线资料回基地，接下来打开校园地图。")
	elif board.outside:
		point(caption(board.navigation,"校内"),"campus_dispatch","回到校内","第一份免费委托在校内图书馆。")
	elif board.selected_place != "library":
		point(caption(board,"图书馆"),"library","选择图书馆","点击图书馆，找到免费的出发准备委托。")
	elif is_instance_valid(board.staff_picker):
		for button in board.staff_picker.find_children("*","Button",true,false):
			if button.has_meta("staff"):
				point(button,"staff","选择人员","任选一名后勤成员即可；当前人员能力相同。")
				return
	elif board.selected_staff.is_empty():
		point(board.staff_slot,"staff_slot","安排人员","点击人员空位，为第一份派遣安排一名后勤成员。")
	else:
		point(action(board,"commission:departure"),"commission","解锁出发准备","点击这份免费委托的派遣按钮，永久解锁出发准备和校园路线。")

func _edge_toward(bounds: Rect2, destination: Vector2) -> Vector2:
	var delta := destination-bounds.get_center()
	var half := bounds.size/2
	var divisor := maxf(absf(delta.x)/maxf(half.x,1),absf(delta.y)/maxf(half.y,1))
	return bounds.get_center()+delta/maxf(divisor,0.001)

func _update_connector() -> void:
	var box := Rect2(card.position,card.size)
	var start := _edge_toward(box,target_rect.get_center())
	var end := _edge_toward(target_rect,box.get_center())
	var direction := (end-start).normalized()
	connector = PackedVector2Array([start,end-direction*6])

func _draw() -> void:
	if not visible: return
	# Subtract transparent focus windows from the dimmer, without intercepting input.
	var shaded: Array[Rect2] = [Rect2(Vector2.ZERO,size)]
	for window in focus_regions:
		var remainder: Array[Rect2] = []
		for region in shaded:
			var cut := region.intersection(window)
			if not cut.has_area():
				remainder.append(region)
				continue
			for piece in [Rect2(region.position,Vector2(region.size.x,cut.position.y-region.position.y)),Rect2(Vector2(region.position.x,cut.end.y),Vector2(region.size.x,region.end.y-cut.end.y)),Rect2(Vector2(region.position.x,cut.position.y),Vector2(cut.position.x-region.position.x,cut.size.y)),Rect2(Vector2(cut.end.x,cut.position.y),Vector2(region.end.x-cut.end.x,cut.size.y))]:
				if piece.has_area(): remainder.append(piece)
		shaded = remainder
	for region in shaded: draw_rect(region,Color(0.015,0.025,0.04,0.64))
	var outline := StyleBoxFlat.new()
	outline.bg_color = Color.TRANSPARENT
	outline.border_color = Color("ffe09a")
	outline.set_border_width_all(3)
	outline.set_corner_radius_all(8)
	draw_style_box(outline,target_rect)
	if connector.size() < 2: return
	draw_polyline(connector,Color("111b27"),8,true)
	draw_polyline(connector,Color("ffe09a"),3.5,true)
	var tip := connector[-1]
	var direction := (tip-connector[-2]).normalized()
	var tangent := Vector2(-direction.y,direction.x)
	draw_colored_polygon(PackedVector2Array([tip,tip-direction*14+tangent*8,tip-direction*14-tangent*8]),Color("ffe09a"))
