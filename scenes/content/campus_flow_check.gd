extends RefCounted
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
const Rules = preload("res://game/run/campus_flow_rules.gd")
const Journey = preload("res://game/run/campaign_journey.gd")
var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPUS_FLOW: "+label)
func fixture() -> CampusRegionFlow:
	var source = Catalog.definition("library")
	var result := CampusRegionFlow.new()
	result.id = source.id
	result.display_name = source.display_name
	result.revision = 2
	for original in source.stages:
		var stage := CampusRouteStage.new()
		for choice in original.choices: stage.choices.append(choice.duplicate())
		result.stages.append(stage)
	var extra := CampusRouteStage.new()
	var stop: CampusRouteStop = result.stages[1].choices[0].duplicate()
	stop.id = "lake_detour"
	stop.power = 0.86
	extra.choices.append(stop)
	result.stages.insert(3,extra)
	return result
func settle(ui: Node) -> void:
	for i in range(5): await ui.get_tree().process_frame
func has_text(node: Node, value: String) -> bool:
	if node is Label and value in node.text: return true
	for child in node.get_children():
		if has_text(child,value): return true
	return false
func capture(ui: Control, label: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var size := ui.get_window().size
	expect(ui.get_viewport().get_texture().get_image().save_png("res://.godot/campus-flow-%s-%dx%d.png" % [label,size.x,size.y]) == OK,"capture "+label)
func run(ui: Control) -> void:
	for region in Rules.REGIONS:
		var resource = Catalog.definition(region)
		expect(resource.validate().is_empty(),"valid authoring resource "+region)
		var journey := Journey.new()
		expect(journey.begin(region,2),"actual journey loads "+region)
		expect(journey.data.map == resource.snapshot().layers,"same authored stages reach game")
		while not journey.data.finished:
			expect(journey.enter(0,[]),"enter original region")
			var saved := journey.snapshot()
			var restored := Journey.new()
			expect(restored.restore(JSON.parse_string(JSON.stringify(saved))),"JSON checkpoint round trip")
			expect(JSON.stringify(restored.snapshot()) == JSON.stringify(saved),"visit and definition preserved")
			journey.visit.data.guard_won = true
			journey.visit.data.reward_taken = true
			expect(journey.leave(),"advance original flow")
	var flow := fixture()
	expect(flow.validate().is_empty(),"five-stop fixture validates")
	var journey := Journey.new()
	expect(journey.begin("library",2,flow),"original journey accepts five authored stages")
	expect(journey.data.map.size() == 5,"length is configurable")
	var saved: Variant = JSON.parse_string(JSON.stringify(journey.snapshot()))
	flow.stages.remove_at(3)
	var restored := Journey.new()
	expect(restored.restore(saved) and restored.data.map.size() == 5,"valid new-format active run stays coherent")
	var bad: Dictionary = saved.duplicate(true)
	bad.schema = 1
	expect(not restored.restore(bad),"old development checkpoint requires restart")
	bad = saved.duplicate(true)
	bad.flow.stops.gate.power = "strong"
	expect(not restored.restore(bad),"reject invalid power in persisted definition")
	bad = saved.duplicate(true)
	bad.map[0] = ["missing"]
	expect(not restored.restore(bad),"reject map/definition mismatch")
	bad = saved.duplicate(true)
	bad.flow.layers[1].append("gate")
	expect(not restored.restore(bad),"reject duplicate node reference")
	for kind in ["empty", "null_stage", "null_stop", "duplicate", "missing_place", "missing_enemy", "bad_landmark", "bad_enemy", "bad_template", "bad_power", "bad_position", "unregistered_copy"]:
		var broken := fixture()
		match kind:
			"empty": broken.stages[0].choices.clear()
			"null_stage": broken.stages[0] = null
			"null_stop": broken.stages[0].choices[0] = null
			"duplicate": broken.stages[1].choices[0].id = "gate"
			"missing_place": broken.stages[0].choices[0].place = null
			"missing_enemy": broken.stages[0].choices[0].encounter = null
			"bad_landmark":
				broken.stages[0].choices[0].place = broken.stages[0].choices[0].place.duplicate()
				broken.stages[0].choices[0].place.landmark = "missing"
			"bad_enemy": broken.stages[0].choices[0].encounter = CampusEncounter.new()
			"bad_template": broken.stages[0].choices[0].hotspot_template = "missing"
			"bad_power": broken.stages[0].choices[0].power = NAN
			"bad_position":
				broken.stages[0].choices[0].place = broken.stages[0].choices[0].place.duplicate()
				broken.stages[0].choices[0].place.offset = Vector2(1700,1400)
			"unregistered_copy": broken.stages[0].choices[0].encounter = broken.stages[0].choices[0].encounter.duplicate()
		expect(not broken.validate().is_empty(),"authoring error: "+kind)
	var inspector = preload("res://addons/campus-flow/summary.gd").new()
	inspector.flow = fixture()
	ui.add_child(inspector)
	await settle(ui)
	expect(not inspector.preview_button.disabled and "第 5 站" in inspector.overview_label.text,"Inspector overview and preview enabled")
	inspector.flow.stages[0].choices.clear()
	inspector.find_child("ValidateFlow",true,false).pressed.emit()
	expect(inspector.preview_button.disabled and not inspector.status.text.is_empty(),"Inspector validation prevents invalid preview")
	inspector.queue_free()
	await settle(ui)
	# Existing schema-2 visit, hotspot flags, rewards and combat are reused.
	var game = preload("res://scenes/expedition/expedition.tscn").instantiate()
	game.progress.path = "res://.godot/campus-flow-test-profile-%d.json" % Time.get_ticks_usec()
	ui.add_child(game)
	await settle(ui)
	game.set_process(false)
	game.progress.campaign.routes_acquired = true
	game.progress.commission_unlocks.append("departure")
	var before_invalid: Dictionary = game.progress.to_dict().duplicate(true)
	game._begin_region("missing")
	expect(game.progress.to_dict() == before_invalid and game.campaign_mode.is_empty(),"invalid region cannot replace current state or checkpoint")
	expect(has_text(game.campaign_panel,"区域配置无效"),"main controller explains invalid configuration")
	game._begin_region("library")
	# Authored encounter traversal is independent of mid-route recruitment.
	game.run.expedition_party = false
	flow = fixture()
	expect(game.journey.begin("library",2,flow),"main controller uses configured journey")
	game._show_journey()
	await settle(ui)
	expect(has_text(game.campaign_panel,"1 / 5"),"main UI uses authored stage count")
	await capture(ui,"main-five-stops")
	for i in range(5):
		expect(game.journey.enter(0,[]),"main traversal enters stage "+str(i+1))
		game._guard()
		expect(game.run.node.encounter_id == game.journey.stop().encounter_id,"guard uses authored encounter")
		expect(is_equal_approx(game.run.node.power,game.journey.stop().power),"guard uses authored power")
		game.journey.visit.data.guard_won = true
		game.journey.visit.data.reward_taken = true
		expect(game.journey.leave(),"main traversal advances stage "+str(i+1))
	expect(game.journey.data.finished,"five-stop flow reaches original completion")
	game.queue_free()
	await settle(ui)
	ui.get_window().mode = Window.MODE_WINDOWED
	var resolutions := [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1920,1200)] if "--capture" in OS.get_cmdline_user_args() else [Vector2i(1920,1080)]
	for size in resolutions:
		ui.get_window().size = size
		await settle(ui)
		for region in Rules.REGIONS:
			ui.load_region(region)
			await settle(ui)
			expect(ui.flow.region == region and ui.flow.layers.size() == 4,"preview loads same saved resource")
			var id: String = ui.flow.layers[0][0]
			var point = ui.board.project(preload("res://game/run/campus_presentation.gd").point(region,id,ui.board.layout,ui.flow))
			expect(ui.board.place_at(point) == id,"preview point projection/hit")
			ui.inspect_stop(id)
			expect(ui.flow.stops[id].encounter_id in ui.detail.text,"preview shows existing content reference")
			expect(Rect2(Vector2.ZERO,ui.size).encloses(ui.board.get_rect()),"preview map stays in window")
			await capture(ui,region)
	var long_flow := fixture()
	while long_flow.stages.size() < 12:
		var stage := CampusRouteStage.new()
		var stop: CampusRouteStop = long_flow.stages[0].choices[0].duplicate()
		stop.id = "repeat_gate_"+str(long_flow.stages.size())
		stage.choices.append(stop)
		long_flow.stages.append(stage)
	expect(long_flow.validate().is_empty(),"12 stages can revisit shared place")
	ui.get_window().size = Vector2i(1280,720)
	ui.set_flow(long_flow.snapshot(),"十二站边界夹具")
	await settle(ui)
	expect(ui.stages_scroll.get_v_scroll_bar().max_value > ui.stages_scroll.size.y,"long flow list scrolls in small desktop window")
	var last: String = long_flow.stages.back().choices[0].id
	var buttons: Array = ui.overview.get_children().filter(func(child): return child is Button and child.get_meta("stop_id","") == last)
	expect(buttons.size() == 1,"repeated physical place keeps distinct selectable stop")
	if buttons.size() == 1: buttons[0].pressed.emit()
	expect(ui.board.selected_place == last and last in ui.detail.text,"list selects overlapping map stop")
	ui.load_region("library")
	print("CAMPUS_FLOW checks=%d failures=%d" % [checks,failures])
	ui.get_tree().quit(0 if failures == 0 else 1)
