extends CanvasLayer
## Debug gestures edit the ordinary battlefield; drafts never mutate shared data.
const Model = preload("res://game/debug/battle_tuning.gd")
const Ui = preload("res://scenes/ui/campus_ui.gd")
const Fields = preload("res://scenes/expedition/battle_tuning_panel.gd")
const DRAG_THRESHOLD := 8.0
var hub
var canvas: Control
var shade: ColorRect
var panel: PanelContainer
var column: VBoxContainer
var ghost: TextureRect
var marks: Control
var portrait: TextureRect
var heading: Label
var selector: OptionButton
var stat_fields: Dictionary = {}
var message: Label
var apply_button: Button
var close_button: Button
var draft: Dictionary = {}
var row: Dictionary = {}
var anchor := ""
var edit_side := -1
var edit_slot := -1
var was_paused := false
var pressed_side := -1
var pressed_slot := -1
var press_at := Vector2.ZERO
var pointer := Vector2.ZERO
var dragging := false
var candidate_slot := -1
var press_was_paused := false
var menu_at := Vector2.ZERO

class DragMarks extends Control:
	var editor
	func _draw() -> void:
		if not editor.dragging: return
		for slot in 6:
			var rect: Rect2 = editor.hub._slot_rect(editor.pressed_side,slot)
			var chosen: bool = slot == editor.candidate_slot
			var color := Color(editor.hub.GOLD if chosen else editor.hub.PAPER)
			draw_rect(rect,Color(color,0.24 if chosen else 0.08))
			draw_rect(rect,color,false,3 if chosen else 1)
		if editor.candidate_slot >= 0:
			var end: Vector2 = editor.hub._slot_rect(editor.pressed_side,editor.candidate_slot).get_center()
			draw_dashed_line(editor.press_at,end,editor.hub.GOLD,2,7)

func _ready() -> void:
	layer = 18
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.theme = hub.theme
	canvas.size = Vector2(1280,720)
	add_child(canvas)
	marks = DragMarks.new()
	marks.editor = self
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(marks)
	ghost = TextureRect.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.modulate.a = 0.7
	canvas.add_child(ghost)
	ghost.hide()
	shade = ColorRect.new()
	shade.size = canvas.size
	shade.color = Color(0.04,0.08,0.12,0.16)
	shade.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			shade.accept_event()
			close())
	canvas.add_child(shade)
	shade.hide()
	panel = PanelContainer.new()
	panel.custom_minimum_size.x = 350
	panel.add_theme_stylebox_override("panel",Ui.panel_style("daily","strong"))
	canvas.add_child(panel)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	panel.hide()

func busy() -> bool:
	return pressed_side >= 0 or (is_instance_valid(panel) and panel.visible)

func active() -> bool:
	return hub.debug_enabled and hub.screen == "battle" and hub.phase in ["prepare","battle"] and not hub.leaving and hub.pending_exit.is_empty() and not hub.pause_overlay.visible and not hub.debug_panel.panel.visible and not is_instance_valid(hub.team_panel) and not is_instance_valid(hub.codex_panel)

func _process(_delta: float) -> void:
	var available: Vector2 = hub.get_viewport_rect().size
	var factor := minf(available.x/1280,available.y/720)
	canvas.scale = Vector2.ONE*factor
	canvas.position = (available-canvas.size*factor)/2
	if not active() and busy(): close()
	if panel.visible:
		panel.size = panel.get_combined_minimum_size()
		panel.position = Vector2(clampf(menu_at.x,24,1256-panel.size.x),clampf(menu_at.y,92,maxf(92,704-panel.size.y)))
	marks.queue_redraw()

func slot_at(point: Vector2, side: int) -> int:
	for slot in 6:
		if hub._slot_rect(side,slot).has_point(point): return slot
	return -1

func unit_at(side: int, slot: int) -> Dictionary:
	for unit in hub.units:
		if unit.side == side and unit.slot == slot: return unit
	return {}

func handle_input(event: InputEvent) -> bool:
	if panel.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE,KEY_F8,KEY_P]:
				close()
				return event.keycode != KEY_F8
		return false
	if event is InputEventKey and event.pressed and pressed_side >= 0 and event.keycode == KEY_ESCAPE:
		cancel_drag()
		return true
	if not active(): return false
	if not (event is InputEventMouseMotion or event is InputEventMouseButton): return false
	pointer = canvas.get_global_transform().affine_inverse()*event.position
	if event is InputEventMouseMotion:
		if pressed_side < 0: return false
		if hub.phase == "prepare" and pointer.distance_to(press_at) >= DRAG_THRESHOLD: dragging = true
		candidate_slot = slot_at(pointer,pressed_side)
		if dragging:
			ghost.show()
			ghost.position = pointer-ghost.size*Vector2(0.5,0.8)
		return true
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and pressed_side >= 0:
		cancel_drag()
		return true
	if event.button_index != MOUSE_BUTTON_LEFT: return false
	if event.pressed:
		if hub.inspector.bag.visible or hub.inspector.blocks_event(event): return false
		# The deployment hand and selected destination keep their original gesture.
		if hub.deployment.active() and hub.deployment.mode in [hub.deployment.Mode.DEPLOY,hub.deployment.Mode.SWAP]: return false
		var unit: Dictionary = hub.inspector.pick(pointer)
		if unit.is_empty(): return false
		pressed_side = unit.side
		pressed_slot = unit.slot
		press_at = pointer
		press_was_paused = hub.paused
		hub.paused = true
		hub.deployment.cancel()
		hub.inspector.close_info()
		ghost.texture = unit.animation.texture() if unit.animation.texture() != null else unit.portrait
		ghost.size = unit.battle_animation.display_size if unit.battle_animation != null else Vector2(64,64)
		ghost.flip_h = unit.battle_animation != null and unit.battle_animation.should_flip(unit.presentation.facing_right)
		return true
	if pressed_side < 0: return false
	var side := pressed_side
	var slot := pressed_slot
	var moved := dragging
	candidate_slot = slot_at(pointer,side)
	var target := candidate_slot
	cancel_drag()
	if moved:
		if target >= 0 and target != slot: move_unit(side,slot,target)
		elif target < 0: hub._note("未换位：请拖到同侧阵位，Esc 可取消。")
	else: open_unit(side,slot)
	return true

func _input(event: InputEvent) -> void:
	if handle_input(event): hub.get_viewport().set_input_as_handled()

func cancel_drag() -> void:
	if pressed_side >= 0: hub.paused = press_was_paused
	pressed_side = -1
	pressed_slot = -1
	dragging = false
	candidate_slot = -1
	if is_instance_valid(ghost): ghost.hide()

func move_unit(side: int, source: int, target: int) -> void:
	if hub.phase != "prepare" or source == target: return
	if side == 0:
		var old: int = hub.formation[source]
		hub.formation[source] = hub.formation[target]
		hub.formation[target] = old
		hub._deployment_changed()
	else:
		var settings: Dictionary = Model.snapshot(hub)
		var old: Dictionary = settings.enemies[source]
		settings.enemies[source] = settings.enemies[target]
		settings.enemies[target] = old
		settings.enemies[source].slot = source
		settings.enemies[target].slot = target
		settings.enabled = true
		var error: String = Model.apply(hub,settings,true)
		if not error.is_empty(): hub._note(error); return
	hub._note("已调整阵位；点击角色可更换或改属性，准备好后开战。")
	hub.queue_redraw()

func open_unit(side: int, slot: int) -> void:
	if not active(): return
	var unit: Dictionary = unit_at(side,slot)
	if unit.is_empty(): return
	edit_side = side
	edit_slot = slot
	anchor = Model.Content.role_id(unit.get("deployment_role",unit.role)) if side == 0 else ""
	draft = Model.snapshot(hub)
	row = draft.enemies[slot] if side == 1 else draft.allies.get(anchor,{"id":unit.content_id,"stats":Model.stats(unit)})
	was_paused = hub.paused
	hub.paused = true
	hub.deployment.cancel()
	hub.inspector.close_info()
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	stat_fields.clear()
	var top := HBoxContainer.new()
	column.add_child(top)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(46,46)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = unit.portrait
	top.add_child(portrait)
	heading = Ui.label(("友方" if side == 0 else "敌方")+" · "+unit.name,20)
	heading.custom_minimum_size.x = 250
	top.add_child(heading)
	selector = OptionButton.new()
	selector.custom_minimum_size.y = 38
	selector.add_theme_font_size_override("font_size",18)
	Ui.apply_button(selector)
	var definitions: Array = Model.Content.MANIFEST.characters if side == 0 else Model.Content.MANIFEST.enemies
	for definition in definitions:
		selector.add_item(definition.display_name)
		var index: int = selector.item_count-1
		selector.set_item_metadata(index,definition.id)
		if side == 0:
			selector.set_item_disabled(index,hub.units.any(func(other): return other.side == 0 and other.slot != slot and other.content_id == definition.id))
		if definition.id == row.id: selector.select(index)
	column.add_child(selector)
	selector.item_selected.connect(_select_character)
	var numbers := GridContainer.new()
	numbers.columns = 2
	numbers.add_theme_constant_override("h_separation",12)
	numbers.add_theme_constant_override("v_separation",6)
	column.add_child(numbers)
	for key in Model.STATS:
		var cell := VBoxContainer.new()
		numbers.add_child(cell)
		cell.add_child(Ui.label(Model.STATS[key].name,16))
		var spin := Fields.number(Model.STATS[key].min,Model.STATS[key].max,Model.STATS[key].step)
		spin.custom_minimum_size = Vector2(148,34)
		spin.add_theme_font_size_override("font_size",18)
		spin.value = row.stats[key]
		spin.value_changed.connect(func(value: float): row.stats[key] = value)
		cell.add_child(spin)
		stat_fields[key] = spin
	message = Ui.label("最终属性 · 应用后满血返回整备\n技能、装备与成长随所选同学计算；修改不解锁角色。" if side == 0 else "最终属性 · 应用后满血返回整备\n整备时拖到敌方阵位即可换位或交换。",15,"daily",true)
	message.custom_minimum_size.x = 310
	column.add_child(message)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",10)
	column.add_child(actions)
	apply_button = action("应用修改",actions,apply_edit)
	close_button = action("取消",actions,close)
	menu_at = hub._unit_center(unit)+Vector2(60,-210)
	if menu_at.x > 800: menu_at.x = hub._unit_center(unit).x-410
	shade.show()
	panel.show()
	panel.reset_size()
	var focus: Array[Control] = [selector]
	for field in stat_fields.values(): focus.append(field.get_line_edit())
	focus.append(apply_button)
	focus.append(close_button)
	for index in focus.size():
		focus[index].focus_next = focus[index].get_path_to(focus[(index+1)%focus.size()])
		focus[index].focus_previous = focus[index].get_path_to(focus[posmod(index-1,focus.size())])
	selector.grab_focus()

func action(title: String, parent: Control, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(145,40)
	button.add_theme_font_size_override("font_size",18)
	Ui.apply_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _select_character(index: int) -> void:
	row.id = selector.get_item_metadata(index)
	if edit_side == 1: row.stats = Model.default_stats(hub,row.id)
	else:
		var unit: Dictionary = hub._debug_ally_unit(Model.Content.role_index(row.id),edit_slot)
		unit.max_hp = roundf(unit.max_hp*draft.ally_health)
		unit.atk = roundf(unit.atk*draft.ally_attack)
		row.stats = Model.stats(unit)
	for key in stat_fields: stat_fields[key].value = row.stats[key]
	var definition = Model.enemy(row.id) if edit_side == 1 else Model.Content.character(Model.Content.role_index(row.id))
	heading.text = ("友方" if edit_side == 0 else "敌方")+" · "+definition.display_name
	portrait.texture = definition.portrait

func apply_edit() -> void:
	# Commit typed input even when the user has not pressed Enter in a field.
	for key in stat_fields:
		if stat_fields[key].get_line_edit().has_focus(): stat_fields[key].apply()
	if edit_side == 0: draft.allies[anchor] = row.duplicate(true)
	else: draft.enemies[edit_slot] = row.duplicate(true)
	draft.enabled = true
	var error: String = Model.validate(hub,draft)
	if not error.is_empty(): message.text = error; return
	hub.paused = false
	error = Model.apply(hub,draft,true)
	if not error.is_empty():
		hub.paused = true
		message.text = error
		return
	was_paused = false
	close()
	hub._note("修改已应用；可继续调整阵位，再点击开战。")

func close() -> void:
	cancel_drag()
	if is_instance_valid(panel) and panel.visible:
		panel.hide()
		shade.hide()
		hub.paused = was_paused
		hub.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_drag()
