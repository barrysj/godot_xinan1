@tool
class_name CampusCombatCharacter
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var tags: Array[String] = []
@export var effects: Array[CampusBattleProc] = []
@export_enum("red", "blue", "green", "purple") var code_type := "red"
