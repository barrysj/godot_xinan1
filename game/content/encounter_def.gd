@tool
class_name CampusEncounter
extends Resource
@export var id: String = ""
@export var display_name: String = ""
## units 与 slots 一一对应；允许同一个敌人资源多次出现。
@export var units: Array[CampusUnit] = []
@export var slots: Array[int] = []
