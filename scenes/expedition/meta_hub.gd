extends "res://scenes/expedition/expedition.gd"
const Catalog = preload("res://game/meta/meta_catalog.gd")
const Checkpoint = preload("res://game/run/run_checkpoint.gd")
var storage_ready = false
var checkpoint_error = ""
var selected_staff = "archivist"
var selected_location = 0
var last_save_ok = true
var test_runner: RefCounted
var team_panel: Control
var panel_was_paused = false

func _open_team_panel() -> void:
	if is_instance_valid(team_panel) or not screen in ["map","battle"]: return
	panel_was_paused = paused
	if screen == "map": _build_units()
	paused = true
	team_panel = load("res://scenes/team/team_panel.gd").new()
	team_panel.game = self
	team_panel.editable = screen == "map" or phase == "prepare"
	team_panel.closed.connect(func(): paused = panel_was_paused)
	add_child(team_panel)

func _input(event: InputEvent) -> void:
	if is_instance_valid(team_panel): return
	super._input(event)

func _header(title: String, subtitle: String) -> void:
	super._header(title,subtitle)
	if screen == "map": _flow_button(Rect2(765,26,145,48),"队伍面板")

func _ready() -> void:
	super._ready()
	storage_ready = true
	if not progress.active_run.is_empty() and Checkpoint.decode(progress.active_run).is_empty():
		checkpoint_error = "探索存档无法恢复，原存档已保留。"
		progress.load_blocked = true
	var base_button = _menu_button("返回基地 · 成长与派遣", _to_base)
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
	elif "--team-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/team/team_checks.gd").new()
		test_runner.run_checks(self)

func _pack_checkpoint() -> Dictionary:
	return {"schema":1, "run":run.to_dict(), "screen":screen, "selected":selected,
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
		draw_rect(Rect2(660,22,260,54),Color("344b42"))
		_center(Vector2(707,55),"整备" if phase == "prepare" else ("暂停" if paused else "战斗中"),GOLD,18)
		_flow_button(Rect2(765,26,145,48),"队伍面板")
	if not last_save_ok or progress.load_blocked:
		_pixel_panel(Rect2(25,91,885,40),Color("ac6e58"))
		_text(Vector2(40,118),checkpoint_error if not checkpoint_error.is_empty() else progress.error_message,PAPER,17)

func _draw_base() -> void:
	_header("重返校园 · 安全教室","继续探索 / 校园成长 / 支援同学派遣")
	_campus()
	_pixel_panel(Rect2(136,229,669,334),PAPER)
	_center(Vector2(470,274),"今天，也一起回学校吧。",DARK,28)
	var saved = not progress.active_run.is_empty()
	var finished = saved and progress.active_run.get("screen","") == "summary"
	var caption = "从旧校门出发，沿途构筑队伍。"
	if saved and progress.active_run.get("run",{}) is Dictionary:
		caption = "上次探索已完成，可以查看结果。" if finished else ("探索存档需要检查。" if progress.load_blocked else "已保存第 %d / 5 个地点的探索。" % mini(5,int(progress.active_run.run.stage) + 1))
	_center(Vector2(470,319),caption,DARK,19)
	_center(Vector2(470,350),"选路、换装、领奖后自动保存。",Color("6b705a"),17)
	_flow_button(Rect2(221,388,494,61),"查看上局结果" if finished else ("继续探索" if saved else "开始一次探索"),not progress.load_blocked)
	if saved: _flow_button(Rect2(221,471,494,48),"开始新探索",not progress.load_blocked)
	_pixel_panel(Rect2(936,105,306,492),PAPER)
	_text(Vector2(958,147),"校园修复",DARK,24)
	_paragraph(Vector2(958,190),"完成探索：%d 次\n修复资源：%d\n体能训练：%d / 3" % [progress.completions,progress.points,progress.level("fitness")],DARK,19)
	_flow_button(Rect2(956,320,267,58),"功能与能力解锁")
	_flow_button(Rect2(956,395,267,58),"派遣支援同学")
	var supply_label = "出发补给未解锁"
	if progress.supply_unlocked: supply_label = "出发装备：" + ("厚笔记本" if chosen_supply else "不携带")
	_flow_button(Rect2(956,477,267,44),supply_label,progress.supply_unlocked)
	_text(Vector2(958,560),"派遣队伍：%d / %d" % [progress.dispatches.size(),2 if progress.level("staffing") > 0 else 1],DARK,17)
	_pixel_panel(Rect2(25,625,1215,65),Color("344b42"))
	_text(Vector2(42,665),notice.left(64),PAPER,17)

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
		_text(Vector2(x+20,y+110),"等级 %d / %d" % [count,item.costs.size()],Color("6b705a"),17)
		var reason = progress.unlock_reason(item.id)
		var label = "已满级" if count >= item.costs.size() else "解锁 / %d 资源" % item.costs[count]
		_flow_button(Rect2(x+324,y+87,241,42),label,reason.is_empty())
	_flow_button(Rect2(993,634,245,52),"返回基地")
	_text(Vector2(43,667),notice.left(52),PAPER,17)

func _dispatch_point(index: int) -> Vector2:
	return [Vector2(315,260),Vector2(677,423)][index]

func _draw_dispatch() -> void:
	_header("校园远征地图","点击地图建筑查看地点，再选择支援同学派遣。离线探索继续计时。")
	_campus()
	draw_line(Vector2(462,185),Vector2(462,505),Color("d8c79d"),15)
	for i in range(Catalog.LOCATIONS.size()):
		var location: Dictionary = Catalog.LOCATIONS[i]
		var p = _dispatch_point(i)
		draw_line(Vector2(462,p.y),p,Color("d8c79d"),12)
		var unlocked = progress.level(location.requires) > 0
		_pixel_panel(Rect2(p-Vector2(80,48),Vector2(160,96)),PAPER if unlocked else Color("969d8c"))
		draw_rect(Rect2(p-Vector2(88,56),Vector2(176,17)),Color("a86c57"))
		for x in [-48,0,48]: draw_rect(Rect2(p+Vector2(x-12,-19),Vector2(24,30)),Color("709caa"))
		if selected_location == i: draw_rect(Rect2(p-Vector2(94,62),Vector2(188,126)),GOLD,false,4)
		_center(p+Vector2(0,84),location.name,DARK,22)
		var state_text = "可派遣" if unlocked else "尚未解锁"
		for job in progress.dispatches:
			if job.location == location.id:
				state_text = "成果可领取" if int(job.ready_at) <= int(Time.get_unix_time_from_system()) else "探索中"
		_center(p+Vector2(0,112),state_text,DARK,17)
	_pixel_panel(Rect2(936,105,306,490),PAPER)
	var place: Dictionary = Catalog.LOCATIONS[selected_location]
	_text(Vector2(957,148),place.name,DARK,24)
	_paragraph(Vector2(957,188),"消耗 %d 修复资源\n探索 %d 秒 / 获得 %d 资源" % [place.cost,place.duration,place.reward],DARK,17)
	_text(Vector2(957,288),"选择支援同学",DARK,20)
	var workers = progress.available_staff()
	for i in range(workers.size()):
		var label = workers[i].name + (" · 忙碌" if progress.busy(workers[i].id) else "")
		_flow_button(Rect2(953,313+i*58,274,48),label,not progress.busy(workers[i].id))
		if selected_staff == workers[i].id: draw_rect(Rect2(950,310+i*58,280,54),Color("5a9d9c"),false,3)
	var reason = progress.dispatch_reason(selected_staff,place.id)
	_flow_button(Rect2(953,520,274,53),"出发探索" if reason.is_empty() else reason,reason.is_empty())
	for i in range(progress.dispatches.size()):
		var job: Dictionary = progress.dispatches[i]
		var remaining = maxi(0,int(job.ready_at)-int(Time.get_unix_time_from_system()))
		var location = Catalog.find(Catalog.LOCATIONS,job.location)
		_flow_button(Rect2(28+i*447,626,427,57),location.name + (" · 领取成果" if remaining == 0 else " · %d 秒" % remaining),remaining == 0)
	if progress.dispatches.is_empty(): _text(Vector2(35,661),notice.left(48) if not notice.is_empty() else "探索队伍出发后，可在这里领取成果。",PAPER,17)
	_flow_button(Rect2(993,634,245,52),"返回基地")

func _gui_input(event: InputEvent) -> void:
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
		if Rect2(221,388,494,61).has_point(p):
			if progress.active_run.is_empty(): _new_run()
			else: _continue_run()
		elif Rect2(221,471,494,48).has_point(p) and not progress.active_run.is_empty():
			if progress.active_run.get("screen","") == "summary": _new_run()
			else: _request_exit("new_run")
		elif Rect2(956,320,267,58).has_point(p): screen = "growth"; notice = ""
		elif Rect2(956,395,267,58).has_point(p): screen = "dispatch"; notice = ""
		elif Rect2(956,477,267,44).has_point(p) and progress.supply_unlocked: chosen_supply = not chosen_supply
	elif screen == "growth":
		for i in range(Catalog.UNLOCKS.size()):
			if Rect2(359+(i%2)*605,198+int(i/2)*163,241,42).has_point(p):
				var item: Dictionary = Catalog.UNLOCKS[i]
				notice = "已解锁「"+item.name+"」。" if progress.purchase(item.id) else progress.error_message
		if Rect2(993,634,245,52).has_point(p): screen = "base"
	elif screen == "dispatch":
		for i in range(Catalog.LOCATIONS.size()):
			if Rect2(_dispatch_point(i)-Vector2(95,65),Vector2(190,180)).has_point(p): selected_location = i
		var workers = progress.available_staff()
		for i in range(workers.size()):
			if Rect2(953,313+i*58,274,48).has_point(p): selected_staff = workers[i].id
		if Rect2(953,520,274,53).has_point(p):
			notice = "队伍已出发，进度已保存。" if progress.start_dispatch(selected_staff,Catalog.LOCATIONS[selected_location].id) else progress.error_message
		for i in range(progress.dispatches.size()):
			if Rect2(28+i*447,626,427,57).has_point(p):
				notice = "成果已领取，同学已归队。" if progress.claim_dispatch(progress.dispatches[i].id) else progress.error_message
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
	progress.start_dispatch("liaison","gym",int(Time.get_unix_time_from_system()) - 121)
	screen = "dispatch"
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/meta_dispatch.png")
	get_tree().quit()
