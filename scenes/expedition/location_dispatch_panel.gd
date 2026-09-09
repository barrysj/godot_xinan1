extends Control
## Location details and crew selection share one transactional dispatch action.
const Catalog = preload("res://game/meta/meta_catalog.gd")
var game: Control
var place: Dictionary
var selected: Array = []
var rows: VBoxContainer
var counter: Label
var feedback: Label
var dispatch_button: Button
var details: Label
var snapshot := ""
var result_message := ""
var refresh_timer := 0.0

func _label(text: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", game.font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", game.DARK)
	return label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1020, 580)
	panel.theme = preload("res://resources/theme/theme-main.tres")
	panel.add_theme_stylebox_override("panel", game.pause_content.get_child(0).get_theme_stylebox("panel"))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	margin.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 330
	left.add_theme_constant_override("separation", 20)
	columns.add_child(left)
	left.add_child(_label(place.name, 28))
	details = _label("")
	details.name = "Details"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(details)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(space)
	left.add_child(game._menu_button("关闭", game._close_location_details))
	columns.add_child(VSeparator.new())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	columns.add_child(right)
	counter = _label("", 26)
	right.add_child(counter)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 310
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10)
	scroll.add_child(rows)
	feedback = _label("", 17)
	feedback.custom_minimum_size.y = 50
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(feedback)
	dispatch_button = game._menu_button("派遣", _dispatch)
	right.add_child(dispatch_button)
	_refresh()
	left.get_child(left.get_child_count() - 1).grab_focus()

func _process(delta: float) -> void:
	# Refresh on profile changes, not each frame; retain selection and scroll state.
	refresh_timer += delta
	if refresh_timer < 0.2: return
	refresh_timer = 0
	var current := _profile_signature()
	if current != snapshot: _refresh()

func _profile_signature() -> String:
	return JSON.stringify([game.progress.points, game.progress.upgrades, game.progress.dispatches, game.progress.load_blocked])

func _toggle(id: String) -> void:
	if not game.progress.staff_reason(id).is_empty(): return
	if selected.has(id): selected.erase(id)
	elif selected.size() < int(place.get("crew_size", 1)): selected.append(id)
	result_message = ""
	_refresh()
	var button = rows.find_child("Select_" + id, true, false)
	if button != null and not button.disabled: button.grab_focus()

func _dispatch() -> void:
	if game.progress.start_dispatch(selected, place.id):
		selected.clear()
		result_message = "队伍已出发，全部成员将在领取成果后归队。"
		game.notice = "队伍已出发，进度已保存。"
	else:
		result_message = game.progress.error_message
	_refresh()

func _refresh() -> void:
	snapshot = _profile_signature()
	selected = selected.filter(func(id): return game.progress.staff_reason(id).is_empty())
	var required: int = place.get("crew_size", 1)
	counter.text = "派遣同学  %d/%d" % [selected.size(), required]
	var requirement := Catalog.find(Catalog.UNLOCKS, place.requires)
	var state := "已解锁" if game.progress.level(place.requires) > 0 else "尚未解锁 · 需要「%s」" % requirement.get("name", place.requires)
	var tag_names: Array = []
	for tag in place.get("required_tags", []): tag_names.append(Catalog.DISPATCH_TAGS.get(tag, {}).get("name", tag))
	details.text = "%s\n\n%s\n\n要求人数：%d 人\n技能要求：%s\n\n消耗：%d 修复资源／队\n时长：%d 秒\n收益：%d 修复资源／队" % [place.description, state, required, "不限" if tag_names.is_empty() else "、".join(tag_names), place.cost, place.duration, place.reward]
	for row in rows.get_children():
		rows.remove_child(row)
		row.queue_free()
	for staff in game.progress.available_staff(): _staff_row(staff, required)
	var reason: String = game.progress.dispatch_reason(selected, place.id)
	dispatch_button.disabled = not reason.is_empty()
	feedback.text = result_message if not result_message.is_empty() else ("人数已满足，可以派遣。" if reason.is_empty() else reason)

func _staff_row(staff: Dictionary, required: int) -> void:
	var unavailable: String = game.progress.staff_reason(staff.id)
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 88
	row.add_theme_constant_override("separation", 14)
	rows.add_child(row)
	var avatar := PanelContainer.new()
	avatar.name = "Avatar_" + staff.id
	avatar.custom_minimum_size = Vector2(66, 76)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("777777") if not unavailable.is_empty() else Color("71b8dc")
	avatar.add_theme_stylebox_override("panel", style)
	row.add_child(avatar)
	var initials := _label(staff.name.right(2), 22)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.modulate = Color("bcbcbc") if not unavailable.is_empty() else Color.WHITE
	avatar.add_child(initials)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(_label(staff.name, 19))
	var tags := HFlowContainer.new()
	info.add_child(tags)
	for tag_id in staff.get("tags", []):
		var tag: Dictionary = Catalog.DISPATCH_TAGS.get(tag_id, {"name":tag_id, "color":Color("aaaaaa")})
		var badge := PanelContainer.new()
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = tag.color
		badge_style.content_margin_left = 7
		badge_style.content_margin_right = 7
		badge.add_theme_stylebox_override("panel", badge_style)
		badge.add_child(_label(tag.name, 15))
		tags.add_child(badge)
	if not unavailable.is_empty(): info.add_child(_label(unavailable, 15))
	var button: Button = game._menu_button("取消" if selected.has(staff.id) else "选择", func(): _toggle(staff.id))
	button.name = "Select_" + staff.id
	button.custom_minimum_size = Vector2(82, 44)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.disabled = not unavailable.is_empty() or (selected.size() >= required and not selected.has(staff.id))
	button.tooltip_text = unavailable if not unavailable.is_empty() else ("人数已满，请先取消一名同学" if button.disabled else "")
	row.add_child(button)
