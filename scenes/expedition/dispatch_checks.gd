extends RefCounted
const Profile = preload("res://game/meta/campus_progress.gd")
var failures := 0
var checks := 0

func verify(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func run_checks(game: Control) -> void:
	var p = Profile.new()
	p.path = "res://.godot/dispatch-crew-test.json"
	p.points = 30
	p.upgrades = {"dispatch":1, "gym":1}
	var before: Dictionary = p.to_dict()
	verify(not p.start_dispatch([], "gym") and not p.start_dispatch(["archivist"], "gym"), "Exact crew size required")
	verify(not p.start_dispatch(["archivist", "archivist"], "gym"), "Duplicate members rejected")
	verify(not p.start_dispatch(["archivist", "technician"], "gym"), "Locked member rejected")
	verify(p.to_dict() == before, "Invalid dispatch never charges")
	p.path = "res://.godot/missing-dispatch-folder/profile.json"
	verify(not p.start_dispatch(["archivist", "liaison"], "gym") and p.to_dict() == before, "Whole crew rollback on save failure")
	p.path = "res://.godot/dispatch-crew-test.json"
	verify(p.start_dispatch(["archivist", "liaison"], "gym", 1000) and p.points == 26, "One fee per crew")
	verify(p.busy("archivist") and p.busy("liaison") and p.dispatches.size() == 1, "Whole crew occupies one job")
	var loaded = Profile.new()
	loaded.path = p.path
	verify(loaded.read_save() and loaded.busy("liaison"), "Crew survives reload")
	var job_id: String = loaded.dispatches[0].id
	verify(not loaded.claim_dispatch(job_id, 1119), "Cannot claim early")
	verify(loaded.claim_dispatch(job_id, 1120) and loaded.points == 33 and not loaded.busy("archivist") and not loaded.busy("liaison"), "Claim releases whole crew and awards once")
	verify(not loaded.claim_dispatch(job_id, 1121) and loaded.points == 33, "Duplicate claim rejected")
	# Old single-person gym jobs remain valid despite today's two-person requirement.
	var legacy: Dictionary = p.to_dict()
	legacy.version = 2
	legacy.dispatches[0].erase("staff_ids")
	legacy.dispatches[0].staff = "liaison"
	var file = FileAccess.open(p.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	verify(loaded.read_save() and loaded.dispatches[0].staff_ids == ["liaison"], "V2 single-member migration")
	verify(loaded.claim_dispatch(job_id, 1120), "Legacy job reward remains claimable")
	var corrupt: Dictionary = p.to_dict()
	corrupt.dispatches[0].staff_ids = ["archivist", "archivist"]
	file = FileAccess.open(p.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(corrupt))
	file.close()
	verify(not loaded.read_save() and loaded.load_blocked, "Duplicate crew in save rejected")
	game.progress = Profile.new()
	game.progress.path = "res://.godot/dispatch-ui-test.json"
	game.progress.points = 30
	game.progress.upgrades = {"dispatch":1, "gym":1}
	game.screen = "dispatch"
	await game.get_tree().process_frame
	for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
		game.get_window().mode = Window.MODE_WINDOWED
		game.get_window().size = resolution
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		game._open_location_details(1)
		var panel: Control = game.location_panel
		verify(panel.rows.get_child_count() == 3, "All staff visible including locked staff")
		verify(panel.counter.text.ends_with("0/2") and panel.dispatch_button.disabled, "Initial count and disabled dispatch")
		panel.rows.find_child("Select_archivist", true, false).pressed.emit()
		verify(panel.counter.text.ends_with("1/2") and panel.dispatch_button.disabled, "Partial selection")
		panel.rows.find_child("Select_liaison", true, false).pressed.emit()
		verify(panel.counter.text.ends_with("2/2") and not panel.dispatch_button.disabled, "Full selection enables dispatch")
		verify(panel.rows.find_child("Select_technician", true, false).disabled, "Locked selection disabled")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("res://.godot/dispatch-crew-%dx%d.png" % [resolution.x,resolution.y])
		panel._toggle("archivist")
		verify(panel.counter.text.ends_with("1/2"), "Deselect updates count")
		game._close_location_details()
	game._open_location_details(0)
	verify(game.location_panel.counter.text.ends_with("0/1"), "Switching location clears selection and changes requirement")
	game._open_location_details(1)
	game.location_panel._toggle("archivist")
	game.location_panel._toggle("liaison")
	game.location_panel.dispatch_button.pressed.emit()
	verify(game.progress.dispatches.size() == 1 and game.progress.points == 26, "UI submits whole crew")
	verify(game.location_panel.counter.text.ends_with("0/2") and game.location_panel.rows.find_child("Select_liaison", true, false).disabled, "Dispatched staff immediately unavailable")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("res://.godot/dispatch-crew-busy.png")
	game._close_location_details()
	print("DISPATCH CREW CHECK: checks=", checks, " failures=", failures)
	game.get_tree().quit(failures)
