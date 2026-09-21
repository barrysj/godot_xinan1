@tool
extends Resource
@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export_enum("generate", "convert") var effect := "generate"
@export var amount := 3
@export var starting_count := 1
