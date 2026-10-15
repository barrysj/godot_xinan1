extends Node
var game
var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("TUTORIAL: "+message)
		print("SAVE_ERROR ",game.progress.error_message," last=",game.last_save_ok," flags=",game.progress.campaign.story_flags)
		print("STATE ",game.screen," ",game.journey.data.get("screen")," guide=",game.tutorial_guide.step_id)
		for b in game.campaign_panel.find_children("*","Button",true,false):
			if b.is_visible_in_tree(): print("BUTTON ",b.get_meta("action_id","")," disabled=",b.disabled)
		get_tree().quit(1)
func frame() -> void:
	await get_tree().create_timer(0.25).timeout
	await get_tree().process_frame
	game.tutorial_guide.update()
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://tutorial-"+label+".png" if OS.has_feature("web") else "res://.godot/tutorial-"+label+".png")
func click_control(control: Control) -> void:
	expect(is_instance_valid(control),"target exists")
	if not is_instance_valid(control): return
	click(control.get_global_rect().get_center())
func click(at: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
func action(prefix: String) -> void:
	click_control(game.tutorial_guide.action(game.campaign_panel,prefix))
	await frame()
func _ready() -> void:
	game = preload("res://scenes/expedition/expedition.tscn").instantiate()
	game.progress.path = "user://tutorial-check-%d.json" % Time.get_ticks_usec()
	add_child(game)
	game.set_process(false)
	await frame()
	var guide = game.tutorial_guide
	expect(guide.visible and guide.step_id == "prologue","fresh save points at prologue")
	await action("prologue")
	await action("strategy:library:prologue:"+("protect" if "--protect" in OS.get_cmdline_user_args() else "analysis"))
	expect(guide.step_id == "hotspot_memory","map points at exploration hotspot")
	await shot("hotspot")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "hotspot_action","hotspot opens detail action")
	await action("spot:")
	for i in range(12):
		if game.journey.data.get("screen") != "event": break
		await action("event:" if guide.action(game.campaign_panel,"event:") != null else "visit")
	await frame()
	expect(guide.step_id == "hotspot_battle","investigation leads to guard")
	click_control(guide.target)
	await frame()
	await action("spot:")
	expect(game.screen == "battle" and guide.step_id == "formation","guard opens original deployment")
	await shot("formation")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "formation_slot","selected card points at a legal cell")
	click(guide.target_rect.get_center())
	await frame()
	expect(guide.step_id == "start","real deployment change enables start guidance")
	click(guide.target_rect.get_center())
	await frame()
	expect(game.phase == "battle" and guide.hold,"first battle is held for controls")
	var before: float = game.elapsed
	game._process(1)
	expect(game.elapsed == before,"tutorial hold freezes simulation")
	click(guide.target_rect.get_center())
	await frame(); await frame()
	expect(game.paused and guide.step_id == "resume","manual pause then resume instruction")
	click(guide.target_rect.get_center())
	await frame(); await frame()
	expect(not game.paused and guide.step_id == "speed","resume leads to speed")
	click(guide.target_rect.get_center())
	await frame(); await frame()
	expect(guide.step_id == "item" and game.speed != 1,"speed changed through real input")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "item_type","item detail points at a useful code type")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "item_use","code selection leads to use")
	await shot("item")
	click_control(guide.target)
	await frame(); await frame()
	expect(game.simulation.item_uses.has("supply"),"real item consumed")
	game.code_panel.pointer = Vector2(-1000,-1000)
	for tick in range(1600):
		game._process(0.05)
		if guide.step_id == "hack": break
	expect(guide.step_id == "hack","natural combat generates enough code")
	await frame()
	await shot("hack")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "hack_release","program click requests confirmation")
	await shot("release")
	expect(not guide.card.get_global_rect().intersects(game.code_panel.program_preview.get_global_rect()),"guide leaves program details visible")
	click_control(guide.target)
	await frame(); await frame()
	expect(not game.simulation.program_uses.is_empty() and not guide.hold,"real hack releases tutorial hold")
	game.code_panel.pointer = Vector2(-1000,-1000)
	for tick in range(6000):
		game._process(0.05)
		if game.screen == "report": break
	expect(game.screen == "report" and game.result_won,"tutorial encounter completes normally")
	await frame()
	click(guide.target_rect.get_center())
	await frame()
	await action("reward:")
	if game.journey.data.screen == "reward_owner": await action("reward_owner:")
	expect(game.journey.visit.can_leave(),"reward unlocks exit")
	await frame()
	click_control(guide.target)
	await frame()
	expect(game.progress.campaign.prologue_done and guide.step_id == "dispatch","exit returns to dispatch guidance")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "staff_slot","dispatch asks for staff")
	await shot("dispatch")
	click_control(guide.target)
	await frame()
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "commission","staff selected; highlight free commission")
	click_control(guide.target)
	await frame()
	for i in range(120):
		await frame()
		if guide.step_id == "receipt": break
	expect(game.progress.campaign.routes_acquired and guide.step_id == "receipt","dispatch unlock and receipt")
	click_control(guide.target)
	await frame()
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "campus","base points at campus map")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "route","map asks for a route")
	await shot("route")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "route_confirm","route highlights confirmation")
	click_control(guide.target)
	await frame()
	await action("strategy:")
	await action("depart")
	expect(game.campaign_mode == "region" and game.progress.campaign.story_flags.get("tutorial_route_selected",false),"first route starts and guide completion saved")
	expect(not guide.visible,"guide does not repeat in regular region")
	var restored = game.ProgressModel.new()
	restored.path = game.progress.path
	expect(restored.read_save() and restored.campaign.story_flags.get("tutorial_route_selected",false),"guide completion survives profile reload")
	game._begin_region("library","prologue","protect")
	game._guard()
	game._start()
	await frame()
	guide.battle_step = 3
	game.paused = true
	guide.update()
	expect(guide.step_id == "resume_extra","manual pause during items remains recoverable")
	game.paused = false
	guide.skipped = true
	guide.update()
	expect(not guide.hold and not guide.visible,"skip releases tutorial hold without changing player pause")
	print("TUTORIAL_CHECK checks=",checks," failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)
