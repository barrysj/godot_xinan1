@tool
class_name CampusManifest
extends Resource
## 导出时随资源引用打包；文件存在不代表已经注册。
@export var equipment: Array[CampusEquipment] = []
@export var characters: Array[CampusUnit] = []
@export var enemies: Array[CampusUnit] = []
@export var skills: Array[CampusSkill] = []
@export var encounters: Array[CampusEncounter] = []
@export var rewards: Array[CampusReward] = []
@export var reward_pools: Array[CampusRewardPool] = []
@export var events: Array[CampusEvent] = []
@export var locations: Array[CampusLocation] = []
