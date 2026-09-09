extends Control
## Read-only map navigation; the owner handles selection and dispatch transactions.
signal location_selected(index: int)
signal claim_requested(job_id: String)
const Catalog = preload("res://game/meta/meta_catalog.gd")
const Comic = preload("res://scenes/ui/comic_ui.gd")
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
const WORLD_SIZE = Vector2(1200, 680)
const BASE_POINT = Vector2(600, 550)
const TRAVEL_SECONDS = 1.6
var journeys: Array[Dictionary] = []
var progress: RefCounted
var selected := -1
var hovered := -1
var zoom := 1.0
var pan := Vector2.ZERO
var dragging := false
var moved := false
var press_position := Vector2.ZERO
var press_pan := Vector2.ZERO

func play_journey(job: Dictionary, returning: bool = false, target_override: Variant = null) -> void:
	# Only explicit successful transactions create journeys; loading a save does not.
	if journeys.any(func(item): return item.job.id == job.id and item.returning == returning): return
	journeys = journeys.filter(func(item): return item.job.id != job.id)
	var target := job_rect(job).position + Vector2(88, 24)
	if target_override is Vector2: target = target_override
	journeys.append({"job":job.duplicate(true), "returning":returning, "age":0.0, "target":target})
	queue_redraw()

func _process(delta: float) -> void:
	# Dispatch uses real time even while away from this map or in the pause menu.
	for journey in journeys: journey.age += delta
	journeys = journeys.filter(func(item): return item.age < TRAVEL_SECONDS)
	queue_redraw()

func _outbound(job_id: String) -> bool:
	return journeys.any(func(item): return item.job.id == job_id and not item.returning)

func job_rect(job: Dictionary) -> Rect2:
	var index := 0
	for i in Catalog.LOCATIONS.size():
		if Catalog.LOCATIONS[i].id == job.location: index = i; break
	var rank := 0
	if progress != null:
		for other in progress.dispatches:
			if other.id == job.id: break
			if other.location == job.location: rank += 1
	var at := point(index) + Vector2(120 if point(index).x < 600 else -340, -40 + rank * 100)
	return Rect2(at, Vector2(248, 90))

func claim_rect(job: Dictionary) -> Rect2:
	return Rect2(job_rect(job).position + Vector2(178, 48), Vector2(66, 36))

func job_fraction(job: Dictionary, now: float = -1) -> float:
	if now < 0: now = Time.get_unix_time_from_system()
	if now >= float(job.ready_at): return 1.0
	return clampf((now - float(job.started_at)) / maxf(1.0, float(job.ready_at) - float(job.started_at)), 0, 1)

func claim_at(local: Vector2) -> String:
	if progress == null or _fit() <= 0 or not Rect2(Vector2.ZERO, size).has_point(local): return ""
	var world := (local - _offset()) / (_fit() * zoom)
	for job in progress.dispatches:
		if not _outbound(job.id) and Time.get_unix_time_from_system() >= float(job.ready_at) and claim_rect(job).has_point(world): return job.id
	return ""

func journey_position(journey: Dictionary) -> Vector2:
	var t: float = clampf(journey.age / TRAVEL_SECONDS, 0, 1)
	t = t * t * (3 - 2 * t)
	if journey.returning: t = 1 - t
	var elbow := Vector2(BASE_POINT.x, journey.target.y)
	var first := BASE_POINT.distance_to(elbow)
	var second: float = elbow.distance_to(journey.target)
	var distance: float = (first + second) * t
	if distance <= first and first > 0: return BASE_POINT.lerp(elbow, distance / first)
	return elbow.lerp(journey.target, clampf((distance - first) / maxf(1, second), 0, 1))

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(func(): hovered = -1; queue_redraw())
	visibility_changed.connect(func():
		dragging = false
		hovered = -1
		queue_redraw())
	resized.connect(func(): _clamp_pan(); queue_redraw())

func _fit() -> float:
	return minf(size.x / WORLD_SIZE.x, size.y / WORLD_SIZE.y)

func _offset() -> Vector2:
	return (size - WORLD_SIZE * _fit() * zoom) / 2 + pan

func point(index: int) -> Vector2:
	return Catalog.LOCATIONS[index].get("map_position", Vector2(250 + (index % 3) * 320, 200 + int(index / 3) * 220))

func location_at(local: Vector2) -> int:
	if not Rect2(Vector2.ZERO, size).has_point(local) or _fit() <= 0: return -1
	var world := (local - _offset()) / (_fit() * zoom)
	for i in range(Catalog.LOCATIONS.size() - 1, -1, -1):
		if Rect2(point(i) - Vector2(94, 62), Vector2(188, 150)).has_point(world): return i
	return -1

func _clamp_pan() -> void:
	var limit := (WORLD_SIZE * _fit() * zoom - size).max(Vector2.ZERO) / 2
	pan = pan.clamp(-limit, limit)

func zoom_at(local: Vector2, factor: float) -> void:
	if _fit() <= 0: return
	var world := (local - _offset()) / (_fit() * zoom)
	zoom = clampf(zoom * factor, 1.0, 2.5)
	pan = local - (size - WORLD_SIZE * _fit() * zoom) / 2 - world * _fit() * zoom
	_clamp_pan()
	hovered = location_at(local)
	queue_redraw()

func reset_view() -> void:
	zoom = 1
	pan = Vector2.ZERO
	hovered = -1
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position, 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				grab_focus()
				dragging = true
				moved = false
				press_position = event.position
				press_pan = pan
			else:
				var clicked := dragging and not moved
				dragging = false
				var index := location_at(event.position)
				var reward_id := claim_at(event.position)
				if clicked and not reward_id.is_empty():
					claim_requested.emit(reward_id)
				elif clicked and index >= 0:
					selected = index
					location_selected.emit(index)
	elif event is InputEventMouseMotion:
		if dragging:
			moved = moved or event.position.distance_to(press_position) > 6
			if moved:
				pan = press_pan + event.position - press_position
				_clamp_pan()
		hovered = -1 if dragging and moved else location_at(event.position)
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_LEFT, KEY_RIGHT]:
			selected = posmod(selected + (1 if event.keycode == KEY_RIGHT else -1), Catalog.LOCATIONS.size())
			hovered = selected
			pan = (WORLD_SIZE / 2 - point(selected)) * _fit() * zoom
			_clamp_pan()
		elif event.keycode in [KEY_ENTER, KEY_SPACE] and selected >= 0:
			var reward_id := ""
			for job in progress.dispatches:
				if job.location == Catalog.LOCATIONS[selected].id and not _outbound(job.id) and Time.get_unix_time_from_system() >= float(job.ready_at):
					reward_id = job.id
					break
			if not reward_id.is_empty(): claim_requested.emit(reward_id)
			else: location_selected.emit(selected)
	queue_redraw()
	accept_event()

func _label(at: Vector2, text: String, color: Color, font_size: int = 20) -> void:
	draw_string(FONT, at - Vector2(FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_crew(members: Array, at: Vector2) -> void:
	for i in members.size():
		var staff := Catalog.find(Catalog.STAFF, members[i])
		var p := at + Vector2((i - (members.size() - 1) / 2.0) * 50, 0)
		Comic.card(self, Rect2(p - Vector2(22, 22), Vector2(44, 44)), Color("71b8dc"), Comic.INK)
		_label(p + Vector2(0, 6), str(staff.get("name", "同学")).right(2), Comic.INK, 16)

func _draw_dispatches() -> void:
	Comic.card(self, Rect2(BASE_POINT - Vector2(65, 36), Vector2(130, 66)), Comic.WHITE, Comic.INK)
	_label(BASE_POINT + Vector2(0, 7), "据点", Comic.INK, 24)
	if progress == null: return
	var idle: Array = []
	for staff in progress.available_staff():
		if not progress.busy(staff.id) and not journeys.any(func(item): return item.returning and item.job.staff_ids.has(staff.id)):
			idle.append(staff.id)
	_draw_crew(idle, BASE_POINT + Vector2(0, 66))
	for job in progress.dispatches:
		if _outbound(job.id): continue
		var rect := job_rect(job)
		var fraction := job_fraction(job)
		Comic.card(self, rect, Comic.WHITE, Color("36b96e") if fraction >= 1 else Comic.INK)
		_draw_crew(job.staff_ids, rect.position + Vector2(88, 24))
		var bar := Rect2(rect.position + Vector2(10, 51), Vector2(154, 12))
		draw_rect(bar, Color("777777"))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), Color("36b96e"))
		var remaining := maxi(0, int(ceil(float(job.ready_at) - Time.get_unix_time_from_system())))
		_label(rect.position + Vector2(87, 82), "已完成" if fraction >= 1 else "%d%% · %d 秒" % [int(fraction * 100), remaining], Comic.INK, 15)
		if fraction >= 1:
			var claim := claim_rect(job)
			Comic.card(self, claim, Color("36b96e"), Comic.INK)
			_label(claim.get_center() + Vector2(0, 6), "领取", Comic.INK, 18)
	for journey in journeys:
		var members: Array = journey.job.staff_ids
		if journey.returning: members = members.filter(func(id): return not progress.busy(id))
		_draw_crew(members, journey_position(journey))

func _draw() -> void:
	# Reuse the existing dispatch map's placeholder buildings and courtyard palette.
	draw_rect(Rect2(Vector2.ZERO, size), Color("718951"))
	draw_set_transform(_offset(), 0, Vector2.ONE * _fit() * zoom)
	draw_rect(Rect2(Vector2(65, 65), WORLD_SIZE - Vector2(130, 130)), Color("6f7360"))
	for y in range(70, 610, 30):
		for x in range(70, 1130, 36):
			draw_rect(Rect2(x, y, 34, 28), Color("b8b497"))
	draw_line(Vector2(600, 85), Vector2(600, 595), Color("d8c79d"), 18)
	for i in range(Catalog.LOCATIONS.size()):
		var location: Dictionary = Catalog.LOCATIONS[i]
		var p := point(i)
		var unlocked: bool = progress != null and progress.level(location.requires) > 0
		draw_line(Vector2(600, p.y), p, Color("d8c79d"), 16)
		Comic.card(self, Rect2(p - Vector2(80, 48), Vector2(160, 96)), Comic.WHITE if unlocked else Color("969d8c"), Comic.INK)
		draw_rect(Rect2(p - Vector2(88, 56), Vector2(176, 17)), Color("a86c57"))
		for x in [-48, 0, 48]:
			draw_rect(Rect2(p + Vector2(x - 12, -19), Vector2(24, 30)), Color("709caa"))
		if i == hovered or i == selected:
			draw_rect(Rect2(p - Vector2(94, 62), Vector2(188, 126)), Color("f7cc78"), false, 4)
		var status := "可派遣" if unlocked else "尚未解锁"
		if progress != null:
			for job in progress.dispatches:
				if job.location == location.id:
					if int(job.ready_at) <= int(Time.get_unix_time_from_system()): status = "成果可领取"
					elif status != "成果可领取": status = "探索中"
		if status == "成果可领取":
			draw_rect(Rect2(p - Vector2(94, 62), Vector2(188, 126)), Color("36b96e"), false, 4)
		_label(p + Vector2(0, 88), status, Comic.INK, 18)
	_draw_dispatches()
	draw_set_transform(Vector2.ZERO)
	if hovered >= 0:
		var name: String = Catalog.LOCATIONS[hovered].name
		var extent := FONT.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20) + Vector2(32, 18)
		var at := _offset() + (point(hovered) + Vector2(0, -78)) * _fit() * zoom - Vector2(extent.x / 2, extent.y)
		at = at.clamp(Vector2(8, 8), (size - extent - Vector2(8, 8)).max(Vector2(8, 8)))
		Comic.card(self, Rect2(at, extent), Comic.INK)
		_label(at + Vector2(extent.x / 2, 28), name, Comic.WHITE)
