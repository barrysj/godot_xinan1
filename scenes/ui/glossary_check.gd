extends Node
var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("GLOSSARY: "+message)
func frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
func click(at: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
func _ready() -> void:
	var glossary = preload("res://game/content/glossary.gd")
	expect(glossary.markup("追踪破解").count("[url=") == 1,"longest term is not nested")
	expect(glossary.markup("[b]代码").begins_with("[lb]b]"),"literal brackets cannot inject formatting")
	var game = preload("res://scenes/expedition/expedition.tscn").instantiate()
	game.progress.path = "user://glossary-check-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await frame()
	game.tutorial_guide.skipped = true
	game._begin_region("library","prologue","analysis")
	game._guard()
	game.formation = [0,1,2,3,-1,-1]
	var roster: Array[int] = [0,1,2,3]
	game.run.roster = roster
	game._build_units()
	game._start()
	expect(game.phase == "battle","original battle started")
	game.set_process(false)
	await frame()
	game.paused = true
	await frame()
	click(game.code_panel.program_controls.disconnect.button.get_global_rect().get_center())
	await frame()
	expect(game.code_panel.program_preview.visible,"paused program actual click opens description")
	expect(game.code_panel.preview_release.disabled,"paused program cannot spend resources")
	game.code_panel._hide_program_preview()
	click(game.code_panel.item_controls.supply.icon.get_global_rect().get_center())
	await frame()
	expect(game.code_panel.selected_item == "supply","paused item actual click opens description")
	expect(game.code_panel.item_controls.supply.button.disabled,"paused item cannot spend resources")
	game.code_panel._select_item("")
	expect(not glossary.TERMS.has("已确认"),"confirmed is not a glossary term")
	game.code_panel._show_program_preview("disconnect",true)
	await frame()
	var rich = game.code_panel.preview_effect
	expect(rich.get_theme_font("normal_font").resource_path.contains("SourceHan"),"bundled Chinese font")
	await frame()
	await frame()
	var bounds: Rect2 = rich.get_global_rect()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://paused-preview.png" if OS.has_feature("web") else "res://.godot/paused-preview.png")
	var bundled = rich.get_theme_font("normal_font")
	bundled.allow_system_fallback = false
	var missing := ""
	for term in glossary.TERMS:
		for character in term+str(glossary.TERMS[term][1]):
			if not bundled.has_char(character.unicode_at(0)): missing += character
	expect(missing.is_empty(),"all glossary characters exist without system fallback: "+missing)
	if "--preview" in OS.get_cmdline_user_args():
		print("GLOSSARY_PREVIEW_READY failures=",failures)
		return
	var found := Vector2(-1,-1)
	# Real glyph hit testing, not direct signal emission.
	for y in range(int(bounds.position.y+5),int(bounds.end.y),8):
		for x in range(int(bounds.position.x+3),int(bounds.end.x),8):
			var move := InputEventMouseMotion.new()
			move.position = Vector2(x,y)
			move.global_position = move.position
			get_viewport().warp_mouse(move.position)
			get_viewport().push_input(move,true)
			await frame()
			if not rich.active_term.is_empty():
				found = Vector2(x,y)
				break
		if found.x >= 0: break
	expect(found.x >= 0,"hovering a highlighted word opens explanation")
	if found.x >= 0:
		click(found)
		await frame()
		expect(rich.pinned and is_instance_valid(rich.tooltip_panel),"click pins explanation")
		expect(game.code_panel.hover_paused(),"reading preserves combat hover pause")
		expect(get_viewport().get_visible_rect().encloses(rich.tooltip_panel.get_global_rect()),"explanation stays on screen")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://glossary.png" if OS.has_feature("web") else "res://.godot/glossary.png")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		get_viewport().push_input(escape,true)
		await frame()
		expect(not rich.pinned and not game.pause_overlay.visible,"Esc closes explanation without opening game menu")
		rich.show_term("代码",true)
		await frame()
		click(Vector2(1800,120))
		await frame()
		expect(not rich.pinned,"outside click dismisses")
		rich.show_term("验证",true)
		game.code_panel.program_preview.hide()
		await frame()
		expect(not rich.pinned and rich.tooltip_panel == null,"hiding source closes explanation")
	game.code_panel._hide_program_preview()
	await frame()
	expect(game.code_panel.bond_rows.size() == 2,"multiple team bonds have separate rows")
	for id in game.code_panel.bond_rows:
		var row = game.code_panel.bond_rows[id]
		expect(game.code_panel.bond_counts[id].text == "2/2" and row.modulate.a == 1.0,"mixed roster activates each listed bond")
		expect(game.code_panel.bond_members[id].get_child_count() == 2,"Both counted bond members have portraits")
	var bond = game.code_panel.bond_rows.analysis
	await inspect_link(bond,"漏洞研究")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/bonds-team.png")
	bond.close_term()
	var unit = game.units.filter(func(u): return u.side == 0)[0]
	var at: Vector2 = game.origin+(game._unit_center(unit)+Vector2(0,-35))*game.scale_factor
	var hover := InputEventMouseMotion.new()
	hover.position = at
	hover.global_position = at
	get_viewport().warp_mouse(at)
	get_viewport().push_input(hover,true)
	await frame()
	expect(game.inspector.panel.visible and not game.inspector.pinned and game.inspector.bond_tags.visible,"hover summary includes character tags")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/bonds-character-hover.png")
	click(at)
	await frame()
	expect(game.inspector.pinned and game.inspector.bond_tags.visible,"character click reveals tags inside information panel")
	var label = game.inspector.bond_tags
	await inspect_link(label,preload("res://game/content/glossary.gd").unit_tags(unit))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/bonds-unit.png")
	label.close_term()
	game.inspector.close_info()
	game._open_team_panel()
	await frame()
	var team = game.team_panel
	expect(not team.bond_tags.plain_copy.contains("羁绊") and not team.bond_tags.plain_copy.is_empty(),"Bond field heading is separate from clickable values")
	await inspect_link(team.bond_tags,team.bond_tags.plain_copy.trim_prefix("羁绊 · "))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/bonds-character-info.png")
	team.bond_tags.close_term()
	team.close_panel()
	await frame()
	var active_before = game.simulation.tag_ids.duplicate()
	game.units[0].hp = 0
	await frame()
	expect(game.simulation.tag_ids == active_before,"retirement does not deactivate locked bonds")
	print("GLOSSARY_CHECK checks=",checks," failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)

func inspect_link(rich, expected: String) -> void:
	await frame()
	var bounds: Rect2 = rich.get_global_rect()
	var found := false
	for x in range(int(bounds.position.x+4),int(bounds.end.x),6):
		var at := Vector2(x,bounds.position.y+10)
		var move := InputEventMouseMotion.new()
		move.position = at
		move.global_position = at
		get_viewport().warp_mouse(at)
		get_viewport().push_input(move,true)
		await frame()
		if rich.active_term == expected:
			click(at)
			await frame()
			found = rich.pinned
			break
	expect(found,"actual hover and click explain "+expected)
	await frame()
	expect(rich.pinned,"explanation survives subsequent UI updates")
