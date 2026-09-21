@tool
class_name CampusTrialCharacter
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var unit: CampusUnit
@export var tags: Array[String] = []
@export var skill_override: CampusSkill
@export var stats: Dictionary = {}
@export var effects: Array[CampusBattleProc] = []
