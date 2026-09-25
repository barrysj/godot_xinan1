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
func click(button: Button) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
func touch(at: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = at
		event.index = 0
		event.pressed = pressed
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
	verify(not panel.program_controls.takeover.button.available and not panel.program_controls.takeover.button.disabled,"unaffordable program can still be inspected")
	move(panel.program_controls.takeover.button.get_global_rect().get_center())
	panel._process(0)
	verify(panel.program_preview.visible and panel.preview_release.disabled and game.simulation.casts == 0,"hover reveals effect but cannot spend missing resources")
	verify(not panel.program_controls.takeover.recipe.purple.enough and panel.program_controls.takeover.recipe.purple.amount == 2,"recipe icon shows unaffordable permission cost")
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 6
	panel._update_hud()
	verify(panel.program_controls.takeover.button.available and not panel.program_controls.takeover.button.disabled,"affordable legal program highlights")
	panel._process(0)
	verify(not panel.preview_release.disabled,"release becomes available after collecting resources")
	verify(panel.program_controls.takeover.recipe.purple.enough and panel.program_controls.takeover.recipe.blue.enough,"recipe icons brighten as costs become affordable")
	verify(panel.item_controls.converter.source_preview.kind == "red" and panel.item_controls.converter.destination_preview.kind == "blue","item input and output previews use resource icons")
	verify(not panel.item_controls.supply.card.visible and not panel.item_controls.converter.card.visible,"item rail initially shows icons and count badges only")
	var initial_supply: int = game.simulation.items.supply
	panel._use_code_item("supply")
	verify(game.simulation.items.supply == initial_supply,"collapsed item cannot be used")
	for controls in [panel.program_controls.takeover,{"button":panel.item_controls.supply.icon,"card":panel.item_controls.supply.icon},{"button":panel.item_controls.converter.icon,"card":panel.item_controls.converter.icon}]:
		move(controls.button.get_global_rect().get_center())
		panel._process(0)
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
		panel._process(0)
		verify(not panel.hover_paused(),"leaving action restores hover pause")
		if controls.button == panel.program_controls.takeover.button: verify(not panel.program_preview.visible,"hover preview closes after leaving skill and detail")
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
	click(panel.item_controls.supply.icon)
	verify(panel.selected_item == "supply" and panel.item_controls.supply.card.visible and not panel.item_controls.converter.card.visible,"first click opens selected item effect and use controls")
	game.screen = "campaign"
	panel._process(0)
	verify(panel.selected_item.is_empty(),"leaving battle clears selected item detail")
	game.screen = "battle"
	panel._process(0)
	click(panel.item_controls.supply.icon)
	click(panel.item_controls.converter.icon)
	verify(panel.selected_item == "converter" and panel.item_controls.converter.card.visible and not panel.item_controls.supply.card.visible,"other icon switches detail")
	click(panel.item_controls.converter.icon)
	verify(panel.selected_item.is_empty() and not panel.item_controls.converter.card.visible,"second click collapses detail")
	click(panel.item_controls.supply.icon)
	move(panel.item_controls.supply.destination.get_global_rect().get_center())
	verify(panel.hover_paused(),"inline type selection pauses")
	game.simulation.blocks.red = 0
	panel.item_controls.supply.destination.select(0)
	panel._update_hud()
	verify(panel.item_controls.supply.destination_preview.kind == "red" and panel.item_controls.supply.destination_preview.amount == 3,"supply output icon follows selected resource")
	panel._use_code_item("supply")
	verify(game.simulation.blocks.red == 3 and panel.item_controls.supply.icon.remaining == 0,"item updates bank and count badge")
	verify(panel.selected_item.is_empty() and not panel.item_controls.supply.card.visible,"using item closes detail")
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
	game.simulation.blocks.blue = 1
	panel._update_hud()
	fx.particles.clear()
	move(panel.program_controls.takeover.button.get_global_rect().get_center())
	panel._process(0)
	verify(panel.hover_paused() and panel.program_preview.visible and panel.preview_release.disabled,"unaffordable icon still opens an inspectable preview")
	if "--capture" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
			get_window().size = resolution
			await get_tree().process_frame
			await get_tree().process_frame
			panel._process(0)
			move(panel.program_controls.takeover.button.get_global_rect().get_center())
			panel._process(0)
			panel._update_hud()
			await RenderingServer.frame_post_draw
			verify(panel.get_viewport_rect().encloses(panel.programs.get_global_rect()),"skills fit viewport")
			verify(panel.get_viewport_rect().encloses(panel.items.get_global_rect()),"items fit viewport")
			verify(panel.program_preview.visible and panel.get_viewport_rect().encloses(panel.program_preview.get_global_rect()),"skill effect preview fits viewport")
			get_viewport().get_texture().get_image().save_png("res://.godot/code-program-preview-%dx%d.png" % [resolution.x,resolution.y])
			click(panel.item_controls.converter.icon)
			move(panel.item_controls.converter.card.get_global_rect().position+Vector2(20,16))
			await RenderingServer.frame_post_draw
			verify(panel.item_controls.converter.card.visible and panel.get_viewport_rect().encloses(panel.item_controls.converter.card.get_global_rect()),"item detail fits viewport")
			get_viewport().get_texture().get_image().save_png("res://.godot/code-hud-detail-%dx%d.png" % [resolution.x,resolution.y])
			click(panel.item_controls.converter.icon)
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 6
	panel._update_hud()
	if "--capture" in OS.get_cmdline_user_args():
		move(panel.program_controls.takeover.button.get_global_rect().get_center())
		panel._process(0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/code-program-ready-1920x1200.png")
	touch(panel.program_controls.disconnect.button.get_global_rect().get_center())
	verify(panel.preview_pinned and panel.preview_program_id == "disconnect" and game.simulation.casts == 0,"touch selects skill without releasing")
	move(Vector2(640,600))
	panel._process(0)
	verify(panel.program_preview.visible and panel.hover_paused(),"touch selected preview stays open and pauses combat")
	touch(Vector2(640,600))
	verify(not panel.program_preview.visible and game.simulation.casts == 0,"touch outside dismisses preview without spending")
	move(panel.program_controls.takeover.button.get_global_rect().get_center())
	click(panel.program_controls.takeover.button)
	verify(panel.preview_pinned and panel.preview_program_id == "takeover" and game.simulation.casts == 0,"mouse click selects skill without releasing")
	click(panel.preview_release)
	verify(game.simulation.system_taken and game.simulation.casts == 1 and not panel.program_preview.visible,"only release button executes skill and closes preview")
	var bursts: Array = fx.particles.filter(func(p): return p.kind == "program")
	verify(bursts.size() == 1,"skill creates a burst")
	if not bursts.is_empty():
		var age: float = bursts[0].age
		move(panel.program_controls.takeover.button.get_global_rect().get_center())
		panel._process(0)
		fx._process(0.05)
		verify(bursts[0].age == age,"hover freezes battle effects")
		move(Vector2(640,600))
		fx._process(0.05)
		verify(bursts[0].age > age,"leaving resumes battle effects")
	print("CODE_HUD_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
