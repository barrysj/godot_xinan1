extends Node
## Check the fonts actually resolved by the original battle HUD, without OS fallback.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Codes = preload("res://game/combat/code_catalog.gd")
var checks := 0
var failures := 0
var fonts := {}

func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BATTLE_FONT_CHECK: " + message)

func check_text(control, text: String, label: String, key := "font") -> void:
	var original: Font = control.get_theme_font(key)
	if not fonts.has(original.get_instance_id()):
		var copy: Font = original.duplicate(true)
		if copy is FontFile: copy.allow_system_fallback = false
		if copy is FontVariation and copy.base_font is FontFile: copy.base_font.allow_system_fallback = false
		fonts[original.get_instance_id()] = copy
	var font: Font = fonts[original.get_instance_id()]
	var missing := ""
	for character in text:
		if character in ["\n", "\r", "\t"]: continue
		if not font.has_char(character.unicode_at(0)) and not missing.contains(character):
			missing += character
	verify(missing.is_empty(), "%s missing [%s] in %s" % [label, missing, control.get_theme_font(key).resource_path])

func check_controls(node: Node) -> void:
	if node is Label and not node.text.is_empty():
		check_text(node, node.text, str(node.get_path()))
	elif node is Button and not node.text.is_empty():
		check_text(node, node.text, str(node.get_path()))
	if node is OptionButton:
		for index in node.item_count:
			check_text(node.get_popup(), node.get_item_text(index), "dropdown")
	for child in node.get_children():
		check_controls(child)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/art-workflow/battle-font-check")
	var game = Campaign.instantiate()
	game.progress.path = "res://.godot/art-workflow/battle-font-check/profile-%d.json" % Time.get_ticks_usec()
	add_child(game)
	game.storage_ready = false
	game.set_process(false)
	game._begin_region("library", "prologue")
	game._guard()
	game.run.node.encounter_id = "encounter_classroom"
	game.formation = [0, 1, 2, 3, -1, -1]
	game.run.roster.assign([0, 1, 2, 3])
	game._build_units()
	game._start()
	var choice_label := Label.new()
	choice_label.add_theme_font_override("font", preload("res://scenes/expedition/choice_skin.gd").font("body"))
	add_child(choice_label)
	check_text(choice_label, "校园运行记录选择路线出发准备派遣破解验证护盾权限追踪", "choice theme")
	check_controls(game.tutorial_guide)
	check_text(game.tutorial_guide.description, "操作指引探索热点排列阵型积攒代码使用物品暂停调整速度解锁派遣校园路线", "tutorial")
	var panel = game.code_panel
	panel._process(0)
	panel.set_process(false)
	for program in Codes.RULES.programs:
		game.simulation.loadout = [program.id, "repair" if program.id != "repair" else "disconnect"]
		panel._process(0)
		panel._show_program_preview(program.id, true)
		verify(panel.preview_effect.text == program.description, "original program description " + program.id)
		check_text(panel.preview_effect, program.description, "program " + program.id)
		check_controls(panel.program_preview)
	for item in Codes.RULES.items:
		panel._select_item(item.id)
		check_controls(panel.item_controls[item.id].card)
	for kind in Codes.RULES.types:
		check_text(panel.bank_labels[kind], Codes.RULES.types[kind].name + "全队吸收已满", "code " + kind)
	check_controls(panel)
	game.inspector.show_unit(game.units[0], true)
	check_controls(game.inspector)
	# Retain the original battle for optional native visual verification.
	panel._select_item("supply")
	await get_tree().process_frame
	await get_tree().process_frame
	print("BATTLE_FONT_CHECK checks=%d failures=%d platform=%s" % [checks, failures, OS.get_name()])
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/art-workflow/battle-font-check/native.png")
	if "--keep-open" not in OS.get_cmdline_user_args():
		get_tree().quit(0 if failures == 0 else 1)
