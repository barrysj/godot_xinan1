@tool
class_name CampusTrialEncounter
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var pulse_interval: float = 6.0
@export var pulse_shield: float = 70.0
@export var units: Array[CampusUnit] = []
@export var slots: Array[int] = []
@export var reward_ids: Array[String] = []
