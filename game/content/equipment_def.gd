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

@export_group("新局成长预算")
## Negative values inherit the original budget; old active runs retain the original fields.
@export var balanced_health_bonus: int = -1
@export var balanced_attack_bonus: int = -1
@export var balanced_interval_multiplier: float = -1.0
@export_multiline var balanced_description: String = ""

func for_rules(version: int) -> CampusEquipment:
	if version < 2: return self
	var resolved: CampusEquipment = duplicate()
	if balanced_health_bonus >= 0: resolved.health_bonus = balanced_health_bonus
	if balanced_attack_bonus >= 0: resolved.attack_bonus = balanced_attack_bonus
	if balanced_interval_multiplier >= 0: resolved.interval_multiplier = balanced_interval_multiplier
	if not balanced_description.is_empty(): resolved.description = balanced_description
	return resolved

func apply(unit: Dictionary) -> void:
	unit.max_hp += health_bonus
	unit.atk += attack_bonus
	unit.interval *= interval_multiplier
	unit.timer = unit.interval
	unit.hp = unit.max_hp
