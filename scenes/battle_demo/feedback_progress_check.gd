extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var checks := 0
var failures := 0
func verify(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/feedback-progress-%s.png" % label)
func _ready() -> void:
	get_window().size = Vector2i(1920,1080)
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/feedback-progress-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	get_window().size = Vector2i(1920,1080)
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game._start()
	var hud = game.battle_status_layer
	var panel = game.code_panel
	panel._process(0)
	hud.pointer = Vector2(-9999,-9999)
	hud._process(0)
	var sim = game.simulation
	var ally: Dictionary = sim.units[0]
	var full: Dictionary = hud.vitals_parts(100,100,0,200)
	verify(is_equal_approx(full.health.size.x,72),"Full HP fills its entire dedicated lane despite historical shields")
	verify(full.shield.size.x == 0,"No shield means no shield fill")
	game._process(0.01)
	var clock: Dictionary = sim.action_timing(ally.id)
	verify(hud.action_progress(clock)>clock.progress,"Action progress advances between fixed simulation ticks")
	game.paused = true
	var frozen_progress: float = hud.action_progress(clock)
	game._process(0.03)
	verify(is_equal_approx(hud.action_progress(sim.action_timing(ally.id)),frozen_progress),"Pause freezes interpolated progress")
	game.paused = false
	# Feed real events from the original combat path until the first completed cycle.
	var seen_damage := false
	for step in range(2400):
		game._process(0.01)
		hud._process(0.01)
		if not hud.damage_numbers.is_empty(): seen_damage = true
		if not hud.cycles.is_empty(): break
	verify(seen_damage,"Real impact events reach the status-layer damage numbers")
	verify(not hud.cycles.is_empty(),"Natural effective attacks enter a visible full-node cycle")
	if not hud.cycles.is_empty():
		var cycle: Dictionary = hud.cycles.values()[0]
		verify(hud.cycle_remaining(cycle)>2.9,"Third node is visibly full before draining")
		game.paused = true
		panel._process(0)
		await capture("full-nodes")
		game.paused = false
		for i in range(15):
			game._process(0.01)
			hud._process(0.01)
		verify(hud.cycle_remaining(cycle)>0 and hud.cycle_remaining(cycle)<3,"Cycle drains right-to-left before resource release")
		game.paused = true
		await capture("draining")
		game.paused = false
		for i in range(20):
			game._process(0.01)
			hud._process(0.01)
		verify(not hud.cycles.has(cycle.cycle_id),"Completed cycle clears its visual sequence")
		verify(panel.code_fx.particles.any(func(p): return p.kind=="drop"),"Completed cycle emits a flying code")
		game.paused = true
		panel._process(0)
		await capture("released")
		game._open_pause()
		verify(game.pause_overlay.z_index > panel.code_fx.z_index and panel.program_preview.z_index > panel.code_fx.z_index,"Modal UI and details stay above live combat effects")
		await capture("menu-effects")
		game._resume_battle()
		game.paused = false
	# Real current shield/hit values, not fabricated floating numbers.
	for i in range(400):
		game._process(0.01)
		hud._process(0.01)
		if hud.damage_numbers.any(func(n): return n.age<0.04): break
	game.paused = true
	await capture("damage")
	var ages: Array = hud.damage_numbers.map(func(n): return n.age)
	hud._process(0.2)
	verify(ages == hud.damage_numbers.map(func(n): return n.age),"Paused damage numbers do not expire")
	game.paused = false
	# Rebuild through the existing encounter path; the Simulation object is reused.
	hud.shield_peaks[ally.id] = 999
	hud.visual_values[ally.id] = {"vitals":Vector2(1,999),"count":2.0}
	game._build_units()
	game._start()
	panel._process(0)
	hud._process(0)
	var rebuilt: Dictionary = sim.units[0]
	verify(hud.visual_values[rebuilt.id].vitals.x == rebuilt.max_hp,"Next battle starts visually full without previous damage interpolation")
	verify(float(hud.shield_peaks.get(rebuilt.id,0)) < 999,"Next battle resets shield display history")
	verify(hud.damage_numbers.is_empty() and hud.cycles.is_empty(),"Next battle clears numbers and cycle animation")
	game.paused = true
	await capture("next-battle")
	print("FEEDBACK_PROGRESS_CHECK checks=%d failures=%d" % [checks,failures])
	game.free()
	get_tree().quit(1 if failures else 0)
