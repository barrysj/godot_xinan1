@tool
class_name CampusRouteStage
extends Resource
## 同一站的 Choices 是互斥岔路；完成所选地点后进入下一站。
@export var choices: Array[CampusRouteStop] = []
