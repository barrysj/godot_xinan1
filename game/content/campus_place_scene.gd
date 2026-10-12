@tool
class_name CampusPlaceScene
extends Resource
## 地点内的独立背景与示意位置；不创建新的遭遇或奖励。
@export var id: String = ""
@export var display_name: String = ""
@export var background: Texture2D
## Open this scene in the native 2D editor. Marker names: memory/person/system/battle/passage.
@export var layout: PackedScene
## 小地图归一化平面位置，楼层由 floor 单独表达。
@export var map_position: Vector2 = Vector2(0.5, 0.5)
## 0 为地面，负数为地下，正数为楼层；不是建筑实测资料。
@export_range(-3, 12, 1) var floor: int = 0

func snapshot() -> Dictionary:
	var result := {"id":id, "title":display_name, "background":background.resource_path if background != null else "",
		"position":[map_position.x,map_position.y], "floor":floor}
	if layout != null:
		var canvas := layout.instantiate()
		result.layout = canvas.snapshot() if canvas.has_method("snapshot") else {}
		var preview: Texture2D = canvas.get("background")
		if preview == null or background == null or preview.resource_path != background.resource_path:
			result.layout["background_mismatch"] = []
		canvas.free()
	return result
