extends RefCounted
const Profile = preload("res://game/meta/campus_progress.gd")
var failures := 0
var checks := 0

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func capture(game: Control, name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("res://.godot/journey-" + name + ".png")

func click(map: Control, local: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = local
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		map._gui_input(event)

func run_checks(game: Control) -> void:
	game.progress = Profile.new()
	game.progress.path = "res://.godot/journey-test.json"
	game.progress.points = 30
	game.progress.upgrades = {"dispatch":1, "gym":1, "staffing":1}
	game.screen = "dispatch"
	var map: Control = game.campus_map
	map.set_process(false)
	await game.get_tree().process_frame
	game._open_location_details(1)
	verify(game.location_panel.rows.get_child_count() == 3, "Unlocked member appears in list")
	game.location_panel._toggle("archivist")
	game.location_panel._toggle("liaison")
	game.location_panel._dispatch()
	verify(not is_instance_valid(game.location_panel) and map.journeys.size() == 1, "Dispatch shows departure on map")
	verify(map.journeys[0].job.staff_ids.size() == 2, "Both portraits travel together")
	verify(map.journey_position(map.journeys[0]).is_equal_approx(map.BASE_POINT), "Departure starts at base")
	map._process(0.65)
	for resolution in [Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(1920,1200)]:
		game.get_window().mode = Window.MODE_WINDOWED
		game.get_window().size = resolution
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		await capture(game, "depart-%dx%d" % [resolution.x, resolution.y])
	map._process(2)
	verify(map.journeys.is_empty(), "Arrival finishes transient journey")
	var job: Dictionary = game.progress.dispatches[0]
	var now: int = int(Time.get_unix_time_from_system())
	job.started_at = now - 60
	job.ready_at = now + 60
	verify(is_equal_approx(map.job_fraction(job, now), 0.5), "Progress follows persisted timestamps")
	await capture(game, "progress")
	game.progress.write_save()
	var loaded = Profile.new()
	loaded.path = game.progress.path
	verify(loaded.read_save() and loaded.busy("archivist") and loaded.busy("liaison"), "Offline task retains both members")
	var restored_map = load("res://scenes/expedition/campus_map.gd").new()
	restored_map.progress = loaded
	verify(restored_map.journeys.is_empty(), "Loading never replays departure")
	restored_map.free()
	var claim_center: Vector2 = map._offset() + map.claim_rect(job).get_center() * map._fit() * map.zoom
	verify(map.claim_at(claim_center).is_empty(), "No early claim button")
	job.ready_at = now - 1
	verify(map.job_fraction(job) == 1, "Finished progress is full")
	await capture(game, "ready")
	map.zoom_at(claim_center, 1.5)
	claim_center = map._offset() + map.claim_rect(job).get_center() * map._fit() * map.zoom
	verify(map.claim_at(claim_center) == job.id, "Claim hit test follows zoom")
	var saved_path: String = game.progress.path
	game.progress.path = "res://.godot/missing-journey-folder/save.json"
	click(map, claim_center)
	verify(map.journeys.is_empty() and game.progress.points == 26 and game.progress.dispatches.size() == 1, "Save failure cannot start return or grant reward")
	game.progress.path = saved_path
	map.reset_view()
	claim_center = map._offset() + map.claim_rect(job).get_center() * map._fit() * map.zoom
	click(map, claim_center)
	verify(game.progress.points == 33 and game.progress.dispatches.is_empty(), "Map claim grants reward once")
	verify(map.journeys.size() == 1 and map.journeys[0].returning and map.journeys[0].job.staff_ids.size() == 2, "Both portraits return after successful claim")
	map._process(0.8)
	await capture(game, "return")
	game._claim_map_job(job.id)
	verify(game.progress.points == 33 and map.journeys.size() == 1, "Duplicate claim adds no reward or journey")
	map._process(2)
	verify(map.journeys.is_empty() and not game.progress.busy("archivist") and not game.progress.busy("liaison"), "Returned crew is idle at base")
	await capture(game, "base")
	game.progress.start_dispatch("archivist", "library")
	game.progress.start_dispatch("liaison", "library")
	verify(not map.job_rect(game.progress.dispatches[0]).intersects(map.job_rect(game.progress.dispatches[1])), "Two jobs at same destination have separate progress and claim areas")
	print("JOURNEY CHECK: checks=", checks, " failures=", failures)
	game.get_tree().quit(failures)
