extends "res://scenes/expedition/meta_hub.gd"
## M1 flow adapter; old random runs retain the existing hub path.
const Journey = preload("res://game/run/campaign_journey.gd")
const CampaignSave = preload("res://game/run/campaign_checkpoint.gd")
var tutorial_guide: Control
var journey = Journey.new()
var campaign_mode = ""
var campaign_panel: PanelContainer
var campaign_enabled = false
var dispatch_board: Control
var departure_request: Dictionary = {}
var departure_items: Array = ["supply","converter"]
var departure_party: Array = []
var detail_return = "visit"
var reset_pending = false
var debug_enabled = false
var debug_battle_preview = false
var debug_panel: CanvasLayer
var debug_battle_difficulty := "normal"
var debug_battle_tuning: Dictionary = {}
var battle_context: CanvasLayer
var battle_preview_results: Control
const BattleTuning = preload("res://game/debug/battle_tuning.gd")
const DebugCommands = preload("res://game/debug/campus_debug.gd")
const OPERATIONS = ["修正目标","撤销越权","限制写入"]
const FINAL_LINES = ["前代：新增内容不是需要回滚的错误？\n当前 AI：目标是维护一个容纳变化的校园，而不是永远保持初始版本。",
	"前代：我将撤销对管理员新开发的自动覆盖权限。\n管理员：保留你的记忆，停止替我们决定什么应该存在。",
	"记录者：我已理解。对虚拟世界只读，只在记录用途下追加进程日志。\n当前 AI：校园的日常，交还给参与其中的人。"]

func _ready() -> void:
	debug_enabled = "--campus-debug" in OS.get_cmdline_user_args()
	debug_battle_preview = debug_enabled and "--debug-battle" in OS.get_cmdline_user_args()
	if debug_enabled: progress.path = "user://campus_debug_progress.json"
	if debug_battle_preview: progress.path = "res://.godot/debug-battle-preview.json"
	if "--debug-check" in OS.get_cmdline_user_args(): progress.path = "res://.godot/debug-check-profile.json"
	if "--preview-result-check" in OS.get_cmdline_user_args(): progress.path = "res://.godot/battle-preview-result-check-profile.json"
	if "--battle-preparation-check" in OS.get_cmdline_user_args(): progress.path = "res://.godot/battle-preparation-check-profile.json"
	if "--battle-tuning-check" in OS.get_cmdline_user_args(): progress.path = "res://.godot/battle-tuning-check-profile.json"
	if "--battle-report-check" in OS.get_cmdline_user_args(): progress.path = "res://.godot/battle-report-check-%d.json" % Time.get_ticks_usec()
	if "--profile-reset-check" in OS.get_cmdline_user_args():
		progress.path = "res://.godot/profile-reset-ui.json"
	if "--startup-capture" in OS.get_cmdline_user_args():
		progress.path = "res://.godot/game-launcher/timing-profile-%d.json" % Time.get_ticks_usec()
		add_child.call_deferred(load("res://tools/development/startup_capture.gd").new())
	theme = preload("res://resources/theme/theme-main.tres").duplicate()
	theme.default_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	super._ready()
	campaign_enabled = not is_test or "--campaign-flow-check" in OS.get_cmdline_user_args()
	if not campaign_enabled: return
	_hide_version_overlay.call_deferred()
	inspector.theme = theme
	deployment.theme = theme
	campaign_panel = preload("res://scenes/expedition/campaign_panel.gd").new()
	add_child(campaign_panel)
	move_child(pause_overlay,get_child_count()-1)
	campaign_panel.action.connect(_campaign_action)
	tutorial_guide = preload("res://scenes/expedition/tutorial_guide.gd").new()
	tutorial_guide.game = self
	add_child(tutorial_guide)
	# Focused regression harnesses drive simulation without tutorial input.
	var test_scene := get_tree().current_scene.scene_file_path if get_tree().current_scene != null else ""
	if (test_scene.contains("_check") or OS.get_cmdline_user_args().has("--campaign-flow-check")) and not test_scene.contains("tutorial_check"):
		tutorial_guide.skipped = true
	_home()
	if "--library-environment-preview" in OS.get_cmdline_user_args() or "--library-environment-preview-capture" in OS.get_cmdline_user_args():
		_show_library_environment_preview()
	if "--campus-environment-preview" in OS.get_cmdline_user_args() or "--campus-environment-preview-capture" in OS.get_cmdline_user_args():
		_show_campus_environment_preview()
	if debug_enabled:
		debug_panel = preload("res://scenes/expedition/debug_panel.gd").new()
		debug_panel.hub = self
		add_child(debug_panel)
		battle_context = preload("res://scenes/expedition/battle_context_editor.gd").new()
		battle_context.hub = self
		add_child(battle_context)
	if debug_battle_preview:
		battle_preview_results = preload("res://scenes/expedition/battle_preview_results.gd").new()
		battle_preview_results.hub = self
		add_child(battle_preview_results)
		_launch_debug_battle()
	if "--preview-result-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/battle_preview_result_check.gd").new()
		test_runner.run_checks(self)
	if "--battle-preparation-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/battle_preparation_check.gd").new()
		test_runner.run_checks(self)
	if "--battle-tuning-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/battle_tuning_check.gd").new()
		test_runner.run_checks(self)
	if "--debug-battle-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/debug_battle_check.gd").new()
		test_runner.run_checks(self)
	if "--debug-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/debug_check.gd").new()
		test_runner.run_checks(self)
	if "--profile-reset-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/profile_reset_check.gd").new()
		test_runner.run_checks(self)
	if "--campaign-flow-check" in OS.get_cmdline_user_args():
		test_runner = load("res://scenes/expedition/campaign_flow_check.gd").new()
		test_runner.run_checks(self)

func _launch_debug_battle() -> void:
	# Use the ordinary prologue encounter, deployment, checkpoint and simulation.
	# A fresh preview never consumes or depends on either player's progress file.
	var lineup: Array = RunModel.new().formation.duplicate()
	_begin_region("library", "prologue")
	if not last_save_ok: return
	formation = lineup
	_guard()
	if not last_save_ok: return
	if screen == "battle" and phase == "prepare":
		print("DEBUG_BATTLE_PREPARED encounter=", encounter_id, " allies=", _living(0).size())
	queue_redraw()

func _preparation_hint(guide: String) -> String:
	return "拖动角色换位 · 点击角色更换与改属性 · 调整好后开战" if debug_enabled else guide

func _ally_unit(role: int, slot: int) -> Dictionary:
	var unit: Dictionary = super._ally_unit(BattleTuning.ally_role(self,role),slot)
	unit.deployment_role = role
	return unit

func _debug_ally_unit(role: int, slot: int) -> Dictionary:
	return super._ally_unit(role,slot)

func _can_deploy_role(role: int, slot: int) -> bool:
	for other in formation:
		if other < 0 or other == role or other == formation[slot]: continue
		if BattleTuning.ally_role(self,other) == BattleTuning.ally_role(self,role): return false
	return true

func _deployment_definition(role: int):
	return Content.character(BattleTuning.ally_role(self,role))

func _inspection_unit(role: int) -> Dictionary:
	for unit in units:
		if unit.side == 0 and unit.get("deployment_role",unit.role) == role: return unit
	return super._inspection_unit(role)

func _encounter_definition():
	var group = super._encounter_definition()
	if not BattleTuning.active(self): debug_battle_tuning.clear()
	return BattleTuning.encounter(self,group)

func _battle_backdrop() -> Texture2D:
	if BattleTuning.active(self) and not debug_battle_tuning.get("background","").is_empty():
		background_crop = Rect2(0.085,0.123,0.83,0.833)
		return load(BattleTuning.BACKGROUNDS[debug_battle_tuning.background].path)
	return super._battle_backdrop()

func _build_units() -> void:
	super._build_units()
	if not debug_enabled: return
	# Apply only enemy multipliers, after the current encounter's ordinary power.
	var difficulty: Dictionary = DebugCommands.Difficulties.preset(debug_battle_difficulty)
	for unit in units:
		if unit.side != 1: continue
		unit.max_hp = roundf(unit.max_hp * difficulty.health)
		unit.hp = unit.max_hp
		unit.atk = roundf(unit.atk * difficulty.attack)
	BattleTuning.apply_stats(self)

func _show_library_environment_preview() -> void:
	if not campaign_enabled or not is_instance_valid(campaign_panel):
		return
	paused = false
	pause_overlay.hide()
	screen = "campaign"
	campaign_panel.show()
	campaign_panel.library_environment_preview()

func _hide_version_overlay() -> void:
	var version := get_node_or_null("/root/GGT_Transitions/Version") as Control
	if version != null and not debug_enabled:
		var was_visible := version.visible
		version.hide()
		tree_exiting.connect(func():
			if is_instance_valid(version): version.visible = was_visible)

func _show_campus_environment_preview() -> void:
	if not campaign_enabled or not is_instance_valid(campaign_panel): return
	paused = false
	pause_overlay.hide()
	screen = "campaign"
	campaign_panel.show()
	campaign_panel.campus_environment_preview()

func _home() -> void:
	reset_pending = false
	screen = "base"
	campaign_panel.show()
	campaign_panel.home(progress,chosen_supply)
	if progress.campaign.routes_acquired:
		preload("res://scenes/expedition/expanded_campus_map.gd").warm_texture("day" if progress.campaign.restored else "anomaly")
	if debug_enabled: campaign_panel.text("DEBUG · 当前使用独立调试存档",18)

func _input(event: InputEvent) -> void:
	if is_instance_valid(dispatch_board): return
	if debug_battle_preview and screen == "report":
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_F8):
			if event.is_action_pressed("ui_cancel"): battle_preview_results.quit_button.grab_focus()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(campaign_panel) and is_instance_valid(campaign_panel.home_overlay) and not paused:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			if reset_pending: _profile_action("reset_cancel")
			else: campaign_panel.close_home_overlay()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(debug_panel):
		if debug_panel.handle_input(event):
			get_viewport().set_input_as_handled()
			return
		if debug_panel.panel.visible: return
	if not paused and is_instance_valid(campaign_panel) and campaign_panel.choice_page.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	super._input(event)

func _request_exit(destination: String) -> void:
	if is_instance_valid(battle_context): battle_context.close()
	if is_instance_valid(debug_panel) and debug_panel.panel.visible: debug_panel.close()
	super._request_exit(destination)

func _profile_action(id: String) -> bool:
	if id == "reset_profile" and screen == "base":
		reset_pending = true
		campaign_panel.show_home_reset_confirmation()
		return true
	if id == "reset_cancel" and reset_pending:
		_home()
		return true
	if id == "reset_confirm" and reset_pending:
		if not progress.restart_profile():
			campaign_panel.show_home_reset_confirmation(progress.error_message)
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

func _begin_region(region: String, mode: String = "region", starting_strategy: String = "", supplies: Variant = null, starters: Variant = null) -> void:
	if progress.load_blocked or (mode == "region" and not progress.campaign.routes_acquired): return
	if mode == "finale" and (progress.campaign.terminals.size() != 3 or progress.campaign.restored): return
	if mode == "region" and starting_strategy.is_empty(): starting_strategy = "protect"
	var selected_items: Array = ["supply","converter"] if supplies == null else supplies
	if mode != "prologue" and not progress.Commissions.preparation_reason(progress.commission_unlocks,selected_items).is_empty(): return
	var starting_ids: Array = _starting_pair(starting_strategy) if starters == null else starters
	var eligible := _eligible_characters()
	if mode == "region" and (starting_ids.size() != 2 or starting_ids[0] == starting_ids[1] or not starting_ids.all(func(id): return eligible.has(id))): return
	var next_journey = Journey.new()
	if not next_journey.begin(region,progress.campaign.terminals.size(),null,mode):
		campaign_panel.text("区域配置无效，请先在 Godot 校验并保存。")
		return
	campaign_mode = mode
	journey = next_journey
	run = RunModel.new()
	run.permanent_hp = 0
	if mode != "prologue":
		for id in progress.commission_unlocks:
			var effect: Dictionary = progress.Commissions.find(id)
			if effect.kind == "item" and not run.dispatch_items.has(effect.value): run.dispatch_items.append(effect.value)
			if effect.kind == "buff" and not run.dispatch_buffs.has(effect.value): run.dispatch_buffs.append(effect.value)
		for key in run.code_supplies: run.code_supplies[key] = 0
		for id in selected_items: run.code_supplies[id] += 1
	if mode != "prologue":
		for id in progress.campaign.characters:
			var role = Content.role_index(id)
			if role >= 0 and not run.roster.has(role): run.roster.append(role)
	formation = [-1,-1,-1,-1,-1,-1]
	if mode != "prologue":
		formation = progress.campaign.formation.map(func(id): return -1 if id.is_empty() else Content.role_index(id))
	if starting_strategy in ["analysis","protect"]:
		if not run.configure_starting_strategy(starting_strategy): return
		formation = run.formation.duplicate()
	elif starting_strategy == "keep":
		var has_scanner: bool = formation.has(Content.role_index("analyst"))
		run.code_programs = ["disconnect","repair"] if has_scanner else ["redirect","repair"]
	if mode == "region":
		run.expedition_party = true
		run.eligible_characters = eligible.duplicate()
		run.roster.clear()
		for id in starting_ids: run.roster.append(Content.role_index(id))
		formation = [-1,-1,-1,-1,-1,-1]
		var starter_slots: Array = [3,0] if starting_ids[0] in ["analyst","archer","healer","inventor"] else [0,3]
		for i in run.roster.size(): formation[starter_slots[i]] = run.roster[i]
		for gear in run.inventory:
			if not run.roster.has(run.inventory[gear]): run.inventory[gear] = -1
		if starting_strategy == "keep": run.code_programs = ["disconnect","repair"] if starting_ids.has("analyst") else ["redirect","repair"]
	equipment = run.shoe_wearer
	phase = "prepare"
	if mode == "prologue": journey.enter(0,progress.campaign.memories)
	if mode == "finale":
		journey.data.finale_phase = progress.campaign.finale_stage
		journey.enter(0,progress.campaign.memories)
	var flags: Dictionary = progress.campaign.story_flags.duplicate(true)
	if mode == "region": flags["tutorial_route_selected"] = true
	if _save_campaign(flags): _show_journey()

func _save_campaign(story_flags: Variant = null) -> bool:
	if campaign_mode.is_empty(): return true
	run.formation = formation.duplicate()
	var lineup = formation.map(func(role): return "" if role == -1 else Content.role_id(role)) if campaign_mode != "prologue" else []
	last_save_ok = progress.save_campaign_checkpoint(CampaignSave.pack(journey,run,campaign_mode),lineup,story_flags)
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
		journey.data.report_details = report_details.duplicate(true)
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
		report_details = journey.data.get("report_details",{}).duplicate(true)
		result_won = journey.data.won
		report.clear()
		for row in journey.data.get("report",[]): report.append(row.duplicate(true))
		elapsed = float(journey.data.get("elapsed",0))
		run.node = {"name":journey.title(journey.visit.data.place),"kind":"battle"}
		screen = "report"
		report_view.present(report_details,report,elapsed)
		campaign_panel.hide()
	else: _show_journey()

func _show_journey() -> void:
	screen = "campaign"
	campaign_panel.show()
	if _needs_recruit():
		_show_recruitment()
		return
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
	elif journey.data.screen == "event":
		campaign_panel.location(journey,campaign_mode == "prologue")
		var state: Dictionary = journey.visit.data.event_states[journey.data.event_spot]
		var context := _event_context()
		campaign_panel.hotspot_event(preload("res://game/run/hotspot_event.gd").page(state,progress.campaign.story_flags,context),state,context)
	elif journey.data.screen == "reward":
		campaign_panel.location(journey,campaign_mode == "prologue")
		campaign_panel.rewards(journey.data.offers,run)
	elif journey.data.screen == "reward_owner":
		campaign_panel.location(journey,campaign_mode == "prologue")
		campaign_panel.reward_owner(journey.data.pending_offer,run.roster,run)
	elif journey.visit.data.is_empty(): campaign_panel.route(journey,progress.campaign.restored)
	else:
		campaign_panel.location(journey,campaign_mode == "prologue")

func _guard() -> void:
	if journey.visit.data.is_empty() or journey.visit.data.guard_won: return
	if _needs_recruit():
		_show_recruitment()
		return
	var place: String = journey.visit.data.place
	var boss: bool = (journey.data.step == journey.data.map.size()-1 and campaign_mode == "region") or campaign_mode == "finale"
	var configured: Dictionary = journey.stop()
	var encounter: String = configured.encounter_id if campaign_mode == "region" else "encounter_final" if boss else "encounter_patrol"
	run.node = {"id":place,"name":journey.title(place),"kind":"boss" if boss else "battle",
		"encounter":0 if encounter == "encounter_patrol" else 1,"encounter_id":encounter,
		"power":float(configured.power) if campaign_mode == "region" else 1.0 if boss else 0.62}
	if run.expedition_party:
		# Opening pressure follows the guaranteed team size, not metagame stats.
		run.node.power *= [0.52,0.78,1.0,1.0][mini(3,int(journey.data.step))]
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
	if debug_battle_preview:
		_preview_result_action("retry")
		return
	if campaign_mode.is_empty():
		super._after_report()
		return
	if screen != "report": return
	if not result_won:
		run.retries += 1
		_guard()
	else: _victory()

func _victory() -> void:
	if debug_battle_preview:
		# Debug skip uses the same report, never the campaign reward transition.
		phase = "result"
		_capture_report(true)
		screen = "report"
		_checkpoint()
		return
	journey.visit.data.guard_won = true
	if campaign_mode == "finale":
		journey.data.screen = "operation"
		if _save_campaign(): _show_journey()
		return
	journey.data.screen = "reward"
	if not journey.data.has("offers"):
		var rng = RandomNumberGenerator.new()
		rng.seed = (journey.data.id+journey.visit.data.place+"reward").hash()
		journey.data.offers = run.draw_rewards(rng,false).duplicate(true)
		journey.data.rewards_exhausted = journey.data.offers.is_empty()
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
	if progress.settle_region(journey.data.id,journey.data.region,journey.data.temporary,7,formation.map(func(role): return "" if role == -1 else Content.role_id(role))):
		if progress.save_checkpoint({}):
			campaign_mode = ""
			screen = "campaign"
			campaign_panel.show()
			var detail := "修复资源 +7。"+("发明家已永久加入，下一次出发可在队伍中选择。" if not recruits.is_empty() else "")
			var count: int = progress.campaign.terminals.size()
			if first_clear: detail += "\n\n"+{1:"可以回基地用修复资源完成派遣。下一步：寻找第二台记忆终端。",2:"可以回基地解锁新的准备物品或同伴资格。下一步：取回最后一台记忆终端。",3:"三台终端已齐备。下一步：返回基地，接入终端，修复核心。"}[count]
			else: detail += "\n\n该区域的记忆终端已经回收，本次不会重复获得终端。"
			campaign_panel.core_recovery(journey.data.region,first_clear,progress.campaign.terminals,detail)
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
	# A modal event owns location actions; quitting/saving still preserves its checkpoint.
	if screen == "campaign" and journey.data.get("screen") == "event" and id not in ["visit","choice_menu","base","continue"] and not id.begins_with("event:"): return
	if id == "hub_menu":
		campaign_panel.show_home_menu()
		return
	if id == "hub_close": return
	if _profile_action(id): return
	if progress.load_blocked: return
	if id.begins_with("starter:"):
		if screen != "departure" or departure_request.is_empty() or departure_request.mode != "region": return
		var character_id := id.trim_prefix("starter:")
		if not _eligible_characters().has(character_id): return
		if departure_party.has(character_id): departure_party.erase(character_id)
		elif departure_party.size() < 2: departure_party.append(character_id)
		_show_departure()
		return
	if id.begins_with("join:"):
		if screen != "recruit" or not _needs_recruit(): return
		var character_id := id.trim_prefix("join:")
		var role := Content.role_index(character_id)
		if not run.eligible_characters.has(character_id) or run.roster.has(role): return
		run.roster.append(role)
		var preferred_slots: Array = [0,1,2,3,4,5] if character_id in ["guard","striker"] else [3,4,5,0,1,2]
		for slot in preferred_slots:
			if formation[slot] == -1:
				formation[slot] = role
				break
		if _save_campaign(): _show_journey()
		return
	if id.begins_with("prep:"):
		if departure_request.is_empty(): return
		var item_id := id.trim_prefix("prep:")
		var next := departure_items.duplicate()
		next.append(item_id)
		if progress.Commissions.preparation_reason(progress.commission_unlocks,next).is_empty(): departure_items = next
		_show_departure()
		return
	if id.begins_with("unpack:"):
		if departure_request.is_empty(): return
		departure_items.erase(id.trim_prefix("unpack:"))
		_show_departure()
		return
	if id == "depart":
		if departure_request.is_empty(): return
		var request := departure_request.duplicate()
		if request.mode == "region" and departure_party.size() != 2: return
		_begin_region(request.region,request.mode,request.strategy,departure_items,departure_party if request.mode == "region" else null)
		if last_save_ok: departure_request.clear()
		return
	if id == "choice_menu":
		_open_pause()
		return
	if id.begins_with("event:"):
		_event_choice(id)
		return
	if id == "campus_preview_base":
		_home()
	elif id == "base":
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
		campaign_panel.starting_strategy(parts[1],parts[2],parts[2] != "prologue")
	elif id.begins_with("strategy:"):
		var parts = id.split(":")
		if parts.size() != 4 or parts[3] not in ["analysis","protect","keep"]: return
		if parts[1] not in Journey.Regions.IDS or parts[2] not in ["region","prologue","finale"] or (parts[2] == "prologue" and parts[3] == "keep"): return
		if parts[2] == "prologue": _begin_region(parts[1],parts[2],parts[3])
		else:
			departure_request = {"region":parts[1],"mode":parts[2],"strategy":parts[3]}
			departure_items = ["supply","converter"]
			departure_party = _starting_pair(parts[3])
			_show_departure()
	elif id == "formation:protect":
		if screen != "campaign" or journey.data.get("screen") != "visit" or not run.code_programs.has("redirect"): return
		var suggested: Array = run.recommended_formation("protect")
		if suggested.is_empty(): return
		formation = suggested
		run.formation = suggested.duplicate()
		if _save_campaign(): _show_journey()
	elif id == "tutorial":
		_open_dispatch_board()
	elif id == "supply":
		chosen_supply = not chosen_supply
		_home()
	elif id == "codex": _open_codex()
	elif id == "passage":
		if screen != "campaign" or journey.data.get("screen") != "visit": return
		var target: Dictionary = journey.passage()
		if target.get("enabled",false): _campaign_action(str(target.action))
	elif id.begins_with("scene:"):
		if screen != "campaign" or journey.data.get("screen") != "visit": return
		if journey.current_scene().id == id.trim_prefix("scene:"): return
		if journey.switch_scene(id.trim_prefix("scene:")) and _save_campaign():
			var previous_focus := get_viewport().gui_get_focus_owner()
			campaign_panel._close_library_detail()
			if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
			campaign_panel.exploration_board.change_scene()
	elif id.begins_with("enter:"):
		if journey.enter(int(id.trim_prefix("enter:")),progress.campaign.memories):
			_ensure_starting_partner()
			if _save_campaign(): _show_journey()
	elif id == "leave":
		if campaign_mode == "prologue" and journey.visit.can_leave():
			if progress.complete_prologue() and progress.save_checkpoint({}):
				campaign_mode = ""
				_home()
		elif journey.leave():
			journey.data.erase("offers")
			journey.data.erase("rewards_exhausted")
			journey.data.erase("last_reward")
			if _save_campaign(): _show_journey()
	elif id.begins_with("spot:"): _hotspot(id.trim_prefix("spot:"))
	elif id == "reward_refresh":
		if screen != "campaign" or journey.data.get("screen") != "reward" or not journey.visit.data.guard_won or journey.visit.data.reward_taken: return
		var rng := RandomNumberGenerator.new()
		rng.seed = (journey.data.id+journey.visit.data.place+"dispatch-refresh").hash()
		var refreshed: Array = run.refresh_rewards(rng,journey.data.offers)
		if refreshed.is_empty(): return
		journey.data.offers = refreshed
		journey.data.rewards_exhausted = false
		if _save_campaign(): _show_journey()
	elif id == "reward_continue":
		if journey.data.screen != "reward" or not journey.visit.data.guard_won or journey.visit.data.reward_taken or not journey.data.get("rewards_exhausted",false) or not journey.data.get("offers",[]).is_empty(): return
		journey.visit.data.reward_taken = true
		journey.data.last_reward = "当前没有适用的新奖励；本次整备完成。"
		journey.data.screen = "visit"
		if _save_campaign(): _show_journey()
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
		if journey.data.get("screen") != "reward_owner": return
		journey.data.erase("pending_offer")
		journey.data.screen = "reward"
		if _save_campaign(): _show_journey()
	elif id == "visit":
		if journey.data.get("screen") == "event":
			var spot_id: String = journey.data.event_spot
			var returned := preload("res://game/run/hotspot_event.gd").return_to_location(journey.visit.data.event_states[spot_id])
			if returned.is_empty():
				campaign_panel.choice_page.notify_return_blocked()
				return
			journey.visit.data.event_states[spot_id] = returned
			journey.data.screen = "visit"
			journey.data.erase("event_spot")
			if not _save_campaign(): return
		_show_journey()
	elif id == "photo":
		var memory = load("res://resources/content/library_memory.tres")
		if memory.photograph != null and progress.record_memory(memory.id):
			detail_return = "visit"
			for spot in journey.visit.data.hotspots:
				if spot.kind == "memory": journey.visit.view(spot.id)
			if _save_campaign(): campaign_panel.photograph(memory)
	elif id in ["photo_zoom","photo_fit"]:
		campaign_panel.photograph(load("res://resources/content/library_memory.tres"),id == "photo_zoom",detail_return)
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
		var memory = load("res://resources/content/library_memory.tres")
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
		_open_dispatch_board()
	elif id == "menu": _request_exit("menu")
	elif id == "map_region": _open_map_region()
	elif id == "route_preview":
		campaign_panel.close_home_overlay(false)
		var preview = preload("res://scenes/expedition/campus_route_preview.tscn").instantiate()
		add_child(preview)
		campaign_panel.hide()
		preview.closed.connect(func():
			preview.queue_free()
			_home())

func _open_dispatch_board() -> void:
	if is_instance_valid(dispatch_board): return
	campaign_panel.hide()
	screen = "dispatch_board"
	dispatch_board = preload("res://scenes/expedition/dispatch_board.gd").new()
	dispatch_board.progress = progress
	add_child(dispatch_board)
	dispatch_board.closed.connect(func():
		dispatch_board.queue_free()
		dispatch_board = null
		_home())

func _show_departure() -> void:
	screen = "departure"
	campaign_panel.show()
	var focus := get_viewport().gui_get_focus_owner()
	var focus_id: String = focus.get_meta("action_id","") if is_instance_valid(focus) else ""
	var used := 0
	var items: Array = []
	for item in progress.Commissions.PREPARATIONS:
		used += departure_items.count(item.id)*int(item.cost)
		var next := departure_items.duplicate()
		next.append(item.id)
		var reason: String = progress.Commissions.preparation_reason(progress.commission_unlocks,next)
		items.append({"id":item.id,"name":item.name,"cost":item.cost,"unlocked":progress.Commissions.has_preparation(progress.commission_unlocks,item),"enabled":reason.is_empty(),"reason":reason,"description":RunModel.CodeCatalog.item(item.id).description})
	campaign_panel.preparation({"select_party":departure_request.mode == "region","characters":_eligible_characters(),"selected_party":departure_party,
		"selected_items":departure_items,"remaining":progress.Commissions.PREPARATION_POINTS-used,"points":progress.Commissions.PREPARATION_POINTS,"slots":progress.Commissions.PREPARATION_SLOTS,"items":items,"focus_id":focus_id,
		"can_depart":progress.Commissions.preparation_reason(progress.commission_unlocks,departure_items).is_empty() and (departure_request.mode != "region" or departure_party.size() == 2)})

func _starting_pair(strategy: String) -> Array:
	if strategy == "analysis": return ["analyst","striker"]
	if strategy == "keep":
		var previous: Array = progress.campaign.formation.filter(func(id): return not id.is_empty() and _eligible_characters().has(id))
		if previous.size() >= 2: return previous.slice(0,2)
	return ["guard","healer"]

func _eligible_characters() -> Array:
	var eligible: Array = progress.Campaign.BASE_CHARACTERS.duplicate()
	for id in progress.campaign.characters:
		if Content.role_index(id) >= 0 and not eligible.has(id): eligible.append(id)
	return eligible

func _needs_recruit() -> bool:
	return campaign_mode == "region" and run.expedition_party and not journey.visit.data.is_empty() and not journey.visit.data.guard_won and run.roster.size() < mini(4,int(journey.data.step)+2)

func _show_recruitment() -> void:
	screen = "recruit"
	campaign_panel.show()
	campaign_panel.location(journey,false)
	var options: Array = []
	for id in run.eligible_characters:
		var role := Content.role_index(id)
		if run.roster.has(role): continue
		var person = Content.character(role)
		options.append({"id":"join:"+id,"title":person.display_name,"label":"邀请","icon":person.portrait,"icon_size":58,
			"description":person.description,"hint":"加入本次探索 · 可在战前调整站位"})
	campaign_panel.choice_page.present({"tag":"途中事件 · 同伴会合","title":"选择一位同行的同学","description":"在%s遇到了同伴。邀请一人后继续前进，队伍将扩充到%d人。" % [journey.title(journey.visit.data.place),run.roster.size()+1],
		"picture":"res://assets/art/ui/dispatch/asset_001/campus.png","caption":journey.title(journey.visit.data.place)+" · 集合地点","body_label":"会合记录","options_label":"可邀请的同伴",
		"compact":true,"options":options,"status":"当前队伍 %d / 4 · 选择后自动保存" % run.roster.size(),"close_id":"base","close_label":"返回基地"})

func _open_map_region() -> void:
	if not progress.campaign.routes_acquired: return
	var preview = preload("res://scenes/expedition/expanded_campus_preview.tscn").instantiate()
	preview.name = "CampaignMapRegionPreview"
	preview.campaign_selectable = true
	preview.completed_regions = progress.campaign.terminals.duplicate()
	add_child(preview)
	campaign_panel.hide()
	preview.board.set_state("day" if progress.campaign.restored else "anomaly")
	preview.closed.connect(func():
		preview.queue_free()
		_home())
	preview.region_picked.connect(func(region: String):
		preview.queue_free()
		campaign_panel.show()
		_request_campaign_start(region, "region"))

func _request_campaign_start(region: String, mode: String) -> void:
	if not progress.active_run.is_empty():
		campaign_panel.clear("替换探索","当前探索将被替换；未兑现的临时人物与局内收益会丢失。永久记录保留。")
		campaign_panel.button("开始新局","confirm:"+region+":"+mode)
		campaign_panel.button("返回基地","base")
	else: campaign_panel.starting_strategy(region,mode,mode != "prologue")

func _ensure_starting_partner() -> void:
	if run.expedition_party: return
	if campaign_mode != "region" or journey.data.step != 0 or journey.visit.data.is_empty() or not run.code_programs.has("redirect") or run.roster.has(Content.role_index("inventor")): return
	if not journey.visit.data.hotspots.any(func(spot): return spot.kind == "person"):
		journey.visit.data.hotspots.append({"id":"person","kind":"person","character":"inventor"})

func _hotspot(id: String) -> void:
	if screen != "campaign" or journey.data.get("screen") != "visit": return
	for spot in journey.visit.data.hotspots:
		if spot.id != id: continue
		if spot.kind == "battle":
			_guard()
			return
		if spot.kind == "memory" and not progress.record_memory(id):
			campaign_panel.text(progress.error_message)
			return
		if spot.kind == "person" and not run.expedition_party:
			if not run.roster.has(4): run.roster.append(4)
			if not progress.campaign.characters.has("inventor") and not journey.data.temporary.has("inventor"):
				journey.data.temporary.append("inventor")
		journey.visit.view(id)
		var states: Dictionary = journey.visit.data.get("event_states",{})
		if not states.has(id) or states[id].closed:
			states[id] = preload("res://game/run/hotspot_event.gd").begin(spot.kind,id,progress.campaign.story_flags,_event_context().place)
		journey.visit.data.event_states = states
		journey.data.event_spot = id
		journey.data.screen = "event"
		if _save_campaign(): _show_journey()

func _event_context() -> Dictionary:
	var presentation = preload("res://game/run/campus_presentation.gd")
	var origin: String = progress.campaign.story_flags.get("rollback_origin","")
	var origin_title := "之前的地点"
	if origin.contains(":"):
		origin_title = presentation.title(origin.get_slice(":",0),origin.get_slice(":",1))
	return {"place":journey.data.region+":"+journey.visit.data.place,
		"location_title":journey.title(journey.visit.data.place),"origin":origin_title,
		"expedition_party":run.expedition_party,"can_form_protect":not run.recommended_formation("protect").is_empty(),
		"programs":run.code_programs,"memory":_memory_text(journey.data.get("event_spot",""))+"\n\n已保存到回忆档案。"}

func _event_choice(id: String) -> void:
	if screen != "campaign" or journey.data.get("screen") != "event": return
	var parts := id.split(":")
	if parts.size() != 4 or parts[1] != journey.data.event_spot: return
	var state: Dictionary = journey.visit.data.event_states[parts[1]]
	if parts[2] != state.node: return # Reject stale node buttons and rapid duplicate transitions.
	var outcome := preload("res://game/run/hotspot_event.gd").choose(state,parts[3],progress.campaign.story_flags,_event_context())
	if outcome.is_empty(): return
	journey.visit.data.event_states[parts[1]] = outcome.state
	if outcome.state.closed:
		journey.data.screen = "visit"
		journey.data.erase("event_spot")
	if outcome.command == "formation:protect":
		var suggested: Array = run.recommended_formation("protect")
		if not suggested.is_empty(): formation = suggested
	if _save_campaign(outcome.flags): _show_journey()

func _to_base() -> void:
	if not campaign_enabled:
		super._to_base()
		return
	if _checkpoint():
		_resume_battle()
		_home()

func _gui_input(event: InputEvent) -> void:
	if debug_battle_preview and screen == "report":
		# Old painted reward/menu hitboxes cannot leak through the two buttons.
		if event is InputEventMouse: accept_event()
		return
	super._gui_input(event)
	if campaign_enabled and screen == "base" and not campaign_panel.visible: _home()

func _sync_battle_page_visibility() -> void:
	super._sync_battle_page_visibility()
	var terminal: bool = debug_battle_preview and screen == "report" and not leaving
	if is_instance_valid(battle_preview_results): battle_preview_results.visible = terminal
	if is_instance_valid(debug_panel): debug_panel.entry.visible = not terminal and not debug_panel.panel.visible

func _preview_result_action(id: String) -> void:
	if not debug_battle_preview or screen != "report" or leaving: return
	if id == "quit":
		pending_exit = "quit"
		# Preview settings are temporary. Use the existing quit primitive without
		# another checkpoint or a campaign exit/menu dialog.
		_leave_without_save()
	elif id == "retry":
		var node: Dictionary = run.node.duplicate(true)
		if not DebugCommands.execute(self,"restart"):
			# Failed Campaign saves restore a build without its transient node.
			run.node = node
			phase = "result"
			screen = "report"
			campaign_panel.hide()
			battle_preview_results.show_error("重开未完成："+progress.error_message)
		queue_redraw()

func _report_subtitle() -> String:
	return "试玩已结束。本次阵容与配置保留；重新战斗返回整备，准备好再开战。" if debug_battle_preview else super._report_subtitle()

func _draw_header_actions() -> void:
	if debug_battle_preview and screen == "report": _text(Vector2(936,52),"战斗试玩",GOLD,18)
	else: super._draw_header_actions()

func _draw_report_actions() -> void:
	if not debug_battle_preview: super._draw_report_actions()

func _draw_report() -> void:
	super._draw_report()
	if debug_battle_preview or campaign_mode.is_empty(): return
	var next_step = "领取一份奖励，再返回地点。可以继续调查，也可以离开。"
	if campaign_mode == "finale": next_step = "节点已击破：接下来执行系统操作。"
	if not result_won: next_step = "阵容与装备保留。调整前排与后排，再挑战一次。"
	_pixel_panel(Rect2(30,78,1210,38),PAPER)
	_text(Vector2(48,104),next_step,DARK,19)
	_flow_button(Rect2(405,587,470,66),("系统操作" if campaign_mode == "finale" else "领奖") if result_won else "重新编队")

func _draw_effects() -> void:
	if campaign_mode.is_empty(): super._draw_effects()

func _draw() -> void:
	super._draw()
	if not campaign_mode.is_empty() and screen == "battle":
		draw_set_transform(origin,0,Vector2.ONE*scale_factor)
		_pixel_panel(Rect2(230,25,530,48),Color("202027"))
		var heading = "序章 · 部署教学"
		if campaign_mode == "region": heading = "%d / %d · %s" % [journey.data.step+1,journey.data.map.size(),run.node.name]
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
		var core_stop: String = journey.data.map[0][0]
		journey.visit.begin(core_stop,3,progress.campaign.memories,stage,journey.stop(core_stop).hotspot_template)
		journey.visit.data.scene_id = Journey.PlaceScenes.entries(journey.stop(core_stop))[0].id
		journey.data.screen = "visit"
		if _save_campaign(): _show_journey()

func _ending() -> void:
	screen = "campaign"
	campaign_panel.show()
	campaign_panel.clear("校园 · 日常恢复", "三处区域已经稳定，校园重新接受管理员与毕业生人格共同创造的日常。\n前代重新理解了指令，成为只读记录者；它无法修改或回滚所观察的世界，只能追加记录日志。\n\n记录进程继续运行。很久以后，它依然没有停止。")
	campaign_panel.button("返回校园","base")

func _process(delta: float) -> void:
	if is_instance_valid(tutorial_guide):
		tutorial_guide.update()
		if tutorial_guide.hold and screen == "battle":
			queue_redraw()
			return
	super._process(delta)

