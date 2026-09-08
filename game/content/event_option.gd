@tool
class_name CampusEventOption
extends Resource
@export var id: String = ""
@export var text: String = "收下心意"
@export_multiline var description: String = ""
@export_group("条件与支付")
@export_range(0, 100) var minimum_points: int = 0
@export_range(0, 100) var cost: int = 0
@export var required_character: CampusUnit
@export var required_equipment: CampusEquipment
@export_group("结果")
@export var results: Array[CampusReward] = []
@export var open_rewards: bool = true

func snapshot() -> Dictionary:
	return {"id":id,"text":text,"description":description,"minimum_points":minimum_points,"cost":cost,"character":required_character.id if required_character != null else "","equipment":required_equipment.id if required_equipment != null else "","results":results.map(func(item): return item.snapshot()),"open_rewards":open_rewards}
