extends Node
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Event = preload("res://game/run/hotspot_event.gd")
const Checkpoint = preload("res://game/run/campaign_checkpoint.gd")
var game
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("EVENT_RETURN: "+label)

func settle() -> void:
	for i in range(6): await get_tree().process_frame

func press(id: String, enabled: bool = true) -> void:
	var button: Button = game.campaign_panel.action_button(id)
	expect(button != null and button.disabled != enabled,"native button state "+id)
	if button == null: return
	game.campaign_panel.choice_page.ensure_button_visible(button)
	await settle()
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = button.get_global_transform_with_canvas()*(button.size*0.5)
		get_viewport().push_input(event,true)
	await settle()

func input_action(id: String) -> void:
	var event := InputEventAction.new()
	event.action = id
	event.pressed = true
	get_viewport().push_input(event,true)
	await settle()

func capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await get_tree().create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	expect(get_viewport().get_texture().get_image().save_png("res://.godot/event-return-%s-%dx%d.png" % [label,resolution.x,resolution.y]) == OK,"capture "+label)

func config_checks() -> void:
	var original: Dictionary = Event.definitions
	var probe := {"kind":"system","node":"intro"}
	expect(Event.return_configuration_errors().is_empty(),"production policy config valid")
	Event.definitions = original.duplicate(true)
	Event.GRAPHS = Event.definitions.graphs
	Event.definitions.event_settings.system.allow_return = false
	expect(not Event.can_return(probe),"event default can forbid return")
	Event.GRAPHS.system.intro.allow_return = true
	expect(Event.can_return(probe),"node can override event default")
	expect(Event.can_return({"kind":"system","node":"permissions"}),"final read-only node overrides locked event")
	Event.GRAPHS.system.permissions.allow_return = false
	expect(not Event.return_configuration_errors().is_empty(),"reject final page without choice or exit")
	Event.GRAPHS.system.intro.allow_return = "true"
	expect(not Event.can_return(probe) and not Event.return_configuration_errors().is_empty(),"malformed boolean is never treated as permission")
	Event.definitions = original.duplicate(true)
	Event.GRAPHS = Event.definitions.graphs
	Event.definitions.erase("event_settings")
	for graph in Event.GRAPHS.values():
		for node in graph.values(): node.erase("allow_return")
	expect(Event.can_return(probe),"legacy content defaults to permitted return")
	Event.definitions = original
	Event.GRAPHS = original.graphs
	for kind in Event.GRAPHS:
		for node in Event.GRAPHS[kind].values():
			expect(not node.choices.any(func(choice): return choice.id == "leave"),"no duplicated navigation choice "+kind)

func _ready() -> void:
	config_checks()
	game = Scene.instantiate()
	game.progress.path = "res://.godot/event-return-test-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await settle()
	game.set_process(false)
	game.progress.campaign.prologue_done = true
	game.progress.campaign.routes_acquired = true
	var resolutions := [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)] if "--capture" in OS.get_cmdline_user_args() else [Vector2i(1920,1080)]
	for resolution in resolutions:
		get_window().size = resolution
		game.progress.campaign.story_flags = {}
		game._begin_region("library","region","analysis")
		game.journey.data.level = 2
		game._campaign_action("enter:0")
		game._hotspot("system")
		await settle()
		var page: Control = game.campaign_panel.choice_page
		expect(not game.campaign_panel.action_button("visit").disabled,"intro permits return")
		expect(game.campaign_panel.action_button("event:system:intro:leave") == null,"later choice removed from visible page")
		var intro: Dictionary = game.journey.snapshot()
		game._campaign_action("event:system:intro:leave")
		expect(game.journey.snapshot() == intro,"old navigation action cannot complete the event")
		await press("visit")
		expect(game.journey.data.screen == "visit" and not game.journey.visit.data.event_states.system.closed,"ordinary return preserves unfinished node")
		game._hotspot("system")
		await settle()
		await press("event:system:intro:trace")
		var close: Button = game.campaign_panel.action_button("visit")
		expect(close.disabled and close.tooltip_text.contains("必须完成选择"),"round two is disabled with reason")
		expect(page.close_reason != null and page.close_reason.visible,"blocked reason stays visible without hover")
		expect(get_viewport().gui_get_focus_owner() == game.campaign_panel.action_button("event:system:evidence:record"),"disabled return does not skip first eligible choice")
		var locked: Dictionary = game.journey.snapshot()
		var saved: Dictionary = game.progress.active_run.duplicate(true)
		var build: Dictionary = game.run.to_dict()
		await press("visit",false)
		expect(game.journey.snapshot() == locked,"real click on disabled return has no effect")
		await input_action("ui_cancel")
		expect(game.journey.snapshot() == locked and page.visible and not game.paused,"Esc stays in locked event without opening menu")
		game._campaign_action("visit")
		game._campaign_action("leave")
		game._campaign_action("spot:person")
		game._hotspot("person")
		expect(game.journey.snapshot() == locked and game.run.to_dict() == build,"backend blocks return and stale location actions")
		expect(game.progress.active_run == saved,"blocked actions do not rewrite frozen checkpoint")
		await get_tree().create_timer(0.22).timeout
		expect(page.close_reason.modulate.a == 1.0,"blocked feedback settles")
		await capture("locked",resolution)
		game._continue_run()
		await settle()
		expect(game.journey.snapshot() == locked and game.campaign_panel.action_button("visit").disabled,"continue restores exact locked round and frozen hotspots")
		expect(not Checkpoint.decode(JSON.parse_string(JSON.stringify(game.progress.active_run))).is_empty(),"locked node works with original checkpoint codec")
		var reloaded = game.ProgressModel.new()
		reloaded.path = game.progress.path
		expect(reloaded.read_save() and Checkpoint.decode(reloaded.active_run).journey.snapshot() == locked,"disk reload preserves exact locked round and visit")
		game._campaign_action("base")
		await settle()
		expect(game.screen == "base" and game.progress.active_run == saved,"saving home retains locked checkpoint")
		game._campaign_action("continue")
		await settle()
		expect(game.journey.snapshot() == locked and game.campaign_panel.action_button("visit").disabled,"home continue restores locked return permission")
		game._campaign_action("event:system:intro:trace")
		expect(game.journey.snapshot() == locked,"stale previous-round choice rejected")
		if resolution == Vector2i(1920,1080):
			page.present({"title":"长文本返回限制检查","description":"事件记录保持从开头阅读。".repeat(60),"compact":true,"close_id":"visit","close_enabled":false,"options":[{"id":"probe","label":"继续","title":"阅读后的选择"}]})
			await settle()
			var scroll: ScrollContainer = page.find_child("ChoicesScroll",true,false)
			expect(scroll.scroll_vertical == 0 and get_viewport().gui_get_focus_owner() == scroll,"locked long prose starts at top with reader focus")
			await input_action("ui_focus_next")
			var next: Button = page.buttons.back()
			expect(get_viewport().gui_get_focus_owner() == next and scroll.get_global_rect().encloses(next.get_global_rect()),"keyboard deliberately reaches distant choice")
			game._show_journey()
			await settle()
			var real_path: String = game.progress.path
			game.progress.path = "res://.godot/missing-event-return-directory/save.json"
			game._campaign_action("event:system:evidence:record")
			expect(not game.last_save_ok and game.journey.snapshot() == locked and game.progress.active_run == saved and not game.progress.campaign.story_flags.get("rollback_trace",false),"failed confirmation rolls back node, clue and frozen checkpoint")
			game.progress.path = real_path
			game._show_journey()
			await settle()
		await press("event:system:evidence:record")
		expect(game.progress.campaign.story_flags.get("rollback_trace",false) and not game.campaign_panel.action_button("visit").disabled,"confirmed choice saves clue and next round permits return")
		if resolution == Vector2i(1920,1080): await capture("unlocked",resolution)
		if resolution == Vector2i(1920,1080):
			var unlocked: Dictionary = game.journey.snapshot()
			var real_path: String = game.progress.path
			game.progress.path = "res://.godot/missing-event-return-directory/save.json"
			game._campaign_action("visit")
			expect(not game.last_save_ok and game.journey.snapshot() == unlocked,"failed return save does not complete or abandon the current round")
			game.progress.path = real_path
			game._show_journey()
			await settle()
		await press("event:system:recorded:permissions")
		expect(page.buttons.size() == 1 and not page.buttons[0].disabled,"read-only final page has one header return and no duplicate options")
		await input_action("ui_cancel")
		expect(game.journey.data.screen == "visit" and game.journey.visit.data.event_states.system.closed,"return completes final reader node")
		game._hotspot("system")
		await settle()
		expect(game.journey.visit.data.event_states.system.node == "known","completed event reopens from existing known-clue branch")
		await press("visit")
	print("EVENT_RETURN ",checks," checks / ",failures," failures")
	get_tree().quit(1 if failures else 0)
