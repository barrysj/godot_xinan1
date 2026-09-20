extends Control

const ProgressModel = preload("res://game/meta/campus_progress.gd")
const BACKGROUNDS = [
	{
		"name": "图书馆",
		"normal": "res://design/concepts/m1-main-menu/m1_main_menu_visual/002/library.png",
		"anomaly": "res://design/concepts/m1-main-menu/m1_main_menu_visual/006/library-anomaly.png",
	},
	{
		"name": "品学楼",
		"normal": "res://design/concepts/m1-main-menu/m1_main_menu_visual/002/pinxue-building.png",
		"anomaly": "res://design/concepts/m1-main-menu/m1_main_menu_visual/006/pinxue-building-anomaly.png",
	},
	{
		"name": "银杏主楼",
		"normal": "res://design/concepts/m1-main-menu/m1_main_menu_visual/005/ginkgo-main-building.png",
		"anomaly": "res://design/concepts/m1-main-menu/m1_main_menu_visual/006/ginkgo-main-building-anomaly.png",
	},
]
const BACKGROUND_HOLD_SECONDS := 8.0

@export var play_button: Button
@export var settings_button: Button
@export var exit_button: Button
@export var settings_menu: Control
@export var margin_container: MarginContainer
@export var background: TextureRect
@export var background_tint: ColorRect
@export var state_label: Label
var codex_panel: Control
var codex_button: Button
var background_index := 0
var background_elapsed := 0.0
var normal_backgrounds_unlocked := false

func _load_progress_state() -> void:
	var progress = ProgressModel.new()
	# A missing save is a fresh anomaly state; an unreadable save must not be
	# overwritten or accidentally unlock the restored campus presentation.
	normal_backgrounds_unlocked = progress.read_save() and bool(progress.campaign.get("restored", false))

func _background_path(index: int) -> String:
	return str(BACKGROUNDS[index].normal if normal_backgrounds_unlocked else BACKGROUNDS[index].anomaly)

func _set_background(index: int, instant := false) -> void:
	background_index = posmod(index, BACKGROUNDS.size())
	var texture = load(_background_path(background_index)) as Texture2D
	if texture == null:
		return
	if instant:
		background.texture = texture
		background.modulate.a = 1.0
		return
	background.modulate.a = 0.0
	background.texture = texture
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(background, "modulate:a", 1.0, 0.65)

func _update_state_label() -> void:
	if normal_backgrounds_unlocked:
		state_label.text = "校园已恢复 · 日常影像已解锁"
		state_label.modulate = Color("ffe4a6")
		background_tint.color = Color(0.015, 0.025, 0.07, 0.20)
	else:
		state_label.text = "异常校园 · 完整通关后恢复日常影像"
		state_label.modulate = Color("a9f4ff")
		background_tint.color = Color(0.01, 0.02, 0.08, 0.38)

func _open_codex() -> void:
	if is_instance_valid(codex_panel): return
	codex_panel = load("res://scenes/codex/codex_panel.gd").new()
	add_child(codex_panel)
	codex_panel.closed.connect(func(): codex_button.grab_focus())


func _ready():
	_load_progress_state()
	_update_state_label()
	_set_background(0, true)
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


func _process(delta: float) -> void:
	if settings_menu.visible or (is_instance_valid(codex_panel) and codex_panel.visible):
		return
	background_elapsed += delta
	if background_elapsed >= BACKGROUND_HOLD_SECONDS:
		background_elapsed = 0.0
		_set_background(background_index + 1)


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
