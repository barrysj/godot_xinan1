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
	get_viewport().get_texture().get_image().save_png("res://.godot/status-hud-%s-%dx%d.png" % [label,get_window().size.x,get_window().size.y])
func _ready() -> void:
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/status-hud-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await get_tree().process_frame
	game.storage_ready = false
	game.tutorial_guide.skipped = true
	game.tutorial_guide.hide()
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game._start()
	var hud = game.battle_status_layer
	var ui = game.inspector
	var panel = game.code_panel
	panel._process(0)
	var sim = game.simulation
	for color in sim.blocks: sim.blocks[color] = 1
	sim.absorbed = 48
	var red: Dictionary = sim.units.filter(func(u): return u.side == 0 and u.code_type == "red")[0]
	sim.attack_counts[red.id] = 2
	panel._update_hud()
	for viewport in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = viewport
		await get_tree().process_frame
		game._process(0)
		panel._process(0)
		hud._process(0); ui._process(0)
		await get_tree().process_frame
		var stock_rects: Array[Rect2] = []
		for sockets in panel.bank_labels.values():
			var rect: Rect2 = sockets.get_global_rect()
			verify(rect.size.x >= 94*game.scale_factor-1,"Stock is legible at native HUD scale")
			for other in stock_rects: verify(not rect.intersects(other),"Stock cards do not overlap")
			stock_rects.append(rect)
		verify(panel.bank_labels.red.get_global_rect().end.x < panel.programs.get_global_rect().position.x,"Auxiliary stock stays left of primary program controls")
		verify(panel.bank_labels.purple.absorbed == 48,"Purple displays shared absorbed remainder")
		verify(sim.attack_counts[red.id] == 2,"HUD never consumes generation counters")
		verify(not hud.intents.is_empty(),"Every living enemy has an intent hit target")
		for rect in hud.intents.values():
			verify(rect.size.x >= 32*game.scale_factor,"Smaller intent art retains a generous mouse hit target")
		await capture("battle")
		var id: int = hud.intents.keys()[0]
		ui.pointer = ui.canvas.get_global_transform().affine_inverse() * hud.intents[id].get_center()
		hud._process(0); ui._process(0)
		verify(ui.panel.visible and panel.hover_paused(),"Intent hover opens detail and pauses through shared input boundary")
		verify(ui.heading.text.contains(sim.unit(id).name),"Names remain available through intent details")
		verify(get_viewport().get_visible_rect().encloses(ui.panel.get_global_rect()),"Intent detail fits viewport")
		var elapsed: float = sim.elapsed
		game._process(0.2)
		verify(sim.elapsed == elapsed,"Hover freezes real simulation")
		await capture("intent")
		ui.pointer = ui.canvas.get_global_transform().affine_inverse() * Vector2(-1000,-1000)
		hud._process(0); ui._process(0)
		verify(not ui.panel.visible and not hud.hover_paused(),"Leaving intent closes detail and relinquishes pause")
	ui.pointer = ui.canvas.get_global_transform().affine_inverse() * hud.hit_rects[red.id].get_center()
	hud._process(0); ui._process(0)
	verify(ui.panel.visible and ui.generation.text.contains("普攻产码 2/3"),"Exact personal progress remains available on compact HUD hover")
	verify(not ui.summary.text.is_empty() and not ui.shield_value.text.is_empty(),"Hidden exact vitals remain available in details")
	verify(panel.hover_paused(),"Allied status details retain operation pause")
	await capture("ally-detail")
	var purple: Dictionary = sim.units.filter(func(u): return u.side == 0 and u.code_type == "purple")[0]
	ui.pointer = ui.canvas.get_global_transform().affine_inverse() * hud.hit_rects[purple.id].get_center()
	hud._process(0); ui._process(0)
	verify(ui.generation.text.contains("全队吸收 48/80") and not ui.generation.text.contains("普攻产码"),"Purple compact detail preserves team absorption semantics")
	ui.pointer = ui.canvas.get_global_transform().affine_inverse() * Vector2(-1000,-1000)
	hud._process(0); ui._process(0)
	# Let the original campaign run naturally into a real enemy cast.
	for step in range(230):
		game._process(0.05)
		if not sim.warnings.is_empty(): break
	panel._process(0)
	hud._process(0); ui._process(0)
	verify(not sim.warnings.is_empty(),"Natural enemy timer starts a real cast")
	if not sim.warnings.is_empty():
		var caster: int = sim.warnings.keys()[0]
		verify(sim.action_timing(caster).kind == "cast","Action strip reads real cast phase")
		ui.pointer = ui.canvas.get_global_transform().affine_inverse() * hud.intents[caster].get_center()
		hud._process(0); ui._process(0)
		verify(ui.action_name.text.contains(sim.intent_for(caster).label),"Cast hover uses the actual skill description")
		verify(ui.action_target.text.contains("目标：其他存活敌人"),"Shield broadcast describes recipients, not its attack target")
		await capture("cast")
		for pressed in [true,false]:
			var click := InputEventMouseButton.new()
			click.position = ui.canvas.get_global_transform()*ui.pointer
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			get_viewport().push_input(click,true)
		verify(ui.pinned and ui.observed.id == caster,"Real mouse click pins enemy intent")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		get_viewport().push_input(escape,true)
		hud._process(0); ui._process(0)
		verify(not ui.pinned and not game.paused,"Escape closes only intent, retaining manual pause ownership")
	var before: int = sim.blocks.red
	panel.bank_labels.red.pulse = 0
	panel.consume({"kind":"code_generated","code_type":"red","actual":0,"actor_id":red.id,"target_id":red.id,"from":red.position,"to":red.position,"reason":"普攻"})
	verify(panel.bank_labels.red.pulse == 0,"Overflow does not fake a gained-code pulse")
	hud.consume({"kind":"code_generated","code_type":"red","actual":1,"actor_id":red.id,"reason":"普攻产出"})
	verify(hud.pulses.has(red.id) and sim.blocks.red == before,"Feedback is bounded and visual only")
	hud.pulses.clear()
	for reason in ["护盾吸收","道具","漏洞验证"]:
		hud.consume({"kind":"code_generated","code_type":"purple","actual":1,"actor_id":red.id,"reason":reason})
		verify(not hud.pulses.has(red.id),"Shared and item generation cannot flash personal attack progress")
	# Deliberately adjacent rows, same depth, with shields on every ally.
	ui.pointer = ui.canvas.get_global_transform().affine_inverse() * Vector2(-1000,-1000)
	var row := 1
	for ally in sim.units:
		if ally.side != 0: continue
		ally.position = Vector2(row,4)
		ally.previous_position = ally.position
		ally.shield = 24
		row += 1
	game.paused = true
	game.effects.clear()
	game.skill_effects.clear()
	panel.code_fx.particles.clear()
	game._update_battle_presentations()
	game._process(0)
	hud._process(0); ui._process(0)
	var rects: Array = hud.status_rects.values()
	for i in range(rects.size()):
		for j in range(i+1,rects.size()):
			verify(not rects[i].intersects(rects[j]),"Dense adjacent unit statuses remain separate")
	await capture("dense")
	var initial: Dictionary = hud.vitals_parts(50,100,30,30)
	var shield_hit: Dictionary = hud.vitals_parts(50,100,15,30)
	var health_hit: Dictionary = hud.vitals_parts(40,100,0,30)
	verify(initial.health == shield_hit.health,"Shield loss cannot visually change current HP")
	verify(shield_hit.shield.position.x > initial.shield.position.x and is_equal_approx(shield_hit.shield.end.x,initial.shield.end.x),"Shield shrinks toward the fixed right edge")
	verify(health_hit.health.end.x < initial.health.end.x and health_hit.health.position.x == initial.health.position.x,"HP shrinks toward the fixed left edge")
	verify(health_hit.shield.size.x == 0,"Depleted shield leaves no coloured shield fill")
	red.max_hp = 100
	red.hp = 50
	red.shield = 30
	hud._process(0); ui._process(0)
	await capture("vitals-example")
	game.paused = false
	ui.show_unit(sim.unit(hud.intents.keys()[0]),true)
	game.screen = "report"
	hud._process(0); ui._process(0)
	verify(not hud.visible and not ui.panel.visible and not ui.pinned,"Screen exit clears status and pinned intent")
	verify(not panel.hover_paused(),"Hidden status cannot retain operation pause")
	print("Status HUD checks: %d / failures: %d" % [checks,failures])
	game.free()
	get_tree().quit(1 if failures else 0)
