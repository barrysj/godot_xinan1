@tool
class_name CampusEffect
extends Resource
## value + 攻击力 * attack_scale；所有目标在结算前确定，保留同时行动语义。
@export_enum("damage", "heal", "shield", "max_hp", "attack", "interval") var kind: String = "damage"
@export_enum("normal", "back", "low_enemy", "low_ally", "adjacent", "row", "self", "all_allies", "all_enemies") var target: String = "normal"
@export_range(0, 10000, 0.1) var value: float = 0
@export_range(0, 10, 0.1) var attack_scale: float = 0
