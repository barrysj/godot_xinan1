@tool
class_name CampusRoutePlace
extends Resource
## 共享地点；坐标由地图编辑器维护，此处只引用地标及偏移。
@export var id: String = ""
@export var display_name: String = ""
@export_group("地图位置")
@export var landmark: String = ""
@export var offset: Vector2 = Vector2.ZERO
## 一个探索站点可对应多个地图地标，例如会堂与商业街。
@export var map_landmarks: Array[String] = []
@export_group("已有背景")
@export_enum("south_gate", "pinxue_courtyard", "pinxue_atrium", "xuezi_cafeteria", "student_activity_center", "west_lake_center", "chengdian_auditorium_commercial_street", "yinhua_halal_cafeterias", "basic_laboratory_building", "west_lake_entrance", "sports_field", "library_front") var background_id: String = "south_gate"
@export var library_interior: bool = false
@export_group("地点内场景")
## 首项为默认场景。留空时沿用原背景；同一地点的所有访问共用配置。
@export var scenes: Array[CampusPlaceScene] = []
