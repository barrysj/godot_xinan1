extends "res://scenes/expedition/meta_hub.gd"
## M1 flow adapter; old random runs retain the existing hub path.
const Journey = preload("res://game/run/campaign_journey.gd")
const CampaignSave = preload("res://game/run/campaign_checkpoint.gd")
var journey = Journey.new()
var campaign_mode = ""
var campaign_panel: PanelContainer
var campaign_enabled = false
var detail_return = "visit"
var reset_pending = false
var debug_enabled = false
var debug_panel: CanvasLayer
const OPERATIONS = ["修正目标","撤销越权","限制写入"]
const FINAL_LINES = ["前代：新增内容不是需要回滚的错误？\n当前 AI：目标是维护一个容纳变化的校园，而不是永远保持初始版本。",
	"前代：我将撤销对管理员新开发的自动覆盖权限。\n管理员：保留你的记忆，停止替我们决定什么应该存在。",
	"记录者：我已理解。对虚拟世界只读，只在记录用途下追加进程日志。\n当前 AI：校园的日常，交还给参与其中的人。"]

func _ready() -> void:
	debug_enabled = "--campus-debug" in OS.get_cmdline_user_args()
	if debug_enabled: progress.path = "user://campus_debug_progress.json"
	if "--debug-check" in OS.get_cmdline_user_args(): progress.path = "res://.godot/debug-check-profile.json"
	if "--profile-reset-check" in OS.get_cmdline_user_args():
		progress.path = "res://.godot/profile-reset-ui.json"
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	super._ready()
	campaign_enabled = not is_test or "--campaign-flow-check" in OS.get_cmdline_user_args()
	if not campaign_enabled: return
	inspector.theme = theme
	deployment.theme = theme
	campaign_panel = preload("res://scenes/expedition/campaign_panel.gd").new()
	add_child(campaign_panel)
	move_child(pause_overlay,get_child_count()-1)
	campaign_panel.action.connect(_campaign_action)
	_home()
	if "--library-environment-preview" in OS.get_cmdline_user_args() or "--library-environment-preview-capture" in OS.get_cmdline_user_args():
		_show_library_environment_preview()
	if debug_enabled:
		debug_panel = preload("res://scenes/expedition/debug_panel.gd").new()
		debug_panel.hub = self
		add_child(debug_panel)
	if "--debug-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/debug_check.gd").new()
		test_runner.run_checks(self)
	if "--profile-reset-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/profile_reset_check.gd").new()
		test_runner.run_checks(self)
	if "--campaign-flow-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/campaign_flow_check.gd").new()
		test_runner.run_checks(self)

func _show_library_environment_preview() -> void:
	if not campaign_enabled or not is_instance_valid(campaign_panel):
		return
	paused = false
	pause_overlay.hide()
	screen = "campaign"
	campaign_panel.show()
	campaign_panel.library_environment_preview()

func _home() -> void:
	reset_pending = false
	screen = "base"
	campaign_panel.show()
	campaign_panel.home(progress,chosen_supply)
	if debug_enabled: campaign_panel.text("DEBUG · 当前使用独立调试存档",18)
	campaign_panel.button("重开存档","reset_profile")

func _input(event: InputEvent) -> void:
	if is_instance_valid(debug_panel):
		if debug_panel.handle_input(event):
			get_viewport().set_input_as_handled()
			return
		if debug_panel.panel.visible: return
	super._input(event)

func _request_exit(destination: String) -> void:
	if is_instance_valid(debug_panel) and debug_panel.panel.visible: debug_panel.close()
	super._request_exit(destination)

func _profile_action(id: String) -> bool:
	if id == "reset_profile" and screen == "base":
		reset_pending = true
		campaign_panel.clear("重开存档", "将清空主线进度、角色解锁、回忆、资源、成长、派遣和当前探索。设置保留。\n确认后先备份当前存档，再从序章开始。")
		campaign_panel.button("取消","reset_cancel")
		campaign_panel.button("确认重开","reset_confirm")
		return true
	if id == "reset_cancel" and reset_pending:
		_home()
		return true
	if id == "reset_confirm" and reset_pending:
		if not progress.restart_profile():
			campaign_panel.text(progress.error_message)
			return true
		campaign_mode = ""
		journey = Journey.new()
		run = RunModel.new()
		formation = run.formation.duplicate()
		equipment = run.shoe_wearer
		chosen_supply = false
		report.clear()
		phase = "prepare"
		checkpoint_error = ""
		last_save_ok = true
		_home()
		campaign_panel.text("新存档已建立。" + ("旧档备份：" + progress.last_backup_path if not progress.last_backup_path.is_empty() else ""),16)
		return true
	return id in ["reset_profile","reset_cancel","reset_confirm"]

func _new_run() -> void:
	if not campaign_enabled:
		super._new_run()
		return
	_home()

func _begin_region(region: String, mode: String = "region") -> void:
	if progress.load_blocked or (mode == "region" and not progress.campaign.routes_acquired): return
	if mode == "finale" and (progress.campaign.terminals.size() != 3 or progress.campaign.restored): return
	campaign_mode = mode
	journey = Journey.new()
	journey.begin(region,progress.campaign.terminals.size())
	run = RunModel.new()
	run.permanent_hp = progress.level("fitness") * 20
	if mode != "prologue" and progress.supply_unlocked and chosen_supply:
		run.badge_owned = true
		run.badge_wearer = 2
	if mode != "prologue":
		for id in progress.campaign.characters:
			var role = Content.role_index(id)
			if role >= 0 and not run.roster.has(role): run.roster.append(role)
	formation = [-1,-1,-1,-1,-1,-1]
	if mode != "prologue":
		formation = progress.campaign.formation.map(func(id): return -1 if id.is_empty() else Content.role_index(id))
	equipment = run.shoe_wearer
	phase = "prepare"
	if mode == "prologue": journey.enter(0,progress.campaign.memories)
	if mode == "finale":
		journey.data.finale_phase = progress.campaign.finale_stage
		journey.enter(0,progress.campaign.memories)
	if _save_campaign(): _show_journey()

func _save_campaign() -> bool:
	if campaign_mode.is_empty(): return true
	run.formation = formation.duplicate()
	var lineup = formation.map(func(role): return "" if role == -1 else Content.role_id(role)) if campaign_mode != "prologue" else []
	last_save_ok = progress.save_campaign_checkpoint(CampaignSave.pack(journey,run,campaign_mode),lineup)
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
		journey.data.report = report.duplicate(true)
		journey.data.elapsed = elapsed
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
		screen = "report"
		result_won = journey.data.won
		report.clear()
		for row in journey.data.get("report",[]): report.append(row.duplicate(true))
		elapsed = float(journey.data.get("elapsed",0))
		run.node = {"name":Journey.Regions.PLACES[journey.visit.data.place],"kind":"battle"}
		campaign_panel.hide()
	else: _show_journey()

func _show_journey() -> void:
	screen = "campaign"
	campaign_panel.show()
	if campaign_mode == "finale":
		if progress.campaign.restored:
			if progress.save_checkpoint({}): campaign_mode = ""
			_ending()
		elif journey.data.screen == "operation":
			campaign_panel.clear("核心存储 · 阶段击破",FINAL_LINES[journey.data.finale_phase])
			campaign_panel.button(OPERATIONS[journey.data.finale_phase],"operation")
		else:
			campaign_panel.clear("终局 · 三台记忆终端", "当前 AI：我们争取修改核心存储的机会。每击破一个节点，就执行一次系统操作。前代无需删除，但必须停止回滚校园。")
			campaign_panel.terminal_finale(progress.campaign.terminals, progress.campaign.finale_stage)
			for i in range(3): campaign_panel.text(OPERATIONS[i]+(" · 已提交" if i < progress.campaign.finale_stage else " · 待执行"))
			campaign_panel.button("节点整备","finale_battle")
			campaign_panel.button("返回基地","base")
		return
	if journey.data.finished:
		_settle_campaign()
	elif journey.data.screen == "reward":
		campaign_panel.rewards(journey.data.offers)
	elif journey.data.screen == "reward_owner":
		campaign_panel.reward_owner(journey.data.pending_offer,run.roster,run)
	elif journey.visit.data.is_empty(): campaign_panel.route(journey)
	else:
		campaign_panel.location(journey,campaign_mode == "prologue")

func _guard() -> void:
	if journey.visit.data.is_empty() or journey.visit.data.guard_won: return
	var place: String = journey.visit.data.place
	var boss: bool = (journey.data.step == journey.data.map.size()-1 and campaign_mode == "region") or campaign_mode == "finale"
	run.node = {"id":place,"name":Journey.Regions.PLACES[place],"kind":"boss" if boss else "battle",
		"encounter":1 if boss else 0,"encounter_id":"encounter_final" if boss else "encounter_patrol",
		"power":1.0 if boss else 0.62+journey.data.step*0.08}
	if campaign_mode == "finale":
		run.node.name = "核心节点 %d · %s" % [journey.data.finale_phase+1,OPERATIONS[journey.data.finale_phase]]
		run.node.power = 0.82 + 0.08 * journey.data.finale_phase
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
	if campaign_mode == "finale":
		journey.data.screen = "operation"
		if _save_campaign(): _show_journey()
		return
	journey.data.screen = "reward"
	if not journey.data.has("offers"):
		var pool = RunModel.Rewards.eligible(run.badge_owned,run.roster,run.inventory,"campus_rewards",run.training,run.combat_rewards)
		pool = pool.filter(func(offer): return offer.operation != "recruit")
		var rng = RandomNumberGenerator.new()
		rng.seed = (journey.data.id+journey.visit.data.place+"reward").hash()
		RunModel.shuffle_with(pool,rng)
		journey.data.offers = pool.slice(0,3).duplicate(true)
	if _save_campaign(): _show_journey()

func _finish_journey_reward(offer: Dictionary, owner_id: String = "") -> void:
	journey.data.last_reward = offer.title+"："+offer.description
	if not owner_id.is_empty(): journey.data.last_reward += "\n强化对象："+RunModel.Content.character(RunModel.Content.role_index(owner_id)).display_name
	journey.visit.data.reward_taken = true
	journey.data.screen = "visit"
	journey.data.erase("pending_offer")
	if _save_campaign(): _show_journey()

func _settle_campaign() -> void:
	var first_clear = not progress.campaign.terminals.has(journey.data.region)
	var recruits = journey.data.temporary.filter(func(id): return not progress.campaign.characters.has(id))
	if progress.settle_region(journey.data.id,journey.data.region,journey.data.temporary,7):
		if progress.save_checkpoint({}):
			campaign_mode = ""
			screen = "campaign"
			campaign_panel.show()
			campaign_panel.clear("终端已回收" if first_clear else "探索完成","已回到安全区域，所有收益已保存。")
			if first_clear: campaign_panel.terminal_reveal(journey.data.region)
			else: campaign_panel.terminal_progress(progress.campaign.terminals)
			campaign_panel.text("修复资源 +7。"+("发明家已永久加入，下一次出发可在队伍中选择。" if not recruits.is_empty() else ""))
			var count = progress.campaign.terminals.size()
			if first_clear: campaign_panel.text({1:"图书馆派遣现已开放。下一步：寻找第二台记忆终端。",2:"体育馆派遣现已开放。下一步：取回最后一台记忆终端。",3:"三台终端已齐备。下一步：返回基地，接入终端，修复核心。"}[count])
			campaign_panel.button("返回基地","base")
	else:
		campaign_panel.clear("结算待重试",progress.error_message)
		campaign_panel.button("重试结算","settle")

func _memory_text(id: String) -> String:
	var place = id.get_slice("_system_",0)
	var title = Journey.Regions.PLACES.get(place,"校园")
	if id.ends_with("_2"):
		return title+" · 权限记录\n新建内容不断被旧系统回滚。当前 AI 建议保留记录，借助三台记忆终端重新解释旧系统的任务。\n——虚拟校园系统档案"
	return title+" · 运行记录\n这里仍保留着校园的空间数据，但通路被守卫封锁。解除封锁后，管理员可以继续修复。\n——虚拟校园系统档案"

func _campaign_action(id: String) -> void:
	if paused: return
	if _profile_action(id): return
	if progress.load_blocked: return
	if id == "base":
		if _checkpoint(): _home()
	elif id == "continue": _continue_run()
	elif id == "prologue": _request_campaign_start("library","prologue")
	elif id == "finale": _request_campaign_start("library","finale")
	elif id == "finale_battle": _guard()
	elif id == "operation": _finale_operation()
	elif id == "ending": _ending()
	elif id.begins_with("region:"): _request_campaign_start(id.trim_prefix("region:"),"region")
	elif id.begins_with("confirm:"):
		var parts = id.split(":")
		_begin_region(parts[1],parts[2])
	elif id == "tutorial":
		if progress.complete_tutorial_dispatch(): _home()
		else: campaign_panel.text(progress.error_message)
	elif id == "supply":
		chosen_supply = not chosen_supply
		_home()
	elif id.begins_with("enter:"):
		if journey.enter(int(id.trim_prefix("enter:")),progress.campaign.memories) and _save_campaign(): _show_journey()
	elif id == "leave":
		if campaign_mode == "prologue" and journey.visit.can_leave():
			if progress.complete_prologue() and progress.save_checkpoint({}):
				campaign_mode = ""
				_home()
		elif journey.leave():
			journey.data.erase("offers")
			journey.data.erase("last_reward")
			if _save_campaign(): _show_journey()
	elif id.begins_with("spot:"): _hotspot(id.trim_prefix("spot:"))
	elif id.begins_with("reward:"):
		var index = int(id.trim_prefix("reward:"))
		if journey.data.screen != "reward" or journey.visit.data.reward_taken: return
		if index < 0 or index >= journey.data.offers.size(): return
		var offer: Dictionary = journey.data.offers[index]
		if offer.operation == "combat" and RunModel.Rewards.combat_needs_owner(offer.target):
			journey.data.pending_offer = offer.duplicate(true)
			journey.data.screen = "reward_owner"
			if _save_campaign(): _show_journey()
		elif run.apply_reward(offer): _finish_journey_reward(offer)
	elif id.begins_with("reward_owner:"):
		if journey.data.screen != "reward_owner": return
		if run.apply_reward(journey.data.pending_offer,id.trim_prefix("reward_owner:")):
			var offer: Dictionary = journey.data.pending_offer
			journey.data.erase("pending_offer")
			_finish_journey_reward(offer,id.trim_prefix("reward_owner:"))
	elif id == "reward_back":
		journey.data.erase("pending_offer")
		journey.data.screen = "reward"
		if _save_campaign(): _show_journey()
	elif id == "visit": _show_journey()
	elif id == "photo":
		var memory = preload("res://resources/content/library_memory.tres")
		if memory.photograph != null and progress.record_memory(memory.id):
			detail_return = "visit"
			for spot in journey.visit.data.hotspots:
				if spot.kind == "memory": journey.visit.view(spot.id)
			if _save_campaign(): campaign_panel.photograph(memory)
	elif id in ["photo_zoom","photo_fit"]:
		campaign_panel.photograph(preload("res://resources/content/library_memory.tres"),id == "photo_zoom",detail_return)
	elif id == "settle": _settle_campaign()
	elif id == "memories":
		campaign_panel.clear("回忆档案","已保存的虚拟校园系统记录。随时重看，不影响主线进度。")
		for place in Journey.Regions.PLACES:
			var count = progress.campaign.memories.filter(func(memory): return memory.begins_with(place+"_")).size()
			campaign_panel.text(Journey.Regions.PLACES[place]+" · 系统记录 %d / 2" % count)
			for memory in progress.campaign.memories:
				if memory.begins_with(place+"_"): campaign_panel.button("查看记录","memory:"+memory)
		if progress.campaign.prologue_done: campaign_panel.button("重看序章","replay_prologue")
		campaign_panel.button("返回基地","base")
	elif id.begins_with("memory:"):
		var memory = preload("res://resources/content/library_memory.tres")
		if id.trim_prefix("memory:") == memory.id and memory.photograph != null:
			detail_return = "memories"
			campaign_panel.photograph(memory,false,"memories")
			return
		campaign_panel.clear("校园系统记录",_memory_text(id.trim_prefix("memory:")))
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
		campaign_panel.clear("调查记录",{"memory":_memory_text(id)+"\n\n已保存到回忆档案。",
			"person":"发明家（虚拟伙伴）：我知道自己是虚拟构建，也愿意帮助修复。本局暂时入队；成功完成区域后永久加入出发候选。",
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
	# Reuse the existing identity and idle frame without playing an animation.
	var texture: Texture2D = u.portrait
	var dimensions = Vector2(16,16) * factor
	var anchor = Vector2(0.5,0.875)
	var animation = u.battle_animation
	if animation != null and animation.frames != null and animation.frames.has_animation("idle") and animation.frames.get_frame_count("idle") > 0:
		texture = animation.frames.get_frame_texture("idle",0)
		dimensions = animation.display_size * factor / 4.0
		anchor = animation.anchor
	var tint = Color.WHITE if u.hp > 0 else Color(0.6,0.6,0.6,0.35)
	draw_texture_rect(texture,Rect2(at-dimensions*anchor,dimensions),false,tint)
	var side_color = Color("4AAFD0") if u.side == 0 else Color("DF7468")
	draw_line(at+Vector2(-26,8),at+Vector2(26,8),side_color,4)
	if u.shield > 0 and u.hp > 0: draw_arc(at-Vector2(0,24),38,PI,TAU,24,Color("8dd7e7"),3)
	if u.side == 0 and u.role == equipment: _tile(dungeon,8,10,at+Vector2(24,-3),1.3)

func _draw_report() -> void:
	super._draw_report()
	if campaign_mode.is_empty(): return
	var next_step = "领取一份奖励，再返回地点。可以继续调查，也可以离开。"
	if campaign_mode == "finale": next_step = "节点已击破：接下来执行系统操作。"
	if not result_won: next_step = "阵容与装备保留。调整前排与后排，再挑战一次。"
	_pixel_panel(Rect2(30,78,1210,38),PAPER)
	_text(Vector2(48,104),next_step,DARK,19)
	_flow_button(Rect2(405,587,470,66),("系统操作" if campaign_mode == "finale" else "领奖") if result_won else "重新编队")

func _draw_effects() -> void:
	if campaign_mode.is_empty(): super._draw_effects()

func _draw_unit(u: Dictionary) -> void:
	super._draw_unit(u)
	if campaign_mode.is_empty(): return
	var at = _unit_center(u)
	if at.y > 520:
		_pixel_panel(Rect2(at+Vector2(-46,-68),Vector2(92,22)),PAPER)
		_center(at+Vector2(0,-52),u.name if u.hp > 0 else "已退场",DARK,14)

func _draw() -> void:
	super._draw()
	if not campaign_mode.is_empty() and screen == "battle":
		draw_set_transform(origin,0,Vector2.ONE*scale_factor)
		_pixel_panel(Rect2(230,25,530,48),Color("202027"))
		var heading = "序章 · 部署教学"
		if campaign_mode == "region": heading = "%d / 4 · %s" % [journey.data.step+1,run.node.name]
		elif campaign_mode == "finale": heading = "终局 %d / 3 · %s" % [journey.data.finale_phase+1,OPERATIONS[journey.data.finale_phase]]
		_text(Vector2(244,54),heading,PAPER,22)
		if not is_instance_valid(code_panel) or not code_panel.visible: _pixel_panel(Rect2(28,96,1208,32),Color("202027"))
		var goal = "目标：击败守卫，领取奖励后返回地点。青色为我方，红色为敌方。"
		if campaign_mode == "prologue": goal = "目标：突破校门封锁。部署四名同学后开战；胜利后取回校园路线。"
		elif campaign_mode == "finale": goal = "目标：击破核心节点，然后执行「%s」。" % OPERATIONS[journey.data.finale_phase]
		if is_instance_valid(code_panel) and code_panel.visible: code_panel.summary.tooltip_text = goal
		else: _text(Vector2(42,118),goal,PAPER,17)

func _finale_operation() -> void:
	if campaign_mode != "finale" or journey.data.screen != "operation" or not journey.visit.data.guard_won: return
	var stage: int = journey.data.finale_phase + 1
	if not progress.complete_finale_stage(stage):
		campaign_panel.text(progress.error_message)
		return
	if stage == 3:
		if progress.save_checkpoint({}): campaign_mode = ""
		_ending()
	else:
		journey.data.finale_phase = stage
		journey.visit.begin("gate",3,progress.campaign.memories,stage)
		journey.data.screen = "visit"
		if _save_campaign(): _show_journey()

func _ending() -> void:
	screen = "campaign"
	campaign_panel.show()
	campaign_panel.clear("校园 · 日常恢复", "三处区域已经稳定，校园重新接受管理员与毕业生人格共同创造的日常。\n前代重新理解了指令，成为只读记录者；它无法修改或回滚所观察的世界，只能追加记录日志。\n\n记录进程继续运行。很久以后，它依然没有停止。")
	campaign_panel.button("返回校园","base")
