extends Node
const Scene = preload("res://scenes/trial/trial.tscn")
const Codes = preload("res://game/trial/code_catalog.gd")
var checks := 0
var failures := 0
var view

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func _ready() -> void:
	view = Scene.instantiate()
	view.run.path = "res://.godot/code-ui-%d.json" % Time.get_ticks_usec()
	add_child(view)
	await get_tree().process_frame
	await get_tree().process_frame
	var pickers: Array = []
	_collect(view.root_box, pickers)
	expect(pickers.size() == 2, "two prebattle program selectors")
	pickers[0].select(2)
	pickers[0].item_selected.emit(2)
	expect(view.run.programs[0] == "repair", "selector invokes persisted loadout transaction")
	expect(Array(Codes.RULES.default_loadout) == ["disconnect", "takeover"], "editing loadout never mutates shared defaults")
	view.run.set_program(0,"disconnect")
	view.run.set_program(1,"takeover")
	view._start()
	expect(view.running and view.sim.loadout == view.run.programs, "battle receives preparation loadout")
	view._toggle_pause()
	for tick in range(120): view.board.consume_events(view.sim.advance(0.05))
	view._update_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	var elapsed: float = view.sim.elapsed
	var visual: float = view.board.visual_time
	await get_tree().process_frame
	expect(view.paused and view.sim.elapsed == elapsed and view.board.visual_time == visual, "console freezes simulation and visuals")
	expect(view.get_viewport_rect().encloses(view.console.get_global_rect()), "console fits logical viewport")
	for kind in Codes.RULES.types:
		expect(view.console_labels[kind].count == view.sim.blocks[kind], "graphical bank matches simulation")
	for id in view.program_controls:
		for kind in view.program_controls[id].recipe:
			expect(view.program_controls[id].recipe[kind].capacity == Codes.program(id).cost[kind], "recipe socket count matches configured cost")
	if "--graphics-capture" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
			get_window().mode = Window.MODE_WINDOWED
			get_window().size = resolution
			await get_tree().create_timer(0.25).timeout
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			expect(view.get_viewport_rect().encloses(view.console.get_global_rect()), "graphical console fits " + str(resolution))
			expect(get_viewport().get_texture().get_image().get_size() == resolution, "actual capture resolution")
			get_viewport().get_texture().get_image().save_png("res://.godot/code-graphics-%dx%d.png" % [resolution.x,resolution.y])
	var controls: Dictionary = view.item_controls.supply
	controls.destination.select(Codes.RULES.types.keys().find("purple"))
	controls.destination.item_selected.emit(controls.destination.selected)
	expect(not controls.button.disabled, "supply enabled for chosen destination")
	await _click(controls.button)
	expect(view.sim.items.supply == 0 and view.sim.blocks.purple >= 3, "real mouse click consumes supply and generates chosen code")
	expect(view.run.supplies.supply == 1, "battle item spending does not overwrite retry checkpoint")
	controls = view.item_controls.converter
	controls.source.select(Codes.RULES.types.keys().find("purple"))
	controls.destination.select(Codes.RULES.types.keys().find("blue"))
	controls.destination.item_selected.emit(controls.destination.selected)
	await _click(controls.button)
	expect(view.sim.items.converter == 0, "real mouse conversion consumes second item")
	var expected: Dictionary = view.sim.blocks.duplicate()
	expected.purple -= 2
	expected.blue -= 2
	await _click(view.program_controls.takeover.button)
	expect(view.sim.system_taken and view.sim.blocks == expected, "real program button spends exact recipe")
	expect(view.program_controls.takeover.button.disabled, "used or cooling program visibly disabled")
	view._close_console()
	await get_tree().process_frame
	await get_tree().process_frame
	expect(not view.paused and not view.console.visible and not view.console_shade.visible, "continue dismisses modal and restores battle input")
	print("CODE_UI_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _collect(node: Node, output: Array) -> void:
	for child in node.get_children():
		if child is OptionButton: output.append(child)
		_collect(child,output)

func _click(button: Button) -> void:
	await get_tree().process_frame
	var at := button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		get_viewport().push_input(event,true)
	await get_tree().process_frame
