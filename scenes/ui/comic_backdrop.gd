extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	preload("res://scenes/ui/comic_ui.gd").backdrop(self,size)
