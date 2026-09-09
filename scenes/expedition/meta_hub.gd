extends "res://scenes/expedition/expedition.gd"
const Catalog = preload("res://game/meta/meta_catalog.gd")
const Checkpoint = preload("res://game/run/run_checkpoint.gd")
var storage_ready = false
var checkpoint_error = ""
var selected_location = 0
var last_save_ok = true
var test_runner: RefCounted
var team_panel: Control
var panel_was_paused = false
var campus_map: Control
var location_panel: Control

func _create_campus_map() -> void:
	campus_map = preload("res://scenes/expedition/campus_map.gd").new()
	campus_map.progress = progress
	campus_map.location_selected.connect(_open_location_details)
	campus_map.claim_requested.connect(_claim_map_job)
	add_child(campus_map)
	campus_map.hide()

func _dispatch_departed(job: Dictionary) -> void:
	_close_location_details()
	campus_map.reset_view()
	campus_map.play_journey(job)

func _claim_map_job(job_id: String) -> void:
	if screen != "dispatch" or paused or is_instance_valid(location_panel): return
	var job: Dictionary = {}
	for item in progress.dispatches:
		if item.id == job_id: job = item.duplicate(true); break
	var return_origin: Vector2 = campus_map.job_rect(job).position + Vector2(88, 24) if not job.is_empty() else Vector2.ZERO
	if progress.claim_dispatch(job_id):
		notice = "成果已领取，同学正在返回据点。"
		campus_map.play_journey(job, true, return_origin)
	else: notice = progress.error_message

func _close_location_details() -> void:
	if is_instance_valid(location_panel):
		remove_child(location_panel)
		location_panel.queue_free()
		location_panel = null
	if screen == "dispatch": campus_map.grab_focus()

func _open_location_details(index: int) -> void:
	if screen != "dispatch" or paused: return
	_close_location_details()
	selected_location = index
	campus_map.selected = index
	campus_map.hovered = -1
	location_panel = preload("res://scenes/expedition/location_dispatch_panel.gd").new()
	location_panel.game = self
	location_panel.place = Catalog.LOCATIONS[index]
	add_child(location_panel)
func _open_team_panel() -> void:
	if is_instance_valid(team_panel) or not screen in ["map","battle"]: return
	panel_was_paused = paused
	if screen == "map": _build_units()
	paused = true
	team_panel = load("res://scenes/team/visual_team_panel.gd").new()
	team_panel.game = self
	team_panel.editable = screen == "map" or phase == "prepare"
	team_panel.closed.connect(func(): paused = panel_was_paused)
	add_child(team_panel)

func _input(event: InputEvent) -> void:
	if is_instance_valid(location_panel):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_location_details()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(team_panel): return
	super._input(event)

func _header(title: String, subtitle: String) -> void:
	super._header(title,subtitle)
	if screen == "map": _flow_button(Rect2(765,26,145,48),"队伍面板")

func _ready() -> void:
	var content_errors = Content.validate()
	if not content_errors.is_empty():
		push_error("内容校验失败：\n"+"\n".join(content_errors))
		var error_label = Label.new()
		error_label.text = "内容校验失败，请检查输出：\n"+"\n".join(content_errors)
		error_label.add_theme_font_override("font",preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
		add_child(error_label)
		set_process(false)
		set_process_input(false)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	super._ready()
	_create_campus_map()
	storage_ready = true
	if not progress.active_run.is_empty() and Checkpoint.decode(progress.active_run).is_empty():
		checkpoint_error = "探索存档无法恢复，原存档已保留。"
		progress.load_blocked = true
	var base_button = _menu_button("返回基地", _to_base)
	pause_actions.add_child(base_button)
	pause_actions.move_child(base_button,2)
	pause_actions.position.y = 270
	pause_actions.size.y = 300
	pause_content.get_child(0).position.y = 110
	pause_content.get_child(0).size.y = 540
	if "--meta-smoke" in OS.get_cmdline_user_args():
		var check = load("res://scenes/expedition/meta_checks.gd").new()
		check.run_checks(self)
	elif "--meta-capture" in OS.get_cmdline_user_args():
		_capture_meta()
	elif "--random-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/random_checks.gd").new()
		test_runner.run_checks(self)
	elif "--content-check" in OS.get_cmdline_user_args():
		test_runner = load("res://game/content/content_checks.gd").new()
		test_runner.run_checks(self)
	elif "--team-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/team/team_checks.gd").new()
		test_runner.run_checks(self)
	elif "--map-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/campus_map_checks.gd").new()
		test_runner.run_checks(self)
	elif "--dispatch-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/dispatch_checks.gd").new()
		test_runner.run_checks(self)
	elif "--journey-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/journey_checks.gd").new()
		test_runner.run_checks(self)

func _pack_checkpoint() -> Dictionary:
	return {"schema":1, "run":run.to_dict(), "screen":screen, "selected":selected, "selected_id":Content.role_id(selected),
		"report":report.duplicate(true), "won":result_won, "elapsed":elapsed,
		"seconds":expedition_seconds, "speed":speed}

func _checkpoint() -> bool:
	if not storage_ready: return true
	if not screen in ["map","battle","event","reward","report","summary"]: return not progress.load_blocked
	_sync_team_data()
	if screen == "summary" and not run.settled:
		_settle()
		return run.settled
	last_save_ok = progress.save_checkpoint(_pack_checkpoint())
	return last_save_ok

func _sync_team_data() -> void:
	run.formation = formation.duplicate()
	run.shoe_wearer = equipment

func _new_run() -> void:
	if progress.load_blocked:
		notice = "存档无法读取，已禁止覆盖。请保留文件排查。"
		return
	super._new_run()
	run.permanent_hp = progress.level("fitness") * 20
	_checkpoint()

func _sync_team() -> void:
	super._sync_team()
	_checkpoint()

func _start() -> void:
	super._start()
	_checkpoint()

func _enter_node() -> void:
	super._enter_node()
	_checkpoint()

func _choose_event(index: int) -> void:
	super._choose_event(index)
	_checkpoint()

func _choose_reward(index: int) -> void:
	super._choose_reward(index)
	_checkpoint()

func _after_report() -> void:
	super._after_report()
	_checkpoint()

func _build_units() -> void:
	super._build_units()
	for unit in units:
		if unit.side == 0:
			unit.max_hp += run.permanent_hp
			unit.hp = unit.max_hp

func _process(delta: float) -> void:
	var previous_screen = screen
	super._process(delta)
	if screen != previous_screen: _checkpoint()
	if is_instance_valid(campus_map):
		campus_map.progress = progress
		var layout_scale: float = minf(size.x / 1280, size.y / 720)
		var layout_origin: Vector2 = (size - Vector2(1280, 720) * layout_scale) / 2
		campus_map.position = layout_origin + Vector2(24, 105) * layout_scale
		campus_map.size = Vector2(894, 490) * layout_scale
		campus_map.visible = screen == "dispatch" and not paused
		campus_map.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_instance_valid(location_panel) else Control.MOUSE_FILTER_STOP
		campus_map.queue_redraw()
		if screen != "dispatch" and is_instance_valid(location_panel): _close_location_details()

func _settle() -> void:
	screen = "summary"
	if run.settled: return
	run.settled = true
	_sync_team_data()
	last_save_ok = progress.finish_run(_pack_checkpoint(),run.points)
	if not last_save_ok: run.settled = false

func _continue_run() -> void:
	if progress.load_blocked: return
	var data = Checkpoint.decode(progress.active_run)
	if data.is_empty():
		notice = "没有可恢复的探索存档。"
		return
	run = data.run
	screen = data.screen
	formation = run.formation.duplicate()
	equipment = run.shoe_wearer
	selected = data.selected if run.roster.has(data.selected) else 0
	speed = data.speed
	chosen_node = 0
	inspected_enemy_slot = -1
	pending_slot = -1
	phase = "prepare"
	encounter = int(run.node.get("encounter",0))
	_build_units()
	report = data.report
	result_won = data.won
	expedition_seconds = data.seconds
	if screen != "battle": elapsed = data.elapsed
	paused = false
	notice = "已恢复探索。中断的战斗从同一战前阵容重新开始。"
	_note(notice)

func _to_base() -> void:
	if not _checkpoint():
		pause_caption.text = "保存失败，暂未离开。\n请重试，原存档仍保留。"
		return
	_resume_battle()
	screen = "base"
	notice = "探索已保存，可继续探索或管理基地。"

func _request_exit(destination: String) -> void:
	if is_instance_valid(team_panel): team_panel.close_panel()
	super._request_exit(destination)
	if destination == "new_run":
		pause_heading.text = "放弃当前探索？"
		pause_caption.text = "新探索会替换当前探索存档。\n本局尚未结算的资源不会带回。"
	else:
		pause_caption.text = "确认后保存并离开。\n下次可继续，中断战斗从战前重开。"

func _confirm_exit() -> void:
	if pending_exit == "new_run":
		_resume_battle()
		_new_run()
		return
	if not _checkpoint():
		pause_caption.text = "保存失败，暂未退出。\n请重试，原存档仍保留。"
		return
	super._confirm_exit()

func _return_to_formation() -> void:
	super._return_to_formation()
	_checkpoint()

func _draw() -> void:
	if screen in ["growth","dispatch"]:
		if font == null: return
		scale_factor = minf(size.x / 1280.0,size.y / 720.0)
		origin = (size - Vector2(1280,720) * scale_factor) / 2
		draw_rect(Rect2(Vector2.ZERO,size),DARK)
		draw_set_transform(origin,0,Vector2.ONE * scale_factor)
		if screen == "growth": _draw_growth()
		else: _draw_dispatch()
	else:
		super._draw()
	if screen == "battle":
		draw_rect(Rect2(660,22,260,54),Color("202027"))
		_center(Vector2(707,55),"整备" if phase == "prepare" else ("暂停" if paused else "战斗中"),GOLD,18)
		_flow_button(Rect2(765,26,145,48),"队伍面板")
	if not last_save_ok or progress.load_blocked:
		_pixel_panel(Rect2(25,91,885,40),Color("ac6e58"))
		_text(Vector2(40,118),checkpoint_error if not checkpoint_error.is_empty() else progress.error_message,PAPER,17)

func _home_rect(id: String) -> Rect2:
	return {"resume":Rect2(36,259,185,55),"new":Rect2(36,329,185,55),"supply":Rect2(36,430,185,50),"growth":Rect2(1059,259,185,55),"dispatch":Rect2(1059,329,185,55),"codex":Rect2(1059,399,185,55)}[id]

func _home_panel(rect: Rect2) -> void:
	var comic = preload("res://scenes/ui/comic_ui.gd")
	comic.card(self,rect,Color(0.06,0.06,0.08,0.90))
	draw_line(rect.position+Vector2(16,65),rect.position+Vector2(rect.size.x-14,54),comic.RED,5)

func _home_button(id: String, label: String, enabled: bool = true) -> void:
	var comic = preload("res://scenes/ui/comic_ui.gd")
	var rect = _home_rect(id)
	var hovered = enabled and rect.has_point((get_local_mouse_position()-origin)/scale_factor)
	var fill = comic.RED if hovered or id == "resume" else comic.WHITE
	if not enabled: fill = Color("494952")
	comic.card(self,rect,fill,comic.WHITE if hovered else comic.INK)
	var ink = comic.WHITE if hovered or id == "resume" else comic.INK
	if not enabled: ink = Color("b5b3bc")
	_text(rect.position+Vector2(18,35),{"resume":"01","new":"+","supply":"S","growth":"02","dispatch":"03","codex":"04"}[id],ink,15)
	_center(rect.get_center()+Vector2(10,8),label,ink,24)
	if hovered: _text(rect.position+Vector2(rect.size.x-25,35),">",ink,25)

func _draw_base() -> void:
	preload("res://scenes/ui/comic_ui.gd").backdrop(self,Vector2(1280,720))
	# Reserve the center for the campus; controls stay in the side gutters.
	draw_set_transform(origin+Vector2(250,112)*scale_factor,0,Vector2.ONE*scale_factor*0.84)
	_campus(false)
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)
	preload("res://scenes/ui/comic_ui.gd").card(self,Rect2(416,40,448,77),Color("e92746"))
	_center(Vector2(640,96),"重 返 校 园",Color("fff9ee"),44)
	_center(Vector2(640,137),"RETURN TO SUMMER / 忆夏学园",Color("fff9ee"),17)
	_home_panel(Rect2(20,173,217,390))
	_home_panel(Rect2(1043,173,217,390))
	_text(Vector2(43,218),"探索",PAPER,28)
	_text(Vector2(1066,218),"成长",PAPER,28)
	var saved = not progress.active_run.is_empty()
	var finished = saved and progress.active_run.get("screen","") == "summary"
	_home_button("resume","战报" if finished else ("继续" if saved else "出发"),not progress.load_blocked)
	if saved: _home_button("new","新探索",not progress.load_blocked)
	_home_button("supply","补给 ✓" if chosen_supply else "补给",progress.supply_unlocked)
	_text(Vector2(43,509),"厚笔记本" if chosen_supply else ("未携带" if progress.supply_unlocked else "尚未解锁"),Color("c5c2ca"),16)
	_home_button("growth","升级")
	_home_button("dispatch","大地图")
	_home_button("codex","图鉴")
	_text(Vector2(1065,503),"资源  %d" % progress.points,PAPER,18)
	_text(Vector2(1065,535),"探索队  %d" % progress.dispatches.size(),Color("c5c2ca"),16)
	if saved and not progress.load_blocked:
		_center(Vector2(640,646),"上局已完成" if finished else "探索进度已保存",Color("c5c2ca"),17)
	_pixel_panel(Rect2(1148,28,78,36),Color("202027"))
	_center(Vector2(1187,53),"菜单",PAPER,17)
	if not notice.is_empty(): _center(Vector2(640,690),notice.left(55),Color("c5c2ca"),15)

func _draw_growth() -> void:
	_header("校园成长","消耗修复资源解锁功能；能力提升从下一次新探索生效。")
	for i in range(Catalog.UNLOCKS.size()):
		var item: Dictionary = Catalog.UNLOCKS[i]
		var x = 35 + (i % 2) * 605
		var y = 111 + int(i / 2) * 163
		_pixel_panel(Rect2(x,y,584,143),PAPER)
		_text(Vector2(x+20,y+35),item.name,DARK,23)
		_text(Vector2(x+20,y+68),item.description,DARK,16)
		var count = progress.level(item.id)
		_text(Vector2(x+20,y+110),"等级 %d / %d" % [count,item.costs.size()] + (" · %d 资源" % item.costs[count] if count < item.costs.size() else ""),Color("6b705a"),17)
		var reason = progress.unlock_reason(item.id)
		var label = "已满级" if count >= item.costs.size() else "升级"
		_flow_button(Rect2(x+324,y+87,241,42),label,reason.is_empty())
	_flow_button(Rect2(993,634,245,52),"返回基地")
	_text(Vector2(43,667),notice.left(52),PAPER,17)

func _draw_dispatch() -> void:
	_header("校园大地图","悬停查看地点名 · 点击查看详情 · 滚轮缩放 · 拖动浏览")
	_flow_button(Rect2(765,26,145,48),"复位")
	_pixel_panel(Rect2(936,105,306,490),PAPER)
	var place: Dictionary = Catalog.LOCATIONS[selected_location]
	_text(Vector2(957,148),place.name,DARK,24)
	_paragraph(Vector2(957,188),"消耗 %d 修复资源\n探索 %d 秒 / 获得 %d 资源" % [place.cost,place.duration,place.reward],DARK,17)
	_paragraph(Vector2(957,288),"要求 %d 名同学\n在地点详情中选择队伍。" % place.get("crew_size",1),DARK,18)
	_flow_button(Rect2(953,520,274,53),"查看详情")
	for i in range(progress.dispatches.size()):
		var job: Dictionary = progress.dispatches[i]
		var remaining = maxi(0,int(job.ready_at)-int(Time.get_unix_time_from_system()))
		var location = Catalog.find(Catalog.LOCATIONS,job.location)
		_text(Vector2(40+i*447,620),location.name + (" · %d 秒" % remaining if remaining > 0 else ""),PAPER,16)
		_flow_button(Rect2(28+i*447,626,427,57),"领取" if remaining == 0 else "探索中",remaining == 0)
	if progress.dispatches.is_empty(): _text(Vector2(35,661),notice.left(48) if not notice.is_empty() else "探索队伍出发后，可在这里领取成果。",PAPER,17)
	_flow_button(Rect2(993,634,245,52),"返回基地")

func _gui_input(event: InputEvent) -> void:
	if is_instance_valid(location_panel): return
	if is_instance_valid(team_panel): return
	if paused or leaving: return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed): return
	var p: Vector2 = (event.position-origin)/scale_factor
	if screen in ["map","battle"] and Rect2(765,26,145,48).has_point(p):
		_open_team_panel()
		accept_event()
		return
	if Rect2(1148,28,78,36).has_point(p):
		_open_pause()
		accept_event()
		return
	if screen == "base":
		if _home_rect("resume").has_point(p):
			if progress.active_run.is_empty(): _new_run()
			else: _continue_run()
		elif _home_rect("new").has_point(p) and not progress.active_run.is_empty():
			if progress.active_run.is_empty() or progress.active_run.get("screen","") == "summary": _new_run()
			else: _request_exit("new_run")
		elif _home_rect("growth").has_point(p): screen = "growth"; notice = ""
		elif _home_rect("dispatch").has_point(p): screen = "dispatch"; notice = ""
		elif _home_rect("codex").has_point(p): _open_codex()
		elif _home_rect("supply").has_point(p) and progress.supply_unlocked: chosen_supply = not chosen_supply
	elif screen == "growth":
		for i in range(Catalog.UNLOCKS.size()):
			if Rect2(359+(i%2)*605,198+int(i/2)*163,241,42).has_point(p):
				var item: Dictionary = Catalog.UNLOCKS[i]
				notice = "已解锁「"+item.name+"」。" if progress.purchase(item.id) else progress.error_message
		if Rect2(993,634,245,52).has_point(p): screen = "base"
	elif screen == "dispatch":
		if Rect2(765,26,145,48).has_point(p): campus_map.reset_view()

		if Rect2(953,520,274,53).has_point(p): _open_location_details(selected_location)
		for i in range(progress.dispatches.size()):
			if Rect2(28+i*447,626,427,57).has_point(p):
				_claim_map_job(progress.dispatches[i].id)
				break
		if Rect2(993,634,245,52).has_point(p): screen = "base"
	else:
		var previous_screen = screen
		if screen == "summary" and Rect2(936,582,306,69).has_point(p) and not run.settled:
			_settle()
		else: super._gui_input(event)
		if screen != previous_screen: _checkpoint()
	accept_event()

func _capture_meta() -> void:
	progress.points = 25
	_new_run()
	_enter_node()
	_to_base()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/meta_continue.png")
	progress.purchase("dispatch")
	progress.purchase("gym")
	progress.purchase("staffing")
	progress.purchase("fitness")
	screen = "growth"
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/meta_growth.png")
	progress.start_dispatch("archivist","library")
	progress.start_dispatch(["liaison","technician"],"gym",int(Time.get_unix_time_from_system()) - 121)
	screen = "dispatch"
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/meta_dispatch.png")
	get_tree().quit()
