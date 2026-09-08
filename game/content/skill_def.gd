@tool
class_name CampusSkill
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_enum("shield", "arrow", "heart", "bolt", "flask") var glyph: String = "shield"
@export_range(1, 20) var attacks_to_trigger: int = 3
@export var effects: Array[CampusEffect] = []
