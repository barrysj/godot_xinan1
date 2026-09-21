@tool
class_name CampusBattleProc
extends Resource
## One non-recursive, declarative response to a combat event.
@export var id: String = ""
@export_enum("battle_start", "skill_impact", "before_damage_skill", "half_health", "hack_complete", "verify", "skill_emit") var trigger: String = "battle_start"
@export_enum("shield", "heal", "hack", "mark", "attack_speed", "damage_bonus", "pierce") var effect: String = "shield"
@export_enum("owner", "lowest_ally", "lowest_other_near", "skill_target") var target: String = "owner"
@export_enum("owner", "team", "action", "none") var limit: String = "owner"
@export var value: float = 0.0
@export var max_health_ratio: float = 0.0
@export var duration: float = 0.0
@export var radius: float = 2.05
@export var required_tag: String = ""
@export var source: String = ""
## Colored-code mode uses these fields instead of the legacy progress value.
@export var code_amount := 1
@export var code_type := ""
