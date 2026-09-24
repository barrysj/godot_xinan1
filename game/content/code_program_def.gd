@tool
extends Resource
@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var cost: Dictionary = {}
@export_enum("disconnect", "redirect", "repair", "takeover") var effect := "disconnect"
@export var heal_ratio := 0.25
