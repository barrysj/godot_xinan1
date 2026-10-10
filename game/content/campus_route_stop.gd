@tool
class_name CampusRouteStop
extends Resource
## ID 在本区域内唯一；同一地点可以被多个不同站点引用。
@export var id: String = ""
@export var place: CampusRoutePlace
@export_group("已有内容引用")
@export var encounter: CampusEncounter
@export_range(0.1, 3.0, 0.01) var power: float = 0.7
## 引用原热点／回忆模板，具体事件仍在原多轮对话图谱中维护。
@export_enum("gate", "walk", "court", "hall", "library", "end_b", "end_c") var hotspot_template: String = "gate"
