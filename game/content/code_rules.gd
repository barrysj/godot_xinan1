@tool
extends Resource
@export var types: Dictionary = {}
@export var programs: Array[Resource] = []
@export var items: Array[Resource] = []
@export var cache_cap := 6
@export var attacks_per_block := 3
@export var shared_cooldown := 3.0
@export var default_loadout: Array[String] = ["disconnect", "redirect"]
@export var shield_per_block := 80.0
@export var validation_cooldown := 4.0
@export var confirmation_duration := 8.0
@export var vulnerability_duration := 6.0
@export var validation_scale := 0.8
@export var exposure_scale := 1.0
@export var opening_shield := 20.0
@export var absorption_heal := 8.0
@export var item_cooldown := 3.0
