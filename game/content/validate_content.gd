extends SceneTree
## 无窗口校验入口：godot --headless --path . --script res://game/content/validate_content.gd
func _initialize() -> void:
	var host = Node.new()
	host.name = "ContentValidation"
	root.add_child(host)
	current_scene = host
	var db = load("res://game/content/content_db.gd")
	var errors = db.validate()
	for message in errors: printerr(message)
	print("CONTENT_VALIDATION errors=",errors.size()," characters=",db.MANIFEST.characters.size()," equipment=",db.MANIFEST.equipment.size()," locations=",db.MANIFEST.locations.size())
	quit(0 if errors.is_empty() else 1)
