extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func verify(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func click(button: Button) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		get_viewport().push_input(event,true)
func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dim := get_window().size
	get_viewport().get_texture().get_image().save_png("res://.godot/code-layout-%s-%dx%d.png" % [label,dim.x,dim.y])
func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/code-layout-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game.run.code_programs = ["redirect","repair"]
	var panel = game.code_panel
	panel._process(0)
	game._start()
	panel._process(0)
	await get_tree().process_frame
	var sim = game.simulation
	var controls: Dictionary = panel.program_controls.redirect
	for dim in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = dim
		await get_tree().process_frame
		game._process(0)
		panel._process(0)
		for color in sim.blocks: sim.blocks[color] = 0
		panel._update_hud()
		verify(controls.state.text == "缺码" and not controls.button.disabled,"Missing code remains inspectable and explicitly labelled")
		verify(panel.programs.position.y >= 620,"Programs occupy bottom action area")
		verify(panel.programs.get_global_rect().size.y <= 90*panel.canvas.scale.y,"Program row fits footer height budget")
		verify(get_viewport().get_visible_rect().encloses(panel.programs.get_global_rect()),"Program cards fit viewport")
		for stock in panel.bank_labels.values():
			verify(stock.get_global_rect().size.y <= 32*panel.canvas.scale.y+1,"Stock is a subordinate single line")
			verify(not stock.get_global_rect().intersects(panel.programs.get_global_rect()),"Stock cannot cover action cards")
		await capture("missing")
		for color in sim.blocks: sim.blocks[color] = 6
		panel._update_hud()
		verify(controls.state.text == "可释放" and controls.button.available,"Available program visibly invites release")
		controls.button._process(0.3)
		panel._update_hud()
		verify(controls.button.ready_age >= 0.22,"Ready emphasis does not loop")
		await capture("ready")
		controls.button.grab_focus()
		key(KEY_ENTER)
		await get_tree().process_frame
		panel._process(0)
		verify(panel.preview_pinned and panel.preview_release.has_focus(),"Keyboard enters explicit confirmation with release focus")
		verify(controls.state.text == "确认释放","Selected legal program shows confirmation state")
		verify(panel.program_preview.get_global_rect().end.y <= panel.programs.get_global_rect().position.y+2*panel.canvas.scale.y,"Confirmation expands upward")
		verify(get_viewport().get_visible_rect().encloses(panel.program_preview.get_global_rect()),"Confirmation fits viewport")
		verify(sim.casts == 0,"Inspecting and selecting do not spend codes")
		await capture("confirm")
		key(KEY_ESCAPE)
		panel._process(0)
		verify(not panel.preview_pinned and sim.casts == 0,"Escape dismisses without spending")
	panel._show_program_preview("redirect",true)
	var purple_before: int = sim.blocks.purple
	var green_before: int = sim.blocks.green
	click(panel.preview_release)
	verify(sim.casts == 1 and sim.blocks.purple == purple_before-2 and sim.blocks.green == green_before-1,"Confirm spends precisely the displayed fixed recipe")
	verify(not panel.preview_pinned,"Successful cast closes confirmation")
	panel._update_hud()
	verify(controls.state.text == "冷却中","Cast cooldown has explicit feedback")
	var ally: Dictionary = sim.units.filter(func(u): return u.side == 0)[0]
	sim._queue_code_cycle(ally,"purple","护盾吸收")
	panel._update_absorption_cycle()
	verify(is_equal_approx(panel.bank_labels.purple.cycle_ratio,1.0),"Shield completion shows a full shared collection line")
	sim.elapsed += sim.CODE_CYCLE_DURATION/2
	panel._update_absorption_cycle()
	verify(is_equal_approx(panel.bank_labels.purple.cycle_ratio,0.5),"Shared collection contracts using simulation elapsed time")
	var ratio: float = panel.bank_labels.purple.cycle_ratio
	panel._process(0.2)
	verify(panel.bank_labels.purple.cycle_ratio == ratio,"Real-time HUD updates cannot advance paused shared collection")
	sim.elapsed += sim.CODE_CYCLE_DURATION/2
	sim._release_code_cycles()
	panel._update_absorption_cycle()
	verify(panel.bank_labels.purple.cycle_ratio == -1,"Completed collection relinquishes the temporary full counter")
	print("Code layout checks: %d / failures: %d" % [checks,failures])
	game.free()
	get_tree().quit(1 if failures else 0)
