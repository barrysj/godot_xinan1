extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/hack-feedback-check.json"
	add_child(game)
	await get_tree().process_frame
	game.progress.path = "res://.godot/hack-feedback-check.json"
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.run.node.encounter_id = "encounter_classroom"
	game.formation = [0,1,2,3,-1,-1]
	var roster: Array[int] = [0,1,2,3]
	game.run.roster = roster
	game.screen = "battle"
	for id in ["disconnect","redirect","repair","takeover"]:
		game.run.code_programs = [id,"repair" if id != "repair" else "disconnect"]
		game._build_units()
		game._start()
		for tick in range(40): game._tick()
		for actor in game.units:
			if actor.side == 0: actor.hp = actor.max_hp*0.45
		for kind in game.simulation.blocks: game.simulation.blocks[kind] = 6
		var panel = game.code_panel
		panel._process(0)
		# Flat HUD is already visible.
		await get_tree().process_frame
		var fx = panel.code_fx
		fx.particles.clear()
		fx.set_process(false)
		var button: Button = panel.program_controls[id].button
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			event.position = button.get_global_rect().get_center()
			event.global_position = event.position
			get_viewport().push_input(event,true)
			await get_tree().process_frame
		verify(game.simulation.casts == 0 and panel.preview_program_id == id,"HUD click previews without casting "+id)
		# Interaction clicks are covered by code_hud_check; this check isolates each effect burst.
		panel.preview_release.pressed.emit()
		verify(game.simulation.casts == 1,"release button executes "+id)
		verify(not game.paused and panel.programs.visible,"flat HUD stays available after casting")
		var programs: Array = fx.particles.filter(func(p): return p.kind == "program")
		verify(programs.size() == 1,"one program event creates one burst")
		if programs.is_empty(): continue
		var burst: Dictionary = programs[0]
		verify(burst.targets.size() == 2 if id == "repair" else burst.targets.is_empty(),"only actual immediate effects attach to actors")
		var old_age: float = burst.age
		game.paused = true
		fx._process(0.05)
		verify(is_equal_approx(burst.age,old_age),"paused game freezes burst")
		game.paused = false
		var before_hp: Array = game.units.map(func(u): return u.hp)
		var before_blocks: Dictionary = game.simulation.blocks.duplicate()
		fx.advance(0.8,false)
		verify(burst.age > old_age,"resumed game advances burst")
		verify(game.units.map(func(u): return u.hp) == before_hp and game.simulation.blocks == before_blocks,"visual advance does not mutate combat health or currency")
		if "--capture" in OS.get_cmdline_user_args():
			await capture(game,fx,id,Vector2i(1920,1080))
			if id == "takeover":
				await capture(game,fx,id,Vector2i(2560,1440))
				await capture(game,fx,id,Vector2i(1920,1200))
				fx.reduced_motion = true
				await capture(game,fx,"reduced",Vector2i(1920,1080))
				fx.reduced_motion = false
				if "--frames" in OS.get_cmdline_user_args():
					get_window().size = Vector2i(1280,720)
					await get_tree().process_frame
					for frame in range(44):
						burst.age = frame*0.05
						fx.queue_redraw()
						game.queue_redraw()
						await RenderingServer.frame_post_draw
						get_viewport().get_texture().get_image().save_png("res://.godot/hack-frame-%03d.png" % frame)
		fx.advance(3.0,false)
		verify(fx.particles.is_empty(),"burst releases all particles after completion")
	print("HACK_FEEDBACK_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture(game: Control, fx: Control, id: String, resolution: Vector2i) -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = resolution
	await get_tree().process_frame
	await get_tree().process_frame
	game.queue_redraw()
	fx.queue_redraw()
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	verify(shot.get_size() == resolution,"actual effect capture resolution")
	shot.save_png("res://.godot/hack-%s-%dx%d.png" % [id,resolution.x,resolution.y])
