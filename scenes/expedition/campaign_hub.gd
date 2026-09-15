extends "res://scenes/expedition/meta_hub.gd"
## M1 flow adapter; old random runs retain the existing hub path.
const Journey = preload("res://game/run/campaign_journey.gd")
const CampaignSave = preload("res://game/run/campaign_checkpoint.gd")
var journey = Journey.new()
var campaign_mode = ""
var campaign_panel: PanelContainer
var campaign_enabled = false
var detail_return = "visit"

func _ready() -> void:
	super._ready()
	campaign_enabled = not is_test or "--campaign-flow-check" in OS.get_cmdline_user_args()
	if not campaign_enabled: return
	campaign_panel = preload("res://scenes/expedition/campaign_panel.gd").new()
	add_child(campaign_panel)
	move_child(pause_overlay,get_child_count()-1)
	campaign_panel.action.connect(_campaign_action)
	_home()
	if "--campaign-flow-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/campaign_flow_check.gd").new()
		test_runner.run_checks(self)

func _home() -> void:
	screen = "base"
	campaign_panel.show()
	campaign_panel.clear("2026 · 虚拟校园",progress.Campaign.objective(progress.campaign))
	if progress.load_blocked:
		campaign_panel.text(progress.error_message)
		return
	for region in Journey.Regions.NAMES:
		campaign_panel.text(Journey.Regions.NAMES[region]+(" · 渐稳" if progress.campaign.terminals.has(region) else " · 待修复"),20)
	if not progress.active_run.is_empty(): campaign_panel.button("继续探索","continue")
	if not progress.campaign.prologue_done:
		campaign_panel.button("开始序章","prologue")
	elif not progress.campaign.routes_acquired:
		campaign_panel.text("当前 AI：派档案员占位成员取回路线资料。这次教学立即完成，不扣资源，也不会占用普通派遣队。")
		campaign_panel.button("教学派遣","tutorial")
	else:
		for region in Journey.Regions.NAMES:
			campaign_panel.button(Journey.Regions.NAMES[region].split("〔")[0],"region:"+region)
	campaign_panel.button("回忆档案","memories")
	campaign_panel.button("校园成长","growth")
	campaign_panel.button("普通派遣","dispatch")
	campaign_panel.button("主菜单","menu")

func _new_run() -> void:
	if not campaign_enabled:
		super._new_run()
		return
	_home()

func _begin_region(region: String, mode: String = "region") -> void:
	if progress.load_blocked or (mode == "region" and not progress.campaign.routes_acquired): return
	campaign_mode = mode
	journey = Journey.new()
	journey.begin(region,progress.campaign.terminals.size())
	run = RunModel.new()
	run.permanent_hp = progress.level("fitness") * 20
	if mode == "region":
		for id in progress.campaign.characters:
			var role = Content.role_index(id)
			if role >= 0 and not run.roster.has(role): run.roster.append(role)
	formation = [-1,-1,-1,-1,-1,-1]
	equipment = run.shoe_wearer
	phase = "prepare"
	if mode == "prologue": journey.enter(0,progress.campaign.memories)
	if _save_campaign(): _show_journey()

func _save_campaign() -> bool:
	if campaign_mode.is_empty(): return true
	run.formation = formation.duplicate()
	last_save_ok = progress.save_checkpoint(CampaignSave.pack(journey,run,campaign_mode))
	if not last_save_ok:
		var restored = CampaignSave.decode(progress.active_run)
		if not restored.is_empty():
			journey = restored.journey
			run = restored.build
			formation = run.formation.duplicate()
		campaign_panel.show()
		campaign_panel.clear("保存失败",progress.error_message+"。本次操作未完成，请重试。")
		campaign_panel.button("返回基地","base")
	return last_save_ok

func _checkpoint() -> bool:
	if campaign_mode.is_empty(): return super._checkpoint()
	if screen == "battle": journey.data.screen = "battle"
	elif screen == "report":
		journey.data.screen = "report"
		journey.data.won = result_won
	return _save_campaign()

func _continue_run() -> void:
	if progress.active_run.get("kind") != "campaign":
		campaign_mode = ""
		if campaign_enabled: campaign_panel.hide()
		super._continue_run()
		return
	var restored = CampaignSave.decode(progress.active_run)
	if restored.is_empty(): return
	journey = restored.journey
	run = restored.build
	campaign_mode = restored.mode
	formation = run.formation.duplicate()
	equipment = run.shoe_wearer
	if journey.data.screen == "battle": _guard()
	elif journey.data.screen == "report":
		if journey.data.get("won",false): _victory()
		else: _guard()
	else: _show_journey()

func _show_journey() -> void:
	screen = "campaign"
	campaign_panel.show()
	if journey.data.finished:
		_settle_campaign()
	elif journey.data.screen == "reward":
		campaign_panel.clear("选择奖励","只选一份，本局有效。胜利后全员恢复。")
		for i in range(journey.data.offers.size()):
			var offer = journey.data.offers[i]
			campaign_panel.text(offer.title+"："+offer.description)
			campaign_panel.button("选取奖励","reward:"+str(i))
	elif journey.visit.data.is_empty(): campaign_panel.route(journey)
	else:
		campaign_panel.location(journey)
		if campaign_mode == "prologue":
			campaign_panel.text("当前 AI：这里是 2026 年的虚拟校园原型。你是管理员，我与你一起引导知情参与的毕业生人格。先挑战守卫，部署四人后开战。前代把我们新建的内容视作 Bug，持续回滚。")

func _guard() -> void:
	if journey.visit.data.is_empty() or journey.visit.data.guard_won: return
	var place: String = journey.visit.data.place
	var boss: bool = journey.data.step == journey.data.map.size()-1 and campaign_mode == "region"
	run.node = {"id":place,"name":Journey.Regions.PLACES[place],"kind":"boss" if boss else "battle",
		"encounter":1 if boss else 0,"encounter_id":"encounter_final" if boss else "encounter_patrol",
		"power":1.0 if boss else 0.62+journey.data.step*0.08}
	run.stage = 0
	screen = "battle"
	phase = "prepare"
	journey.data.screen = "battle"
	_build_units()
	if _save_campaign(): campaign_panel.hide()

func _after_report() -> void:
	if campaign_mode.is_empty():
		super._after_report()
		return
	if screen != "report": return
	if not result_won:
		run.retries += 1
		_guard()
	else: _victory()

func _victory() -> void:
	journey.visit.data.guard_won = true
	journey.data.screen = "reward"
	if not journey.data.has("offers"):
		var pool = RunModel.Rewards.eligible(run.badge_owned,run.roster,run.inventory,"campus_rewards",run.training)
		pool = pool.filter(func(offer): return offer.operation != "recruit")
		var rng = RandomNumberGenerator.new()
		rng.seed = (journey.data.id+journey.visit.data.place+"reward").hash()
		RunModel.shuffle_with(pool,rng)
		journey.data.offers = pool.slice(0,3).duplicate(true)
	if _save_campaign(): _show_journey()

func _settle_campaign() -> void:
	if progress.settle_region(journey.data.id,journey.data.region,journey.data.temporary,7):
		if progress.save_checkpoint({}):
			campaign_mode = ""
			_home()
	else:
		campaign_panel.clear("结算待重试",progress.error_message)
		campaign_panel.button("重试结算","settle")

func _campaign_action(id: String) -> void:
	if paused or progress.load_blocked: return
	if id == "base":
		if _checkpoint(): _home()
	elif id == "continue": _continue_run()
	elif id == "prologue": _request_campaign_start("library","prologue")
	elif id.begins_with("region:"): _request_campaign_start(id.trim_prefix("region:"),"region")
	elif id.begins_with("confirm:"):
		var parts = id.split(":")
		_begin_region(parts[1],parts[2])
	elif id == "tutorial":
		if progress.complete_tutorial_dispatch(): _home()
		else: campaign_panel.text(progress.error_message)
	elif id.begins_with("enter:"):
		if journey.enter(int(id.trim_prefix("enter:")),progress.campaign.memories) and _save_campaign(): _show_journey()
	elif id == "leave":
		if campaign_mode == "prologue" and journey.visit.can_leave():
			if progress.complete_prologue() and progress.save_checkpoint({}):
				campaign_mode = ""
				_home()
		elif journey.leave():
			journey.data.erase("offers")
			if _save_campaign(): _show_journey()
	elif id.begins_with("spot:"): _hotspot(id.trim_prefix("spot:"))
	elif id.begins_with("reward:"):
		var index = int(id.trim_prefix("reward:"))
		if journey.data.screen != "reward" or journey.visit.data.reward_taken: return
		if index < 0 or index >= journey.data.offers.size(): return
		if run.apply_reward(journey.data.offers[index]):
			journey.visit.data.reward_taken = true
			journey.data.screen = "visit"
			if _save_campaign(): _show_journey()
	elif id == "visit": _show_journey()
	elif id == "settle": _settle_campaign()
	elif id == "memories":
		campaign_panel.clear("回忆档案","系统记录为机制样本，尚无真实照片与共同经历。")
		for place in Journey.Regions.PLACES:
			var count = progress.campaign.memories.filter(func(memory): return memory.begins_with(place+"_")).size()
			campaign_panel.text(Journey.Regions.PLACES[place]+" · 系统记录 %d / 2" % count)
			for memory in progress.campaign.memories:
				if memory.begins_with(place+"_"): campaign_panel.button("查看记录","memory:"+memory)
		if progress.campaign.prologue_done: campaign_panel.button("重看序章","replay_prologue")
		campaign_panel.button("返回基地","base")
	elif id.begins_with("memory:"):
		campaign_panel.clear("系统记录〔占位〕",id.trim_prefix("memory:")+"\n2026 年虚拟校园记录。真实照片及共同经历尚待提供；此处不代表真实纪念内容。")
		campaign_panel.button("返回档案","memories")
	elif id == "replay_prologue":
		campaign_panel.clear("序章 · 2026", "管理员与当前 AI 在虚拟校园原型中构建毕业生人格。大家知情参与修复；前代同源 AI 却把新开发当作 Bug 回滚。三台记忆终端将帮助我们重新解释它的任务。")
		campaign_panel.button("返回档案","memories")
	elif id in ["growth","dispatch"]:
		campaign_panel.hide()
		screen = id
	elif id == "menu": _request_exit("menu")

func _request_campaign_start(region: String, mode: String) -> void:
	if not progress.active_run.is_empty():
		campaign_panel.clear("替换探索","当前探索将被替换；未兑现的临时人物与局内收益会丢失。永久记录保留。")
		campaign_panel.button("开始新局","confirm:"+region+":"+mode)
		campaign_panel.button("返回基地","base")
	else: _begin_region(region,mode)

func _hotspot(id: String) -> void:
	for spot in journey.visit.data.hotspots:
		if spot.id != id: continue
		if spot.kind == "battle":
			_guard()
			return
		if spot.kind == "memory" and not progress.record_memory(id):
			campaign_panel.text(progress.error_message)
			return
		if spot.kind == "person":
			if not run.roster.has(4): run.roster.append(4)
			if not progress.campaign.characters.has("inventor") and not journey.data.temporary.has("inventor"):
				journey.data.temporary.append("inventor")
		journey.visit.view(id)
		if not _save_campaign(): return
		campaign_panel.clear("调查记录",{"memory":"系统记录〔占位〕：这份虚拟校园记录已加入回忆档案。真实照片与说明待提供。",
			"person":"毕业生人格〔占位：发明家〕：我知道自己是虚拟构建，也愿意帮助修复。本局暂时入队；成功完成区域后永久加入出发候选。",
			"system":"当前 AI：前代仍在执行早期目标。我们需要三台记忆终端，才能重新解释目标与限制它的权限。"}[spot.kind])
		campaign_panel.button("返回地点","visit")

func _to_base() -> void:
	if not campaign_enabled:
		super._to_base()
		return
	if _checkpoint():
		_resume_battle()
		_home()

func _gui_input(event: InputEvent) -> void:
	super._gui_input(event)
	if campaign_enabled and screen == "base" and not campaign_panel.visible: _home()

func _create_battle_presentations() -> void:
	if campaign_mode.is_empty(): super._create_battle_presentations()

func _pawn(u: Dictionary, at: Vector2, factor: float = 4) -> void:
	if campaign_mode.is_empty():
		super._pawn(u,at,factor)
		return
	draw_rect(Rect2(at-Vector2(22,54),Vector2(44,54)),Color("71b8dc") if u.side == 0 else Color("df9386"))
	_center(at-Vector2(0,20),"人" if u.side == 0 else "卫",DARK,20)

func _draw_effects() -> void:
	if campaign_mode.is_empty(): super._draw_effects()
