@tool
class_name CampusCombatReward
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("羁绊", "装备", "训练", "专属") var category: String = "羁绊"
@export var character_id: String = ""
@export var health_multiplier: float = 1.0
@export var attack_multiplier: float = 1.0
@export var mark_uses_bonus: int = 0
@export var effects: Array[CampusBattleProc] = []
