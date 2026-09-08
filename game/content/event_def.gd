@tool
class_name CampusEvent
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var image: Texture2D
@export var options: Array[CampusEventOption] = []

func snapshot() -> Dictionary:
	return {"id":id,"name":display_name,"description":description,"options":options.map(func(item): return item.snapshot())}
