extends Control

@export var play_button: Button
@export var settings_button: Button
@export var exit_button: Button
@export var settings_menu: Control
@export var margin_container: MarginContainer
var codex_panel: Control
var codex_button: Button

func _open_codex() -> void:
	if is_instance_valid(codex_panel): return
	codex_panel = load("res://scenes/codex/codex_panel.gd").new()
	add_child(codex_panel)
	codex_panel.closed.connect(func(): codex_button.grab_focus())


func _ready():
	codex_button = Button.new()
	codex_button.text = "校园图鉴"
	codex_button.add_theme_font_override("font",preload("res://assets/fonts/SourceHanSansSC-Medium.otf"))
	codex_button.custom_minimum_size = Vector2(200,70)
	play_button.get_parent().add_child(codex_button)
	play_button.get_parent().move_child(codex_button,1)
	codex_button.pressed.connect(_open_codex)
	play_button.focus_neighbor_bottom = play_button.get_path_to(codex_button)
	play_button.focus_next = play_button.get_path_to(codex_button)
	codex_button.focus_neighbor_top = codex_button.get_path_to(play_button)
	codex_button.focus_neighbor_bottom = codex_button.get_path_to(settings_button)
	settings_button.focus_neighbor_top = settings_button.get_path_to(codex_button)
	# needed for gamepads to work
	play_button.grab_focus()
	if OS.has_feature('web'):
		exit_button.queue_free() # exit button dosn't make sense on HTML5
	if "--codex-check" in OS.get_cmdline_user_args():
		var check = load("res://scenes/codex/codex_check.gd").new()
		get_tree().root.call_deferred("add_child",check)


func _on_PlayButton_pressed() -> void:
	GGT.change_scene("res://scenes/expedition/expedition.tscn", {"show_progress_bar": true})

func _on_ExitButton_pressed() -> void:
	# gently shutdown the game
	var transitions = get_node_or_null("/root/GGT_Transitions")
	if transitions:
		transitions.fade_in({
			'show_progress_bar': false
		})
		await transitions.anim.animation_finished
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	settings_menu.show()


func _on_settings_menu_visibility_changed() -> void:
	margin_container.visible = !settings_menu.visible
	if !settings_menu.visible:
		settings_button.grab_focus()


func _on_settings_menu_confirm_button_clicked() -> void:
	settings_menu.hide()
