extends Node
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Event = preload("res://game/run/hotspot_event.gd")
const Journey = preload("res://game/run/campaign_journey.gd")
const Campaign = preload("res://game/meta/campaign_state.gd")
var game
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("CHOICE_PAGES: "+label)
func settle() -> void:
	for i in range(6): await get_tree().process_frame
func press(id: String) -> void:
	var button = game.campaign_panel.action_button(id)
	expect(button != null and not button.disabled,"available native action "+id)
	if button == null or button.disabled: return
	var scroll = game.campaign_panel.choice_page.find_child("ChoicesScroll",true,false)
	if scroll != null and scroll.is_ancestor_of(button): game.campaign_panel.choice_page.ensure_button_visible(button)
	await settle()
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = button.get_global_transform_with_canvas()*(button.size*0.5)
		get_viewport().push_input(event,true)
	await settle()
func capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	expect(get_viewport().get_texture().get_image().save_png("res://.godot/choice-%s-%dx%d.png" % [label,resolution.x,resolution.y])==OK,"capture "+label)
func enclosing_card(button: Button) -> PanelContainer:
	var parent := button.get_parent()
	while parent != null and not parent is PanelContainer: parent = parent.get_parent()
	return parent as PanelContainer

func labels() -> String:
	var result := ""
	for label in game.campaign_panel.choice_page.find_children("*","Label",true,false): result += label.text+"\n"
	return result
func lint_graphs() -> void:
	expect(Event.return_configuration_errors().is_empty(),"return switches are valid and final pages cannot trap players")
	for kind in Event.GRAPHS:
		var graph: Dictionary = Event.GRAPHS[kind]
		for id in graph:
			var node: Dictionary = graph[id]
			expect(node.line == "$memory" or Event.definitions.lines.has(node.line),"line reference "+kind+"/"+id)
			var seen: Array = []
			for choice in node.choices:
				expect(not seen.has(choice.id) and (choice.to == "END" or graph.has(choice.to)),"unique valid transition "+kind+"/"+id+"/"+choice.id)
				seen.append(choice.id)
			var pending: Array = [id]
			var visited: Array = []
			var has_exit := false
			while not pending.is_empty():
				var current: String = pending.pop_back()
				if visited.has(current): continue
				visited.append(current)
				if graph[current].choices.is_empty() and Event.can_return({"kind":kind,"node":current}): has_exit = true
				for choice in graph[current].choices:
					if choice.to == "END": has_exit = true
					else: pending.append(choice.to)
			expect(has_exit,"each node has an exit "+kind+"/"+id)
func _ready() -> void:
	lint_graphs()
	game = Scene.instantiate()
	game.progress.path = "res://.godot/choice-check-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await settle()
	game.set_process(false)
	game.progress.campaign.prologue_done = true
	game.progress.campaign.routes_acquired = true
	var legacy: Dictionary = Campaign.fresh()
	legacy.erase("story_flags")
	expect(Campaign.valid(legacy),"legacy permanent facts remain valid")
	expect(not Event.valid_flags({"nested":{}}) and not Event.valid_flags({"":true}),"reject malformed story flags")
	var resolutions := [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)] if "--capture" in OS.get_cmdline_user_args() else [Vector2i(1920,1080)]
	if "--skin-only" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(1920,1080)
		var page = game.campaign_panel.choice_page
		page.present({"tag":"校园补给 · 交互检查","title":"选择一份战利品","description":"同一套组件的聚焦、悬停与不可用状态。","picture":page.PICTURES.reward,"compact":true,"close_id":"state_back","close_label":"返回地点","options":[{"id":"state_focus","label":"选取","title":"当前选择","description":"键盘焦点有独立边缘标记。"},{"id":"state_hover","label":"选取","title":"悬停选择","description":"鼠标移入后同时强调按钮与对应选项。"},{"id":"state_disabled","label":"强化","title":"暂不可用","description":"保留选项说明，按钮与边缘退为灰色。","hint":"训练份数已满","enabled":false}]})
		await settle()
		var first_button: Button = page.buttons[1]
		var hover_button: Button = page.buttons[2]
		first_button.grab_focus()
		await settle()
		expect(first_button.get_theme_stylebox("focus") is StyleBoxTexture,"native focus uses scalable art")
		expect(page.buttons[3].disabled,"disabled option stays inert")
		expect(enclosing_card(first_button).get_theme_stylebox("panel").texture.resource_path.ends_with("card_active.svg"),"keyboard focus marks the matching card")
		var motion := InputEventMouseMotion.new()
		motion.position = hover_button.get_global_transform_with_canvas()*(hover_button.size*0.5)
		get_viewport().push_input(motion,true)
		await settle()
		expect(hover_button.is_hovered(),"real pointer reaches hover state")
		await capture("skin-hover",Vector2i(1920,1080))
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.position = motion.position
		down.pressed = true
		get_viewport().push_input(down,true)
		await settle()
		expect(hover_button.is_pressed(),"real pointer reaches pressed state")
		await capture("skin-pressed",Vector2i(1920,1080))
		down.pressed = false
		get_viewport().push_input(down,true)
		print("CHOICE_SKIN ",checks," checks / ",failures," failures")
		get_tree().quit(1 if failures else 0)
		return
	if "--core-only" in OS.get_cmdline_user_args():
		for resolution in resolutions:
			get_window().size = resolution
			game.progress.campaign.terminals = []
			game._begin_region("library")
			while not game.journey.data.finished:
				game.journey.enter(0,[])
				game.journey.visit.data.guard_won = true
				game.journey.visit.data.reward_taken = true
				game.journey.leave()
			game._settle_campaign()
			await settle()
			expect(labels().contains("记忆终端已回收"),"core recovery uses existing terminal identity")
			await capture("core",resolution)
		print("CHOICE_CORE ",checks," checks / ",failures," failures")
		get_tree().quit(1 if failures else 0)
		return
	for resolution in resolutions:
		get_window().size = resolution
		await settle()
		game.progress.campaign.story_flags = {}
		game._begin_region("library","region","protect")
		game.journey.data.level = 2
		game._campaign_action("enter:0")
		game._hotspot("system")
		await settle()
		expect(game.journey.data.screen == "event" and game.campaign_panel.choice_page.visible,"main hotspot opens modal")
		var sheet: Control = game.campaign_panel.choice_page.sheet
		var rect := sheet.get_global_rect()
		expect(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(rect),"sheet fits "+str(resolution))
		var first: Button = game.campaign_panel.action_button("event:system:intro:trace")
		var scroll: Control = game.campaign_panel.choice_page.find_child("ChoicesScroll",true,false)
		expect(scroll.get_global_rect().encloses(first.get_global_rect()),"first action remains fully visible after focus")
		await capture("event",resolution)
		await press("event:system:intro:trace")
		expect(game.journey.visit.data.event_states.system.node == "evidence","real mouse advances dialogue")
		var stale: Dictionary = game.journey.snapshot()
		game._campaign_action("event:system:intro:trace")
		expect(game.journey.snapshot() == stale,"stale node action cannot advance again")
		await press("event:system:evidence:back")
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		get_viewport().push_input(cancel,true)
		await settle()
		expect(game.journey.data.screen == "visit" and not game.campaign_panel.choice_page.visible and not game.paused,"escape returns to map without menu")
		game._hotspot("system")
		await press("event:system:intro:trace")
		game._continue_run()
		await settle()
		expect(game.journey.visit.data.event_states.system.node == "evidence" and game.journey.data.screen == "event","checkpoint resumes exact unfinished node")
		await press("event:system:evidence:record")
		expect(game.progress.campaign.story_flags.get("rollback_trace",false) and game.progress.campaign.story_flags.rollback_origin == "library:gate","first clue commits qualified map origin")
		await capture("recorded",resolution)
		await press("visit")
		game._begin_region("region_b","region","analysis")
		game.journey.data.level = 2
		game._campaign_action("enter:0")
		# Another physical location with the same canonical hall ID is qualified by map.
		game.journey.visit.data.guard_won = true
		game.journey.visit.data.reward_taken = true
		game._campaign_action("leave")
		game._campaign_action("enter:0")
		game._hotspot("system")
		await settle()
		expect(game.journey.visit.data.event_states.system.node == "linked" and labels().contains("南门"),"different map references earlier clue")
		await capture("linked",resolution)
		await press("event:system:linked:compare")
		await press("event:system:compare:link")
		expect(game.progress.campaign.story_flags.get("rollback_linked",false),"cross-map relation saved")
		await press("visit")
		var memory: String = game.journey.visit.data.hotspots[1].id
		game._hotspot(memory)
		await settle()
		expect(game.progress.campaign.memories.has(memory),"original memory collection remains intact")
		await press("event:"+memory+":intro:permissions")
		await press("visit")
		game._hotspot("person")
		await settle()
		await press("event:person:intro:shield")
		expect(game.campaign_panel.action_button("event:person:shield:formation").disabled and labels().contains("反冲"),"unavailable formation explains program condition")
		await capture("person",resolution)
		await press("visit")
		# Freeze genuine catalog rewards through the existing victory controller.
		game._victory()
		await settle()
		var offers: Array = game.journey.data.offers.duplicate(true)
		game._continue_run()
		await settle()
		expect(game.journey.data.offers == offers,"rewards do not reroll on continue")
		var reward_first: Button = game.campaign_panel.action_button("reward:0")
		var reward_scroll: Control = game.campaign_panel.choice_page.find_child("ChoicesScroll",true,false)
		expect(reward_scroll.get_global_rect().encloses(reward_first.get_global_rect()),"first reward remains fully visible after continue")
		await capture("reward",resolution)
		await press("choice_menu")
		expect(game.paused and game.pause_overlay.visible and game.campaign_panel.choice_page.visible,"menu sits over reward without abandoning it")
		game._resume_battle()
		await press("reward:0")
		if game.journey.data.screen == "reward_owner":
			await capture("owner",resolution)
			await press("reward_back")
			expect(game.journey.data.offers == offers,"owner back retains frozen offers")
			await press("reward:0")
			var chosen := ""
			for button in game.campaign_panel.choice_page.buttons:
				if button.get_meta("action_id","").begins_with("reward_owner:") and not button.disabled: chosen = button.get_meta("action_id"); break
			await press(chosen)
		expect(game.journey.visit.data.reward_taken and not game.campaign_panel.choice_page.visible,"native reward choice applies and closes")
		var build_snapshot: Dictionary = game.run.to_dict()
		game._campaign_action("reward:0")
		expect(game.run.to_dict() == build_snapshot,"reward duplicate action rejected")
		# Reach settlement using explicit traversal fixtures, not a claimed combat win.
		while not game.journey.data.finished:
			if game.journey.visit.data.is_empty(): game.journey.enter(0,[])
			game.journey.visit.data.guard_won = true
			game.journey.visit.data.reward_taken = true
			game.journey.leave()
		var earned_before: int = game.progress.points
		game._settle_campaign()
		await settle()
		expect(game.progress.campaign.terminals.has("region_b") and game.progress.points == earned_before+7,"existing atomic settlement awards once")
		await capture("core",resolution)
		game._settle_campaign()
		expect(game.progress.points == earned_before+7,"reopened settlement cannot pay twice")
		await press("base")
		expect(game.screen == "base" and not game.campaign_panel.choice_page.visible,"core confirmation returns home cleanly")
		var reloaded = game.ProgressModel.new()
		reloaded.path = game.progress.path
		expect(reloaded.read_save() and reloaded.campaign.story_flags.get("rollback_linked",false),"cross-map facts survive disk reload")
	game._begin_region("library","region","protect")
	game._campaign_action("enter:0")
	game._hotspot("person")
	await settle()
	await press("event:person:intro:shield")
	await press("event:person:shield:formation")
	expect(game.journey.data.screen == "visit" and game.formation == game.run.recommended_formation("protect"),"enabled dialogue formation reuses original build command")
	var legacy_visit: Dictionary = game.journey.snapshot()
	legacy_visit.visit.erase("event_states")
	expect(Journey.new().restore(JSON.parse_string(JSON.stringify(legacy_visit))),"legacy visit without dialogue state still restores")
	var state := Event.begin("system","system",{},"library:gate")
	state = Event.choose(state,"trace",{},{}).state
	var first_record := Event.choose(state,"record",{}, {"place":"library:gate"})
	expect(Event.choose(state,"record",first_record.flags,{}).is_empty(),"once-only transition rejects replay even from old node")
	expect(not Event.valid_state({"kind":"system","spot_id":"system","node":"intro","closed":false,"history":["bad"]},{"id":"system","kind":"system"}),"invalid dialogue history rejected")
	game._begin_region("library","region","protect")
	game._campaign_action("enter:0")
	game.run.training[0] = 2
	game._victory()
	var fixed: Dictionary = game.RunModel.Rewards.eligible(false,game.run.roster,game.run.inventory).filter(func(offer): return offer.operation == "combat" and offer.target == "training")[0]
	game.journey.data.offers = [fixed]
	game._save_campaign()
	game._show_journey()
	await settle()
	game._hotspot("person")
	expect(game.journey.data.screen == "reward","stale hotspot action cannot bypass pending reward")
	await press("reward:0")
	expect(game.campaign_panel.action_button("reward_owner:guard").disabled and labels().contains("训练份数已满"),"fixed owner page displays unavailable reason")
	await capture("owner-fixed",Vector2i(get_window().size))
	await press("reward_back")
	expect(game.journey.data.offers == [fixed],"fixed owner back preserves catalog snapshot")
	await press("reward:0")
	await press("reward_owner:archer")
	expect(game.journey.visit.data.reward_taken and game.run.training_count(1)==1,"fixed owner allocation applies once")
	game.campaign_panel.choice_page.present({"title":"长文本验证","description":"运行记录与已发现的线索。".repeat(60),"options":[{"id":"probe","label":"继续","title":"后续选择"}],"close_id":"visit"})
	await settle()
	var long_scroll: ScrollContainer = game.campaign_panel.choice_page.find_child("ChoicesScroll",true,false)
	expect(long_scroll.scroll_vertical == 0 and long_scroll.get_v_scroll_bar().max_value > long_scroll.size.y,"long prose starts at top and can scroll")
	var action: Button = game.campaign_panel.choice_page.buttons.back()
	action.grab_focus()
	await settle()
	expect(long_scroll.get_global_rect().encloses(action.get_global_rect()),"keyboard focus scrolls distant action into view")
	game._show_journey()
	game._begin_region("library","region","protect")
	game._campaign_action("enter:0")
	game._victory()
	game.journey.data.offers = []
	game.journey.data.rewards_exhausted = true
	game._save_campaign()
	game._show_journey()
	await settle()
	await press("reward_continue")
	game._hotspot("person")
	var empty_checkpoint: Dictionary = game.progress.active_run.duplicate(true)
	expect(not preload("res://game/run/campaign_checkpoint.gd").decode(JSON.parse_string(JSON.stringify(empty_checkpoint))).is_empty(),"hotspot after exhausted reward remains a valid checkpoint")
	game._continue_run()
	expect(game.journey.data.screen == "event" and game.progress.active_run == empty_checkpoint,"empty reward followed by hotspot resumes without invalidating save")
	# Real failed write rolls back both checkpoint and flags.
	game._begin_region("library")
	game.journey.data.level = 2
	game._campaign_action("enter:0")
	game._hotspot("system")
	var before: Dictionary = game.progress.to_dict()
	var failed_flags: Dictionary = game.progress.campaign.story_flags.duplicate()
	failed_flags.test_write = true
	game.progress.path = "res://.godot/missing-choice-directory/save.json"
	expect(not game.progress.save_campaign_checkpoint(game.progress.active_run,[],failed_flags) and game.progress.to_dict() == before,"failed save rolls back story and checkpoint together")
	var bad: Dictionary = game.journey.snapshot()
	bad.visit.event_states.system.node = "missing_node"
	expect(not Journey.new().restore(bad),"invalid saved dialogue node rejected")
	print("CHOICE_PAGES ",checks," checks / ",failures," failures")
	get_tree().quit(1 if failures else 0)
