extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func move(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	get_viewport().push_input(event,true)
func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/code-hud-check.json"
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.run.node.encounter_id = "encounter_classroom"
	game.formation = [0,1,2,3,-1,-1]
	var roster: Array[int] = [0,1,2,3]
	game.run.roster = roster
	game.run.code_programs = ["disconnect","takeover"]
	game._build_units()
	game._start()
	for tick in range(40): game._tick()
	var panel = game.code_panel
	panel._process(0)
	await get_tree().process_frame
	await get_tree().process_frame
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 0
	panel._update_hud()
	verify(panel.program_controls.takeover.button.disabled,"unaffordable program disabled")
	verify(not panel.program_controls.takeover.recipe.purple.enough and panel.program_controls.takeover.recipe.purple.amount == 2,"recipe icon shows unaffordable permission cost")
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 6
	panel._update_hud()
	verify(panel.program_controls.takeover.button.available and not panel.program_controls.takeover.button.disabled,"affordable legal program highlights")
	verify(panel.program_controls.takeover.recipe.purple.enough and panel.program_controls.takeover.recipe.blue.enough,"recipe icons brighten as costs become affordable")
	verify(panel.item_controls.converter.source_preview.kind == "red" and panel.item_controls.converter.destination_preview.kind == "blue","item input and output previews use resource icons")
	for controls in [panel.program_controls.takeover,panel.item_controls.supply,panel.item_controls.converter]:
		move(controls.button.get_global_rect().get_center())
		verify(panel.hover_paused(),"action hover pauses")
		var before: float = game.simulation.elapsed
		var journey_time: float = game.expedition_seconds
		var animation_time: float = game.visual_time
		game._process(0.2)
		verify(game.expedition_seconds == journey_time and game.visual_time == animation_time,"hover freezes journey and presentation clocks")
		verify(game.simulation.elapsed == before,"hover prevents simulation ticks")
		move(controls.card.get_global_rect().end-Vector2(3,3))
		verify(panel.hover_paused(),"cost and picker remain in hover pause region")
		move(Vector2(640,600))
		verify(not panel.hover_paused(),"leaving action restores hover pause")
		game._process(0.2)
		verify(game.simulation.elapsed > before,"leaving resumes combat")
	game.paused = true
	move(panel.item_controls.supply.button.get_global_rect().get_center())
	move(Vector2(640,600))
	game._process(0.2)
	verify(game.paused,"leaving never clears manual pause")
	game.paused = false
	move(panel.program_controls.takeover.button.get_global_rect().get_center())
	game._open_pause()
	move(Vector2(640,600))
	verify(game.paused and game.pause_overlay.visible,"pause menu survives hover exit")
	game._resume_battle()
	move(panel.item_controls.supply.destination.get_global_rect().get_center())
	verify(panel.hover_paused(),"inline type selection pauses")
	game.simulation.blocks.red = 0
	panel.item_controls.supply.destination.select(0)
	panel._update_hud()
	verify(panel.item_controls.supply.destination_preview.kind == "red" and panel.item_controls.supply.destination_preview.amount == 3,"supply output icon follows selected resource")
	panel._use_code_item("supply")
	verify(game.simulation.blocks.red == 3 and panel.item_controls.supply.button.remaining == 0,"item updates bank and count badge")
	verify(panel.hover_paused(),"using item preserves hover pause")
	var fx = panel.code_fx
	fx.set_process(false)
	var drops: Array = fx.particles.filter(func(p): return p.kind == "drop" and p.ui)
	verify(drops.size() == 3,"supply emits three UI code particles")
	if not drops.is_empty():
		var age: float = drops[0].age
		fx._process(0.05)
		verify(drops[0].age > age,"UI collection continues during hover pause")
	game.screen = "campaign"
	verify(not panel.hover_paused(),"leaving battle clears hover suspension immediately")
	game.screen = "battle"
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 6
	game.simulation.blocks.purple = 1
	panel._update_hud()
	fx.particles.clear()
	move(panel.program_controls.takeover.button.get_global_rect().get_center())
	verify(panel.hover_paused(),"disabled icon still pauses for inspection")
	if "--capture" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
			get_window().size = resolution
			await get_tree().process_frame
			await get_tree().process_frame
			panel._process(0)
			move(panel.program_controls.takeover.button.get_global_rect().get_center())
			panel._update_hud()
			await RenderingServer.frame_post_draw
			verify(panel.get_viewport_rect().encloses(panel.programs.get_global_rect()),"skills fit viewport")
			verify(panel.get_viewport_rect().encloses(panel.items.get_global_rect()),"items fit viewport")
			get_viewport().get_texture().get_image().save_png("res://.godot/code-hud-%dx%d.png" % [resolution.x,resolution.y])
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 6
	panel._update_hud()
	move(panel.program_controls.takeover.button.get_global_rect().get_center())
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = panel.program_controls.takeover.button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
	verify(game.simulation.system_taken and panel.hover_paused(),"real skill click executes and keeps hover pause")
	var bursts: Array = fx.particles.filter(func(p): return p.kind == "program")
	verify(bursts.size() == 1,"skill creates a burst")
	if not bursts.is_empty():
		var age: float = bursts[0].age
		fx._process(0.05)
		verify(bursts[0].age == age,"hover freezes battle effects")
		move(Vector2(640,600))
		fx._process(0.05)
		verify(bursts[0].age > age,"leaving resumes battle effects")
	print("CODE_HUD_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
