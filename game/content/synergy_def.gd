@tool
class_name CampusSynergy
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(2, 4) var required_count: int = 2
@export var effects: Array[CampusBattleProc] = []
