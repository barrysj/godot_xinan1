@tool
class_name CampusEncounter
extends Resource
@export var id: String = ""
@export var display_name: String = ""
## units 与 slots 一一对应；允许同一个敌人资源多次出现。
@export var units: Array[CampusUnit] = []
@export var slots: Array[int] = []
## Shared code combat maintenance; each encounter may tune its own pulse.
@export_range(1, 60, 0.5) var maintenance_interval: float = 6.0
@export_range(1, 144, 1) var maintenance_shield: float = 35.0
