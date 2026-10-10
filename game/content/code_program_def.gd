@tool
extends Resource
@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var cost: Dictionary = {}
@export_enum("pursuit", "recoil", "repair") var effect := "pursuit"
@export var cooldown := 10.0
@export var duration := 5.0
@export var damage := 45.0
@export var shield := 30.0
@export var radius := 2.0
@export var heal_amount := 60.0
@export var any_cost := 0
@export var per_battle_limit := 0
# Compatibility for old editor resources only.
@export var heal_ratio := 0.25
