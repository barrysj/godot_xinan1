extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
var failures := 0
var checks := 0
func verify(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func shot(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var capture := get_viewport().get_texture().get_image()
	capture.save_png("res://.godot/activity-"+name+".png")
	var top := int(capture.get_height()*620.0/720.0)
	capture.get_region(Rect2i(0,top,capture.get_width(),capture.get_height()-top)).save_png("res://.godot/activity-"+name+"-dock.png")
func _ready() -> void:
	get_window().size = Vector2i(1920,1080)
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/activity-preview.json"
	add_child(game)
	await get_tree().process_frame
	game.tutorial_guide.skipped = true
	game.tutorial_guide.hide()
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game.run.code_programs = ["disconnect","redirect","repair"]
	game.code_panel._process(0)
	game._start()
	var panel = game.code_panel
	panel._process(0)
	await get_tree().process_frame
	var feed = panel.activity
	verify(panel.program_controls.size() == 3 and panel.programs.get_child_count() == 4,"Three real programs and fourth empty slot")
	verify(panel.bond_panel.size.x < 160,"Compact synergy list")
	verify(not panel.buff_button.visible,"Zero persistent buffs do not occupy an entry")
	verify(not feed.expanded and not feed.history.visible,"Journal collapsed by default")
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 6
	panel._update_hud()
	verify(panel.program_controls.redirect.button.state_code == "ready","Release-ready state")
	verify(panel.program_controls.repair.button.state_code == "target","No wounded target state")
	game.queue_redraw()
	await shot("ready-target")
	panel._show_program_preview("redirect",true)
	verify(panel.preview_recipients().size() == 4,"Team shield preview marks all real recipients")
	panel._hide_program_preview()
	verify(game.simulation.cast_program("redirect"),"Cast real explosive shield")
	panel._consume_pending()
	panel._update_hud()
	verify(panel.program_controls.redirect.button.state_code == "cooldown" and panel.program_controls.redirect.button.cooldown_left > 0,"Real cooldown countdown")
	verify(not feed.announcements.is_empty(),"Hack queues central announcement")
	feed.announcements[0].age = 0.2
	game.queue_redraw()
	game._update_battle_presentations()
	await shot("hack-shield")
	feed.set_expanded(true)
	verify(panel.hover_paused(),"Expanded log owns reading pause")
	verify(feed.history.text.contains("反冲护盾"),"Hack retained in journal")
	await shot("journal")
	feed.set_expanded(false)
	for i in range(1000):
		game._process(game.STEP)
		feed._process(game.STEP)
		panel.code_fx.advance(game.STEP,false)
		if not feed.names.is_empty(): break
	verify(not feed.names.is_empty(),"Real ordinary skill gets actor nameplate")
	verify(feed.records.size() > 4,"Journal keeps more than four entries")
	feed.announcements.clear()
	game._update_battle_presentations()
	game.queue_redraw()
	await shot("personal-skill")
	for kind in game.simulation.blocks: game.simulation.blocks[kind] = 0
	game.simulation.ready_at = 0
	game.simulation.program_ready.clear()
	panel._update_hud()
	verify(panel.program_controls.redirect.button.state_code == "missing","Missing-code appearance")
	verify(panel.program_controls.redirect.recipe.purple.stock == 0,"Cost exposes actual shortage")
	verify(panel.program_controls.redirect.name.modulate != Color.WHITE,"Unavailable name is visually subdued")
	game.queue_redraw()
	await shot("missing")
	game.simulation.upgrades.append("buffer")
	panel._update_bonds()
	verify(panel.buff_button.text == "增益 1" and panel.buff_details.plain_copy.contains("协议缓冲"),"Real persistent program modifier appears in team buffs")
	panel.buff_button.pressed.emit()
	verify(panel.buff_details.visible and panel.hover_paused(),"Buff details pause for reading")
	panel.buff_button.pressed.emit()
	feed.announce("先释放",Color.WHITE)
	feed.announce("后释放",Color.WHITE)
	verify(feed.announcements[0].text == "后释放" and feed.announcements.size() <= 2,"Latest skill appears immediately without queue lag")
	feed.set_expanded(true)
	verify(feed.history.text.contains(":"),"Journal uses minute-second timestamps")
	feed.filter_button.pressed.emit()
	verify(not feed.important_only,"Journal can switch to full records")
	feed.set_expanded(false)
	game.effects.clear()
	var hit := {"actor":game.units[0],"target":game.units[1],"kind":"damage","actual":5,"blocked":0}
	game._present_event(hit)
	game._present_event(hit)
	verify(game.effects.size() == 1 and game.effects[0].value == 10,"Near-simultaneous same-kind numbers combine visually")
	game._build_units()
	verify(feed.records.is_empty() and feed.names.is_empty() and feed.announcements.is_empty(),"Retry clears previous battle journal and announcements")
	print("BATTLE_ACTIVITY_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(failures)
