extends Node
const Scene = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func expect(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func _ready() -> void:
	var game = Scene.instantiate()
	game.progress.path = "res://.godot/chain-integration-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library", "prologue")
	game._guard()
	var candidates: Array[int] = [0,1,2,3,4,5,6]
	game.run.roster = candidates
	game.formation = [0,3,-1,4,2,-1]
	game.run.formation = game.formation.duplicate()
	game.run.code_programs = ["redirect", "repair"]
	game._build_units()
	game._start()
	expect(game.phase == "battle", "original player controller starts battle")
	var sim = game.simulation
	var panel = game.code_panel
	panel._process(0)
	await get_tree().process_frame
	sim.blocks.purple = 2; sim.blocks.green = 1
	panel._show_program_preview("redirect", true)
	expect(panel.preview_program_id == "redirect" and sim.casts == 0, "preview does not spend")
	panel._cast_code("redirect")
	expect(sim.casts == 1 and sim.blocks.purple == 0, "release executes canonical recoil")
	expect(sim.units.filter(func(u): return u.side == 0).all(func(u): return u.shield_layers.any(func(layer): return layer.source == "recoil")), "real party receives special shields")
	var ally: Dictionary = sim._living(0)[0]
	ally.hp -= 80
	sim.ready_at = 0
	sim.blocks.red = 3
	panel._show_program_preview("repair", true)
	panel._update_hud()
	expect(panel.preview_target.visible and panel.preview_payment.visible, "preview exposes target and payment")
	panel._cast_code("repair")
	expect(sim.program_uses.get("repair",0) == 1, "UI pays universal repair")
	game.paused = false
	panel._hide_program_preview()
	for i in range(190): game._tick()
	expect(sim.elapsed > 8.0, "original battle clock advances")
	if "--capture" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(1920,1080)
		get_window().mode = Window.MODE_WINDOWED
		game.queue_redraw()
		panel._process(0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/chain-main-battle.png")
	# Mainline checkpoint preserves pre-battle stock for retry.
	expect(game.run.code_supplies.supply == 1, "inflight combat does not corrupt stock checkpoint")
	print("CHAIN_MAIN checks=%d failures=%d" % [checks, failures])
	game.queue_free()
	get_tree().quit(0 if failures == 0 else 1)
