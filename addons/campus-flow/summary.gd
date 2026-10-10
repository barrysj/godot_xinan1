@tool
extends VBoxContainer
var flow: CampusRegionFlow
var overview_label: Label
var status: Label
var preview_button: Button
func _ready() -> void:
	add_theme_constant_override("separation",8)
	var title := Label.new()
	title.text = "探索流程概览"
	add_child(title)
	overview_label = Label.new()
	overview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(overview_label)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	var actions := HBoxContainer.new()
	add_child(actions)
	var check := Button.new()
	check.name = "ValidateFlow"
	check.text = "校验"
	check.pressed.connect(refresh)
	actions.add_child(check)
	preview_button = Button.new()
	preview_button.text = "流程预览"
	preview_button.pressed.connect(preview)
	actions.add_child(preview_button)
	var guide := Button.new()
	guide.text = "配置指南"
	guide.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("res://docs/campus-flow-authoring.md")))
	actions.add_child(guide)
	refresh()
func refresh() -> void:
	if flow == null: return
	overview_label.text = flow.overview()
	var errors := flow.validate()
	status.text = "校验通过 · 同站任选其一，完成后进入下一站" if errors.is_empty() else "\n".join(errors)
	status.modulate = Color("94dab4") if errors.is_empty() else Color("ffb295")
	preview_button.disabled = not errors.is_empty()
func preview() -> void:
	refresh()
	if not flow.validate().is_empty(): return
	var file := FileAccess.open("res://.godot/campus-flow-preview.json",FileAccess.WRITE)
	if file == null:
		status.text = "预览数据写入失败"
		return
	file.store_string(JSON.stringify(flow.snapshot()))
	file.close()
	EditorInterface.play_custom_scene("res://scenes/content/campus_flow_preview.tscn")
