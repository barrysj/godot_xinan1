@tool
class_name CampusLocation
extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("battle", "elite", "event", "boss") var kind: String = "battle"
@export_enum("start", "safe", "risk", "final") var route_pool: String = "safe"
@export_range(0.1, 3.0, 0.01) var power: float = 1.0
@export var encounter: CampusEncounter
@export var event: CampusEvent
@export var rewards: CampusRewardPool

func snapshot() -> Dictionary:
	return {"id":id,"name":display_name,"description":description,"kind":kind,"power":power,"encounter":0 if encounter == null or encounter.id == "encounter_patrol" else 1,"encounter_id":encounter.id if encounter != null else "","event":event.snapshot() if event != null else {},"reward_pool":rewards.id if rewards != null else ""}
