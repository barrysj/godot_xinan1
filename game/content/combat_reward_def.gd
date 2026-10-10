@tool
class_name CampusCombatReward
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("羁绊", "装备", "训练", "专属", "程序") var category: String = "羁绊"
@export var character_id: String = ""
@export var health_multiplier: float = 1.0
@export var attack_multiplier: float = 1.0
@export var mark_uses_bonus: int = 0
@export var effects: Array[CampusBattleProc] = []

## Additive modifiers for a registered program, separate from character training.
@export var program_id: String = ""
@export var program_duration_bonus: float = 0.0
@export var program_damage_bonus: float = 0.0

@export_group("候选与权重")
@export var reward_chain: String = "general"
@export_range(1,100) var reward_weight: int = 3
@export_range(1,100) var minimum_offer: int = 1
@export var required_tag: String = ""
@export_range(0,4) var required_tag_count: int = 0
