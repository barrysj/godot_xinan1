@tool
extends Resource
@export var types: Dictionary = {}
@export var programs: Array[Resource] = []
@export var items: Array[Resource] = []
@export var cache_cap := 6
@export var attacks_per_block := 3
@export var shared_cooldown := 3.0
@export var default_loadout: Array[String] = ["disconnect", "takeover"]
