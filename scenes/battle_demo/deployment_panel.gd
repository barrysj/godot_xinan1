extends Control
## One gesture state for click-to-confirm and drag-to-deploy. Only commit mutates formation.
const Comic = preload("res://scenes/ui/comic_ui.gd")
const DRAG_THRESHOLD = 8.0
const LIMIT = 4
enum Mode { NONE, DEPLOY, ACTIONS, SWAP }
var mode = Mode.NONE
var locked_preview = false
var toggle_on_release = false
var swap_button: Button
var swap_ghost: TextureRect
var return_hint: Label
var pointer_at = Vector2.ZERO
var game: Control
var canvas: Control
var hand: HBoxContainer
var cards: Dictionary = {}
var ghost: TextureRect
var accept_button: Button
var cancel_button: Button
var withdraw_button: Button
var selected_role = -1
var candidate_slot = -1
var pressed_role = -1
var press_at = Vector2.ZERO
var dragging = false
var hover_role = -1
var roster_snapshot: Array = []
var motion_seconds = 0.12

class Card extends Control:
	var panel: Control
	var role: int
	var lift = 0.0
	func _process(delta: float) -> void:
		var goal = 1.0 if panel.selected_role == role else (0.55 if panel.hover_role == role else 0.0)
		lift = move_toward(lift, goal, delta / panel.motion_seconds)
		queue_redraw()
	func face_rect() -> Rect2:
		return Rect2(Vector2(-3, -16) * lift, size + Vector2(6, 4) * lift)
	func _draw() -> void:
		var rect = face_rect()
		var deployed: bool = panel.game.formation.has(role)
		Comic.card(self, rect, panel.game.PAPER, panel.game.GOLD if panel.selected_role == role else panel.game.DARK)
		var definition = panel.game.Content.character(role)
		var portrait_at = rect.position + Vector2(rect.size.x / 2 - 20, 5)
		draw_texture_rect(definition.portrait, Rect2(portrait_at, Vector2(40, 40)), false, Color(1, 1, 1, 0.55 if deployed else 1.0))
		var font: Font = panel.game.font
		var title: String = definition.display_name
		draw_string(font, rect.position + Vector2((rect.size.x - font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x) / 2, 61), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, panel.game.DARK)
		var label = "已部署" if deployed else "待部署"
		draw_string(font, rect.position + Vector2((rect.size.x - font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x) / 2, 78), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, panel.game.DARK)

class MarkButton extends Button:
	var confirm = false
	func _draw() -> void:
		var ink = Color("2f9b62") if confirm else Color("d74d55")
		if confirm:
			draw_polyline(PackedVector2Array([Vector2(9, 17), Vector2(14, 23), Vector2(25, 10)]), ink, 3.0, true)
		else:
			draw_line(Vector2(10, 10), Vector2(24, 24), ink, 3.0, true)
			draw_line(Vector2(24, 10), Vector2(10, 24), ink, 3.0, true)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = preload("res://resources/theme/theme-main.tres")
	var tokens = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/animation.json"))
	motion_seconds = float(tokens.durations_ms.micro) / 1000.0
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.size = Vector2(1280, 720)
	add_child(canvas)
	hand = HBoxContainer.new()
	hand.position = Vector2(30, 621)
	hand.size = Vector2(874, 84)
	hand.alignment = BoxContainer.ALIGNMENT_CENTER
	hand.add_theme_constant_override("separation", 14)
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hand)
	ghost = TextureRect.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.modulate.a = 0.35
	canvas.add_child(ghost)
	swap_ghost = TextureRect.new()
	swap_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swap_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	swap_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	swap_ghost.modulate.a = 0.35
	canvas.add_child(swap_ghost)
	accept_button = _mark(true)
	cancel_button = _mark(false)
	accept_button.pressed.connect(commit)
	cancel_button.pressed.connect(cancel)
	withdraw_button = Button.new()
	withdraw_button.text = "撤回"
	withdraw_button.add_theme_font_override("font", game.font)
	withdraw_button.add_theme_font_size_override("font_size", 16)
	withdraw_button.size = Vector2(64, 30)
	withdraw_button.position = Vector2(832, 577)
	withdraw_button.pressed.connect(withdraw)
	canvas.add_child(withdraw_button)
	swap_button = Button.new()
	swap_button.text = "交换"
	swap_button.add_theme_font_override("font", game.font)
	swap_button.add_theme_font_size_override("font_size", 16)
	swap_button.size = Vector2(64, 30)
	swap_button.pressed.connect(begin_swap)
	canvas.add_child(swap_button)
	return_hint = Label.new()
	return_hint.text = "松手撤回"
	return_hint.add_theme_font_override("font", game.font)
	return_hint.add_theme_color_override("font_color", game.GOLD)
	return_hint.position = Vector2(40, 589)
	return_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(return_hint)
	refresh()

func _mark(confirm: bool) -> Button:
	var button = MarkButton.new()
	button.confirm = confirm
	button.size = Vector2(34, 34)
	button.tooltip_text = "确认部署" if confirm else "取消部署"
	var style = StyleBoxFlat.new()
	style.bg_color = game.PAPER
	style.set_corner_radius_all(5)
	style.set_border_width_all(1)
	style.border_color = game.DARK
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	canvas.add_child(button)
	return button

func active() -> bool:
	return game.phase == "prepare" and not game.paused and not game.leaving and (game.get("screen") == null or game.get("screen") == "battle")

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if canvas == null: return
	visible = active()
	if not visible:
		cancel()
		return
	var factor = minf(size.x / 1280.0, size.y / 720.0)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - Vector2(1280, 720) * factor) / 2
	var roster: Array = game._deployment_roster()
	if roster != roster_snapshot:
		roster_snapshot = roster.duplicate()
		for child in hand.get_children():
			hand.remove_child(child)
			child.queue_free()
		cards.clear()
		for role in roster:
			var card = Card.new()
			card.panel = self
			card.role = role
			card.custom_minimum_size = Vector2(minf(126, (874.0 - 14 * (roster.size() - 1)) / roster.size()), 84)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hand.add_child(card)
			cards[role] = card
	ghost.visible = mode in [Mode.DEPLOY, Mode.SWAP] and can_place(candidate_slot)
	accept_button.visible = ghost.visible and locked_preview and not dragging
	cancel_button.visible = accept_button.visible
	withdraw_button.visible = mode == Mode.ACTIONS and not dragging
	swap_button.visible = withdraw_button.visible
	return_hint.visible = dragging and game.formation.has(selected_role)
	return_hint.text = "松手撤回" if Rect2(hand.position, hand.size).has_point(pointer_at) else "拖回卡牌区撤回"
	swap_ghost.hide()
	if withdraw_button.visible:
		var unit: Dictionary = game._inspection_unit(selected_role)
		var feet: Vector2 = game._unit_center(unit) + Vector2(0, 13)
		swap_button.position = feet + Vector2(-68, -94)
		withdraw_button.position = feet + Vector2(4, -94)
	if ghost.visible:
		accept_button.tooltip_text = "确认交换" if mode == Mode.SWAP else "确认部署"
		_place_ghost(ghost, selected_role, candidate_slot)
		accept_button.position = Vector2(ghost.position.x + ghost.size.x / 2 - 38, ghost.position.y - 41)
		cancel_button.position = accept_button.position + Vector2(42, 0)
		var other: int = game.formation[candidate_slot]
		if mode == Mode.SWAP and other >= 0 and other != selected_role:
			_place_ghost(swap_ghost, other, game.formation.find(selected_role))
			swap_ghost.show()

func _place_ghost(image: TextureRect, role: int, slot: int) -> void:
	var unit: Dictionary = game._inspection_unit(role)
	var animated: Texture2D = unit.animation.texture()
	image.texture = animated if animated != null else unit.portrait
	image.size = unit.battle_animation.display_size if animated != null else Vector2(64, 64)
	var anchor: Vector2 = unit.battle_animation.anchor if animated != null else Vector2(0.5, 0.875)
	var preview_unit = unit.duplicate()
	preview_unit.slot = slot
	game.AutoBattle.initialize(preview_unit)
	image.position = game._unit_center(preview_unit) + Vector2(0, 13) - image.size * anchor

func previews_unit(role: int) -> bool:
	return active() and mode == Mode.SWAP and ghost.visible and can_place(candidate_slot) and (role == selected_role or role == game.formation[candidate_slot])

func can_place(slot: int) -> bool:
	if selected_role < 0 or slot < 0 or slot >= 6: return false
	if not game._deployment_roster().has(selected_role): return false
	if mode == Mode.ACTIONS: return false
	if mode == Mode.SWAP:
		return game.formation.has(selected_role) and game.formation[slot] != selected_role
	if game.formation[slot] >= 0: return false
	return game.formation.has(selected_role) or 6 - game.formation.count(-1) < LIMIT

func slot_at(point: Vector2) -> int:
	for slot in range(6):
		if game._slot_rect(0, slot).has_point(point): return slot
	return -1

func card_at(point: Vector2) -> int:
	# Base rect remains interactive while the visual rises, preventing hover flicker.
	for role in cards:
		var card: Control = cards[role]
		var rect = Rect2(hand.position + card.position, card.size).merge(Rect2(hand.position + card.position + card.face_rect().position, card.face_rect().size))
		if rect.has_point(point): return role
	return -1

func unit_slot_at(point: Vector2) -> int:
	for unit in game.units:
		if unit.side == 0 and Rect2(game._unit_center(unit) + Vector2(-32, -43), Vector2(64, 64)).has_point(point):
			return unit.slot
	return -1

func select(role: int) -> void:
	selected_role = role
	mode = Mode.ACTIONS if game.formation.has(role) else Mode.DEPLOY
	locked_preview = false
	candidate_slot = -1
	game.selected = role
	game.inspected_enemy_slot = -1
	game._note("点击空格预览部署，或拖动卡片到空格。")
	refresh()

func begin_swap() -> void:
	if not active() or not game.formation.has(selected_role): return
	mode = Mode.SWAP
	locked_preview = false
	candidate_slot = -1
	refresh()

func cancel() -> void:
	selected_role = -1
	candidate_slot = -1
	pressed_role = -1
	dragging = false
	hover_role = -1
	mode = Mode.NONE
	locked_preview = false
	toggle_on_release = false
	if ghost != null:
		ghost.hide()
		accept_button.hide()
		cancel_button.hide()
		withdraw_button.hide()
		swap_button.hide()
		swap_ghost.hide()
		return_hint.hide()

func commit() -> void:
	if not active() or not can_place(candidate_slot): return
	var old: int = game.formation.find(selected_role)
	if old >= 0: game.formation[old] = game.formation[candidate_slot]
	game.formation[candidate_slot] = selected_role
	game._deployment_changed()
	cancel()
	game._note("已部署 %d / 4 位同学。" % (6 - game.formation.count(-1)))
	refresh()

func withdraw() -> void:
	if not active(): return
	var old: int = game.formation.find(selected_role)
	if selected_role < 0 or old < 0: return
	game.formation[old] = -1
	game._deployment_changed()
	cancel()
	game._note("已撤回，可重新选择同学部署。")
	refresh()

func handle(event: InputEvent) -> bool:
	if not active(): return false
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and selected_role >= 0:
		cancel()
		return true
	if not (event is InputEventMouseButton or event is InputEventMouseMotion): return false
	var point: Vector2 = canvas.get_global_transform().affine_inverse() * event.position
	pointer_at = point
	if event is InputEventMouseMotion:
		hover_role = card_at(point)
		if pressed_role >= 0:
			if point.distance_to(press_at) >= DRAG_THRESHOLD:
				if not dragging and selected_role != pressed_role: select(pressed_role)
				dragging = true
				toggle_on_release = false
				locked_preview = false
				mode = Mode.SWAP if game.formation.has(selected_role) else Mode.DEPLOY
			if dragging:
				candidate_slot = slot_at(point)
				refresh()
			return true
		if mode in [Mode.DEPLOY, Mode.SWAP] and not locked_preview:
			candidate_slot = slot_at(point)
			refresh()
		return false
	if event.button_index != MOUSE_BUTTON_LEFT: return false
	if not event.pressed:
		if pressed_role < 0: return false
		if dragging:
			candidate_slot = slot_at(point)
			if game.formation.has(selected_role) and Rect2(hand.position, hand.size).has_point(point): withdraw()
			elif can_place(candidate_slot): commit()
			else:
				cancel()
				game._note("未部署：请拖到空闲的我方格子。")
		elif toggle_on_release:
			cancel()
		pressed_role = -1
		dragging = false
		toggle_on_release = false
		refresh()
		return true
	if accept_button.visible and Rect2(accept_button.position, accept_button.size).has_point(point): return false
	if cancel_button.visible and Rect2(cancel_button.position, cancel_button.size).has_point(point): return false
	if withdraw_button.visible and Rect2(withdraw_button.position, withdraw_button.size).has_point(point): return false
	if swap_button.visible and Rect2(swap_button.position, swap_button.size).has_point(point): return false
	var role = card_at(point)
	if role >= 0:
		var toggle = selected_role == role
		select(role)
		toggle_on_release = toggle
		pressed_role = role
		press_at = point
		return true
	var slot = unit_slot_at(point)
	if slot < 0: slot = slot_at(point)
	if slot >= 0:
		if mode in [Mode.NONE, Mode.ACTIONS] and game.formation[slot] >= 0:
			select(game.formation[slot])
			pressed_role = selected_role
			press_at = point
		elif can_place(slot):
			candidate_slot = slot
			locked_preview = true
			refresh()
		elif selected_role >= 0:
			game._note("格子已占用或已达到四人上限；可先撤回同学。")
		if game.formation[slot] >= 0:
			pressed_role = game.formation[slot]
			press_at = point
		return true
	return false

func _input(event: InputEvent) -> void:
	if handle(event): get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel()
