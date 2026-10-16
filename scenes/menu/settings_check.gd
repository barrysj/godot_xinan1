extends Node
var checks := 0
var failures := 0
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("SETTINGS: "+message)
func frame() -> void:
	await get_tree().create_timer(0.15).timeout
	await get_tree().process_frame
func click(control: Control) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
func _ready() -> void:
	GGT_GameConfig.settings_path = "user://settings-check-%d.cfg" % Time.get_ticks_usec()
	GGT_GameConfig.initialize_default_file()
	GGT_GameConfig.set_fullscreen(false)
	get_window().size = Vector2i(1920,1080)
	var menu = preload("res://scenes/menu/menu.tscn").instantiate()
	add_child(menu)
	await frame()
	click(menu.settings_button)
	await frame()
	var panel = menu.settings_menu
	expect(panel.visible,"real menu button opens project settings")
	expect(panel.tutorial_toggle.button_pressed,"guidance defaults on")
	var font = panel.status.get_theme_font("font")
	font.allow_system_fallback = false
	var missing := ""
	for node in panel.find_children("*","Control",true,false):
		if node is Label or node is Button:
			for character in node.text:
				if character.unicode_at(0) < 32: continue
				if not font.has_char(character.unicode_at(0)): missing += character
	expect(missing.is_empty(),"settings characters available without fallback: "+missing)
	panel.sliders.master.value = 50
	expect(is_equal_approx(AudioServer.get_bus_volume_db(0),linear_to_db(0.5)),"slider changes real master bus")
	var fps_index: int = panel.fps_picker.get_item_index(30)
	panel.fps_picker.select(fps_index)
	panel.fps_picker.item_selected.emit(fps_index)
	expect(Engine.max_fps == 30,"frame cap changes engine setting")
	click(panel.vsync_toggle)
	expect(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED,"vsync toggle changes actual window")
	click(panel.fullscreen_toggle)
	await frame()
	expect(get_window().mode == Window.MODE_FULLSCREEN,"fullscreen toggle changes actual window")
	click(panel.cancel_button)
	await frame()
	expect(Engine.max_fps == 60 and get_window().mode == Window.MODE_WINDOWED,"cancel restores display preferences")
	expect(not panel.visible and is_zero_approx(AudioServer.get_bus_volume_db(0)),"cancel restores previewed audio")
	click(menu.settings_button)
	await frame()
	click(panel.tutorial_toggle)
	click(panel.motion_toggle)
	panel.sliders.music.value = 35
	click(panel.save_button)
	await frame()
	var saved := ConfigFile.new()
	expect(saved.load(GGT_GameConfig.settings_path) == OK,"settings file saved")
	expect(not saved.get_value("game","tutorial_enabled",true) and saved.get_value("game","reduced_motion",false),"preferences persisted")
	click(menu.settings_button)
	await frame()
	expect(not panel.tutorial_toggle.button_pressed and panel.motion_toggle.button_pressed,"reopen reflects saved values")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/settings.png")
	click(panel.reset_button)
	await frame()
	expect(panel.tutorial_toggle.button_pressed and not panel.motion_toggle.button_pressed,"defaults are previewed")
	click(panel.cancel_button)
	await frame()
	expect(not GGT_GameConfig.config.get_value("game","tutorial_enabled") and GGT_GameConfig.config.get_value("game","reduced_motion"),"cancel defaults restores saved snapshot")
	menu.queue_free()
	await frame()
	var game = preload("res://scenes/expedition/expedition.tscn").instantiate()
	game.progress.path = "user://settings-game-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await frame()
	game.tutorial_guide.skipped = false
	game.tutorial_guide.update()
	expect(not game.tutorial_guide.visible,"guidance preference applies in actual campaign")
	expect(game.code_panel.code_fx.reduced_motion,"effect preference applies in actual battle HUD")
	print("SETTINGS_CHECK checks=",checks," failures=",failures)
	get_tree().quit(0 if failures == 0 else 1)
