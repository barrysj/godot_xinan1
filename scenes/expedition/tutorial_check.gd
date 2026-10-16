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
	get_viewport().warp_mouse(at)
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
	expect(guide.target == game.deployment.start_button and guide.target.is_visible_in_tree(),"Start points at visible native button")
	expect(not game.code_panel.dock.visible,"Combat dock is hidden during deployment")
	expect(not game.code_panel.selection_box.get_global_rect().intersects(game.deployment.hand.get_global_rect()),"Loadout selectors never overlap character cards")
	await shot("start")
	click(guide.target_rect.get_center())
	await frame()
	expect(game.phase == "battle" and guide.hold,"first battle is held for controls")
	for dimensions in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = dimensions
		await frame(); await frame()
		var actual: Rect2 = guide._control_bounds(game.code_panel.pause_control)
		expect(guide.target_rect.grow(-7).is_equal_approx(actual),"Pause highlight follows actual control after resize")
		expect(not Rect2(guide.card.position,guide.card.size).intersects(guide.target_rect),"Guide never covers pause target")
		expect(guide.focus_regions[0].encloses(actual),"Dimmer leaves actual target clear")
		expect(Rect2(guide.card.position,guide.card.size).grow(1).has_point(guide.connector[0]),"Arrow starts at instruction card")
		expect(guide.connector.size() == 2,"Guide uses one straight arrow without elbows")
	await shot("pause")
	get_window().size = Vector2i(1920,1080)
	await frame(); await frame()
	var before: float = game.elapsed
	game._process(1)
	expect(game.elapsed == before,"tutorial hold freezes simulation")
	click(guide.target_rect.get_center())
	await frame(); await frame()
	expect(game.paused and guide.step_id == "resume","manual pause then resume instruction")
	click(guide.target_rect.get_center())
	await frame(); await frame()
	expect(not game.paused and guide.step_id == "speed","resume leads to speed")
	expect(guide.target_rect.grow(-7).is_equal_approx(guide._control_bounds(game.code_panel.speed_up)),"Speed highlight follows actual control")
	await shot("speed")
	click(guide.target_rect.get_center())
	await frame(); await frame()
	expect(guide.step_id == "item" and game.speed != 1,"speed changed through real input")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "item_type","item detail points at a useful code type")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "item_use","code selection leads to use")
	expect(not guide.card.get_global_rect().intersects(game.code_panel.item_controls.supply.card.get_global_rect()),"Guide leaves item effect visible")
	await shot("item")
	click_control(guide.target)
	await frame(); await frame()
	expect(game.simulation.item_uses.has("supply"),"real item consumed")
	move_clear()
	await frame()
	for tick in range(1600):
		game._process(0.05)
		if guide.step_id == "hack": break
	expect(guide.step_id == "hack","natural combat generates enough code")
	await frame()
	await shot("hack")
	var hover := InputEventMouseMotion.new()
	hover.position = guide.target.get_global_rect().get_center()
	get_viewport().warp_mouse(hover.position)
	get_viewport().push_input(hover,true)
	await frame()
	expect(game.code_panel.program_preview.visible,"hover opens effect preview")
	expect(not guide.card.get_global_rect().intersects(game.code_panel.program_preview.get_global_rect()),"guide avoids hovered program effect")
	await shot("hack-hover")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "hack_release","program click requests confirmation")
	expect(guide.focus_regions.size() == 2 and guide.focus_regions[1].encloses(guide._control_bounds(game.code_panel.program_preview)),"Hack effect remains bright with release target")
	await shot("release")
	expect(not guide.card.get_global_rect().intersects(game.code_panel.program_preview.get_global_rect()),"guide leaves program details visible")
	click_control(guide.target)
	await frame(); await frame()
	expect(not game.simulation.program_uses.is_empty() and not guide.hold,"real hack releases tutorial hold")
	move_clear()
	await frame()
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
	await shot("commission")
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
	for step in ["prep_points","prep_slots","prep_locked"]:
		expect(guide.step_id == step,"Departure explains "+step)
		await shot(step)
		click_control(guide.skip_button)
		await frame()
	expect(guide.step_id == "prep_carry","Departure points at available carry button")
	click_control(guide.target)
	await frame()
	expect(guide.step_id == "prep_unpack" and not game.departure_items.is_empty(),"Carried item leads to refund and slot explanation")
	await shot("prep-carried")
	click_control(guide.skip_button)
	await frame()
	expect(guide.step_id == "depart","Item guide ends at departure")
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
	guide.update()
	game.code_panel._select_item("supply")
	guide.update()
	await frame()
	# A human press spans multiple frames; the card must not hide between them.
	var skip_at: Vector2 = guide.skip_button.get_global_rect().get_center()
	get_viewport().warp_mouse(skip_at)
	var press := InputEventMouseButton.new()
	press.position = skip_at
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	get_viewport().push_input(press,true)
	await frame()
	var release := press.duplicate()
	release.pressed = false
	get_viewport().push_input(release,true)
	await frame()
	expect(not guide.skipped and guide.battle_step == 4,"next click advances current step only")
	expect(guide.visible and guide.step_id != "item" and not game.paused,"later guidance remains visible after next")
	expect(game.code_panel.selected_item.is_empty(),"next closes skipped item so inspection pause cannot stall battle")
	print("TUTORIAL_CHECK checks=",checks," failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)

func move_clear() -> void:
	var event := InputEventMouseMotion.new()
	event.position = Vector2(10,10)
	get_viewport().warp_mouse(event.position)
	event.global_position = event.position
	get_viewport().push_input(event,true)
