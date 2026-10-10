@tool
extends EditorInspectorPlugin
func _can_handle(object: Object) -> bool:
	return object is CampusRegionFlow
func _parse_begin(object: Object) -> void:
	var panel = preload("res://addons/campus-flow/summary.gd").new()
	panel.flow = object
	add_custom_control(panel)
