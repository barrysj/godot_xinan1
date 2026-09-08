@tool
class_name CampusReward
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("gear", "recruit", "train", "points") var operation: String = "train"
@export var equipment: CampusEquipment
@export var character: CampusUnit
@export_range(1, 100) var amount: int = 1

func snapshot() -> Dictionary:
	return {"id":id,"title":display_name,"description":description,"operation":operation,"target":equipment.id if operation == "gear" and equipment != null else (character.id if character != null else ""),"amount":amount}
