extends Node
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const OUT := "res://.godot/art-workflow/battle-hud-polish/"
var game
var checks := 0
var failures := 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func mouse(at: Vector2, click := false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	get_viewport().warp_mouse(at)
	get_viewport().push_input(motion,true)
	if click:
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.position = at
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			get_viewport().push_input(event,true)
	await frame()
func escape() -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.pressed = pressed
		get_viewport().push_input(event,true)
	await frame()
func shot(label: String) -> void:
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	if not "--capture" in OS.get_cmdline_user_args(): return
	var resolution := get_window().size
	verify(get_viewport().get_texture().get_image().save_png(OUT+"%s-%dx%d.png" % [label,resolution.x,resolution.y]) == OK,"Captured "+label)
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	game = Campaign.instantiate()
	game.progress.path = OUT+"profile-%d.json" % Time.get_ticks_usec()
	add_child(game)
	game.storage_ready = false
	game.set_process(false)
	game.tutorial_guide.skipped = true
	game.tutorial_guide.hide()
	game._begin_region("library","prologue")
	game._guard()
	game.formation = [0,-1,3,2,1,-1]
	game.run.code_programs = ["disconnect","redirect","repair"]
	game._start()
	await frame()
	var card = game.inspector
	var hud = game.battle_status_layer
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200),Vector2i(1280,720)]:
		get_window().size = resolution
		await frame()
		game._process(0)
		hud._process(0)
		for side in [0,1]:
			var unit: Dictionary = game.units.filter(func(u): return u.side == side)[0]
			var at: Vector2 = hud.hit_rects[unit.id].get_center()
			await mouse(at)
			verify(card.panel.visible and not card.pinned and card.heading.text == unit.name,"Both status hovers use the shared character card")
			verify(card.action_section.visible and not card.skill_section.visible,"Shared summary shows current action before expanded skill")
			verify(game.code_panel.hover_paused(),"Character reading owns operation pause")
			var before: float = game.simulation.elapsed
			game._process(0.2)
			verify(game.simulation.elapsed == before,"Reading a character freezes real battle time")
			await mouse(at,true)
			verify(card.pinned and card.skill_section.visible and card.description.visible,"Both sides expand the same skill section on click")
			verify(card.gear_row.visible == (side == 0),"Only friendly characters offer equipment")
			verify(card.panel.size.x <= 304 and get_viewport().get_visible_rect().encloses(card.panel.get_global_rect()),"Unified card fits viewport")
			await shot("ally-detail" if side == 0 else "enemy-detail")
			await escape()
			verify(not card.panel.visible and not game.paused and not game.pause_overlay.visible,"Escape dismisses only the shared card (card=%s paused=%s menu=%s)" % [card.panel.visible,game.paused,game.pause_overlay.visible])
			await mouse(at)
			verify(not card.panel.visible,"Mouse still on dismissed character cannot immediately reopen card")
			await mouse(Vector2(12,200))
			verify(not game.code_panel.hover_paused(),"Leaving card releases operation pause")
		var enemy: Dictionary = game.units.filter(func(u): return u.side == 1)[0]
		await mouse(hud.intents[enemy.id].get_center(),true)
		verify(card.pinned and card.observed.id == enemy.id,"Enemy thought bubble opens the same detail")
		await escape()
		await mouse(Vector2(12,200))
		var panel = game.code_panel
		panel._process(0)
		await frame()
		var clock: Rect2 = panel.clock.get_global_rect()
		verify(panel.dock.get_global_rect().encloses(clock) and panel.playback.get_global_rect().encloses(clock),"Battle clock belongs to bottom-right playback group")
		verify(panel.playback.get_global_rect().encloses(panel.summary.get_global_rect()),"Pause status belongs to the same playback group")
		verify(panel.pause_control.get_global_rect().position.y >= clock.end.y,"Timing row stays above playback buttons")
		verify(panel.bond_panel.get_global_rect().end.x < panel.warning_surface.get_global_rect().position.x,"Synergy portraits leave the central warning lane clear")
		verify(panel.warning_surface.get_global_rect().end.x < panel.activity.toggle.get_global_rect().position.x,"Warning and journal retain separate lanes")
		panel.activity.set_expanded(true)
		await frame()
		verify(panel.activity.history.get_global_rect().position.y > panel.activity.toggle.get_global_rect().end.y,"Expanded journal flows below its entry")
		verify(not panel.activity.history.get_global_rect().intersects(panel.bond_panel.get_global_rect()),"Journal cannot cover synergy members")
		await shot("top-journal")
		panel.activity.set_expanded(false)
	await cast_names()
	game.free()
	print("BATTLE_HUD_POLISH_CHECK checks=%d failures=%d" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func step_battle(count: int) -> void:
	for step in count:
		game._process(game.STEP)
		game.code_panel.activity._process(game.STEP)

func cast_names() -> void:
	get_window().size = Vector2i(1920,1080)
	game._start()
	game.code_panel._process(0)
	await mouse(Vector2(12,200))
	var feed = game.code_panel.activity
	step_battle(1)
	verify(feed.names.is_empty(),"Basic attack windup never creates a skill name")
	for step in 900:
		step_battle(1)
		if not feed.names.is_empty(): break
	verify(not feed.names.is_empty(),"Natural skill start immediately creates its name")
	if feed.names.is_empty(): return
	var entry: Dictionary = feed.names[0]
	var actor: Dictionary = game.simulation.unit(entry.id)
	verify(actor.action.get("kind","") == "cast" and not actor.action.released and entry.exit_age < 0,"Skill name begins during actual windup")
	step_battle(4)
	game.paused = true
	var age: float = entry.age
	feed._process(0.5)
	game._process(0.5)
	verify(entry.age == age,"Manual pause freezes name animation with its cast")
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200),Vector2i(1280,720)]:
		get_window().size = resolution
		await frame()
		await shot("skill-windup")
	get_window().size = Vector2i(1920,1080)
	await frame()
	game.paused = false
	for step in 100:
		step_battle(1)
		if entry.exit_age >= 0: break
	verify(entry.exit_age >= 0 and not entry.cancelled,"Real release starts disappearance")
	await shot("skill-release")
	feed._process(feed.exit_seconds+0.01)
	verify(not feed.names.any(func(item): return item.id == actor.id and item.action_id == entry.action_id),"Name disappears after release without a fixed lingering timer")
	game._start()
	game.code_panel._process(0)
	for unit in game.units:
		unit.hp = 50000
		unit.max_hp = 50000
	await mouse(Vector2(12,200))
	for step in 1000:
		step_battle(1)
		if not game.simulation.warnings.is_empty(): break
	verify(not game.simulation.warnings.is_empty(),"Original battle naturally reaches timed enemy cast")
	if game.simulation.warnings.is_empty(): return
	var id: int = game.simulation.warnings.keys()[0]
	var matches: Array = feed.names.filter(func(item): return item.id == id and item.exit_age < 0)
	verify(not matches.is_empty(),"Enemy warning has its own actor skill name")
	if matches.is_empty(): return
	entry = matches[0]
	step_battle(30)
	verify(entry.age > 1.3 and entry.exit_age < 0,"Long windup keeps its name beyond old timeout")
	game.paused = true
	await shot("enemy-windup")
	game.paused = false
	game.simulation.unit(id).hp = 0
	step_battle(1)
	verify(entry.exit_age >= 0 and entry.cancelled,"Death cancellation fades the matching action name")
	await shot("skill-interrupted")
	feed._process(feed.exit_seconds+0.01)
	verify(not feed.names.any(func(item): return item.id == id),"Cancelled name is removed")
	game._start()
	game.code_panel._process(0)
	await mouse(Vector2(12,200))
	var sim = game.simulation
	for unit in sim.units:
		var target: Dictionary = sim.units.filter(func(other): return other.side != unit.side)[0]
		sim._start_cast(unit,target,3.0)
	game.code_panel._consume_pending()
	feed._process(0.16)
	game._update_battle_presentations()
	await shot("simultaneous-casts")
	verify(feed.name_bounds.size() == sim.units.size(),"Every concurrent real cast has a visible name frame")
	for i in feed.name_bounds.size():
		var bounds: Rect2 = feed.name_bounds[i]
		var text: String = feed._fit_name(feed.names[i].text,202)
		var text_width: float = feed.FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		verify(is_equal_approx(bounds.size.x,text_width+42),"Skill frame fits actual text and icon padding")
		verify(Rect2(16,174,1248,422).encloses(bounds),"Skill names clear header and dock")
		for status in game.battle_status_layer.status_rects.values(): verify(not bounds.intersects(status),"Skill names avoid real status strips")
		for j in range(i+1,feed.name_bounds.size()): verify(not bounds.intersects(feed.name_bounds[j]),"Concurrent skill names remain separate")
	game.paused = true
	var ages: Array = feed.names.map(func(item): return item.age)
	feed._process(1.0)
	verify(ages == feed.names.map(func(item): return item.age),"Concurrent names also honor pause")
	game.paused = false
	game.code_panel.code_fx.reduced_motion = true
	verify(feed.names.all(func(item): return is_equal_approx(feed.name_alpha(item),1.0)),"Reduced motion retains immediate readable cast names")
	game._build_units()
	verify(feed.names.is_empty(),"Retry clears active and fading nameplates")
