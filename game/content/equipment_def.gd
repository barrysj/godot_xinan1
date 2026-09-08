@tool
class_name CampusEquipment
extends Resource
## 一件静态装备；复制资源后先修改稳定 ID。当前穿戴者属于探索存档。
@export_group("身份与展示")
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_group("战斗属性")
@export_range(0, 10000) var health_bonus: int = 0
@export_range(0, 1000) var attack_bonus: int = 0
@export_range(0.1, 3.0, 0.01) var interval_multiplier: float = 1.0

func apply(unit: Dictionary) -> void:
	unit.max_hp += health_bonus
	unit.atk += attack_bonus
	unit.interval *= interval_multiplier
	unit.timer = unit.interval
	unit.hp = unit.max_hp
