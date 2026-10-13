extends Node
## Loads the actual startup chain with a disposable profile, including lazy map UI.
const Campaign = preload("res://scenes/expedition/expedition.tscn")
const Catalog = preload("res://game/run/campus_flow_catalog.gd")
var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROJECT_HEALTH: " + message)

func _ready() -> void:
	for region in ["library", "region_b", "region_c"]:
		expect(not Catalog.snapshot(region).is_empty(), "region resource " + region)
	for icon in ["scene", "passage"]:
		expect(load("res://assets/art/ui/place_scenes/%s.svg" % icon) is Texture2D, "imported icon " + icon)
	expect(load("res://scenes/menu/menu.tscn") is PackedScene, "main menu dependencies")
	var game = Campaign.instantiate()
	var profile := "res://.godot/project-health/profile-%d.json" % Time.get_ticks_usec()
	game.progress.path = profile
	add_child(game)
	for i in range(3): await get_tree().process_frame
	game.set_process(false)
	expect(game.campaign_panel != null, "real campaign startup")
	game.progress.campaign.routes_acquired = true
	game._open_map_region()
	for i in range(3): await get_tree().process_frame
	var preview = game.get_node_or_null("CampaignMapRegionPreview")
	expect(preview != null, "map dependencies")
	if preview != null:
		preview._choose_route(0)
		expect(preview.route_nodes != null and not preview.route_nodes.buttons.is_empty(), "route node construction")
	game.queue_free()
	await get_tree().process_frame
	if FileAccess.file_exists(profile): DirAccess.remove_absolute(ProjectSettings.globalize_path(profile))
	print("PROJECT_HEALTH_CHECK checks=%d failures=%d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
