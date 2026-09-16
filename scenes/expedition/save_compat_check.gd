extends Node
const Progress = preload("res://game/meta/campus_progress.gd")
func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var profile = Progress.new()
	var ok = profile.read_save()
	print("SAVE_REPRO path=",ProjectSettings.globalize_path(profile.path)," loaded=",ok," blocked=",profile.load_blocked," message=",profile.error_message)
	assert(ok and not profile.load_blocked)
	var fixture = Progress.new()
	fixture.path = "res://.godot/save-compat-fixture.json"
	for version in [1,2,3,4]:
		var text = JSON.stringify({"version":version,"points":35,"upgrades":{},"active_run":{},"dispatches":[]})
		var output = FileAccess.open(fixture.path,FileAccess.WRITE)
		output.store_string(text)
		output.close()
		assert(fixture.read_save() == (version <= 3))
		if version == 4:
			assert(not fixture.write_save())
			assert(FileAccess.get_file_as_string(fixture.path) == text)
	var game = load("res://scenes/expedition/expedition.tscn").instantiate()
	add_child(game)
	game.progress = fixture
	game._request_exit("quit")
	game._confirm_exit()
	assert(not game.leaving and game.discard_exit_button.visible)
	game._open_pause()
	assert(not game.discard_exit_button.visible)
	game._request_exit("quit")
	game._confirm_exit()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/save-compat-exit.png")
	var before = FileAccess.get_file_as_string(fixture.path)
	tree_exiting.connect(func():
		assert(FileAccess.get_file_as_string(fixture.path) == before)
		print("SAVE_COMPAT_CHECK PASS legacy versions, future protection, cancel and explicit unsaved quit"))
	game.discard_exit_button.pressed.emit()
