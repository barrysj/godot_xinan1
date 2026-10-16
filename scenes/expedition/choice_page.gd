extends Control
## One native modal for rewards, dialogue nodes and permanent terminal recovery.
signal action(id: String)
const Ui = preload("res://scenes/ui/campus_ui.gd")
const Outcomes = preload("res://scenes/expedition/choice_outcomes.gd")
const OutcomeChip = preload("res://scenes/expedition/choice_outcome_chip.gd")
const ChoiceSkin = preload("res://scenes/expedition/choice_skin.gd")
const PICTURES = {
	"frame":"res://assets/art/ui/event_choice/frame.png",
	"reward":"res://assets/art/ui/event_choice/reward.png",
	"terminal":"res://assets/art/ui/event_choice/terminal.png",
}
var sheet: Control
var body: HBoxContainer
var buttons: Array[Button] = []
var close_id := ""
var close_enabled := true
var close_reason: Label
var return_feedback: Tween
var previous_focus: Control
var fade: Tween
var content_fade: Tween
var presentation_revision := 0

func _ready() -> void:
	name = "ChoicePage"
	z_index = 90
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	theme = Theme.new()
	theme.default_font = ChoiceSkin.font("body")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04,0.06,0.10,0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	sheet = Control.new()
	sheet.name = "ChoiceSheet"
	sheet.size = Vector2(1120,640)
	add_child(sheet)
	var paper := TextureRect.new()
	paper.texture = load(ChoiceSkin.PAPER)
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(paper)
	var wash := ColorRect.new()
	wash.color = Color(1,1,1,0.48)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(wash)
	var chrome := TextureRect.new()
	chrome.texture = load(ChoiceSkin.SHELL)
	chrome.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(chrome)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24 if side in ["top","bottom"] else 32)
	sheet.add_child(margin)
	body = HBoxContainer.new()
	body.add_theme_constant_override("separation",32)
	margin.add_child(body)
	resized.connect(_layout)
	_layout()
	hide()

func _layout() -> void:
	if sheet == null: return
	var factor := minf(size.x/1280.0,size.y/720.0)
	sheet.scale = Vector2.ONE*factor
	sheet.position = (size-sheet.size*factor)*0.5

func _label(value: String, parent: Control, role: String = "body") -> Label:
	var label := Ui.label(value,ChoiceSkin.TYPE_SIZES[role])
	ChoiceSkin.type_label(label,role)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _glossary(value: String, parent: Control, role: String) -> RichTextLabel:
	var label = preload("res://scenes/ui/glossary_text.gd").make(value,ChoiceSkin.TYPE_SIZES[role],true)
	label.set_meta("type_role",role)
	parent.add_child(label)
	return label

func _button(label: String, id: String, parent: Control, enabled: bool = true, secondary: bool = false) -> Button:
	var button := Button.new()
	button.text = label
	button.set_meta("action_id",id)
	button.custom_minimum_size = Vector2(96,34)
	button.disabled = not enabled
	Ui.apply_button(button,"daily")
	ChoiceSkin.button(button,secondary)
	button.pressed.connect(func(): action.emit(id))
	button.focus_entered.connect(func(): ensure_button_visible.call_deferred(button))
	parent.add_child(button)
	buttons.append(button)
	return button

func present(model: Dictionary) -> void:
	presentation_revision += 1
	if content_fade != null: content_fade.kill()
	if return_feedback != null: return_feedback.kill()
	var was_open := visible
	if not was_open: previous_focus = get_viewport().gui_get_focus_owner()
	for child in body.get_children():
		child.hide()
		body.remove_child(child)
		child.queue_free()
	buttons.clear()
	close_id = model.get("close_id","")
	close_enabled = model.get("close_enabled",true)
	close_reason = null
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 364
	left.add_theme_constant_override("separation",12)
	body.add_child(left)
	var category := _label("校园补给" if model.get("picture",PICTURES.terminal) == PICTURES.reward else "现场档案",left,"kicker")
	category.add_theme_color_override("font_color",Color(Ui.colors("night").cyan))
	var image_frame := Control.new()
	image_frame.name = "Illustration"
	image_frame.clip_contents = true
	image_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(image_frame)
	var image := TextureRect.new()
	image.texture = load(model.get("picture",PICTURES.terminal))
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_frame.add_child(image)
	if model.get("foreground") != null:
		var foreground := TextureRect.new()
		foreground.texture = model.foreground
		foreground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foreground.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		foreground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		foreground.offset_left = 26
		foreground.offset_right = -26
		foreground.offset_top = 28
		foreground.offset_bottom = -28
		foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image_frame.add_child(foreground)
	var image_border := Panel.new()
	image_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_border.add_theme_stylebox_override("panel",ChoiceSkin.texture_style(ChoiceSkin.ASSETS.illustration,20,0))
	image_frame.add_child(image_border)
	var caption := _label(model.get("caption","校园探索 · 调查记录"),left,"caption")
	caption.add_theme_color_override("font_color",Color(Ui.colors("night").text_primary,0.8))
	var right := VBoxContainer.new()
	right.name = "ChoiceContent"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",8)
	body.add_child(right)
	var heading := HBoxContainer.new()
	right.add_child(heading)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation",2)
	heading.add_child(titles)
	var tag := _label(model.get("tag","调查记录"),titles,"kicker")
	tag.add_theme_color_override("font_color",ChoiceSkin.outcome_color("story"))
	_label(model.title,titles,"title")
	if not close_id.is_empty():
		var navigation := VBoxContainer.new()
		navigation.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		navigation.add_theme_constant_override("separation",2)
		heading.add_child(navigation)
		var close := _button(model.get("close_label","返回地点"),close_id,navigation,close_enabled,true)
		if not close_enabled:
			close.tooltip_text = model.get("close_hint","必须完成选择后才能返回地点。")
			close_reason = _label("必须完成选择",navigation,"caption")
			close_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rule := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color(Ui.colors().accent_primary,0.32)
	line.thickness = 1
	rule.add_theme_stylebox_override("separator",line)
	right.add_child(rule)
	# The entire reading area scrolls: long dialogue and large rosters cannot push actions off screen.
	var scroll := ScrollContainer.new()
	scroll.name = "ChoicesScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = false # Visibility is resolved in local coordinates through the scaled sheet.
	right.add_child(scroll)
	var reading := VBoxContainer.new()
	reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading.add_theme_constant_override("separation",8)
	scroll.add_child(reading)
	var narrative := VBoxContainer.new()
	narrative.name = "NarrativeBlock"
	narrative.add_theme_constant_override("separation",4)
	reading.add_child(narrative)
	_label(model.get("body_label","事件记录"),narrative,"section")
	var narrative_panel := PanelContainer.new()
	narrative_panel.add_theme_stylebox_override("panel",ChoiceSkin.narrative_style())
	narrative.add_child(narrative_panel)
	_glossary(model.get("description",""),narrative_panel,"body")
	_add_outcomes(model.get("outcomes",[]),narrative)
	if not model.get("options",[]).is_empty(): _label(model.get("options_label","可选行动"),reading,"section")
	for option in model.get("options",[]):
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel",ChoiceSkin.texture_style(ChoiceSkin.ASSETS.card,16,14))
		reading.add_child(card)
		var compact: bool = model.get("compact",false)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",4)
		card.add_child(box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		box.add_child(row)
		if option.get("icon") != null:
			var icon := TextureRect.new()
			icon.texture = option.icon
			icon.custom_minimum_size = Vector2.ONE*float(option.get("icon_size",24))
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
		var title := _label(option.get("title",option.label),row,"option")
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button := _button(option.label,option.id,row,option.get("enabled",true))
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.tooltip_text = option.get("hint","")
		var results := Outcomes.normalize(option.get("outcomes",[]))
		if not option.get("description","").is_empty():
			var detail := _glossary(option.description,box,"option_description")
			if results.size() == 1 and results[0].kind in ["gain","loss","cost"]: detail.add_theme_color_override("default_color",ChoiceSkin.outcome_color(results[0].kind))
		var notes: Control = box
		if compact and not results.is_empty() and not option.get("hint","").is_empty():
			notes = HBoxContainer.new()
			notes.add_theme_constant_override("separation",8)
			box.add_child(notes)
		var chips := _add_outcomes(results,notes)
		ChoiceSkin.card(card,button,option.get("enabled",true),compact,chips)
		if not option.get("hint","").is_empty():
			var hint := _label(option.hint,notes,"caption")
			if notes is HBoxContainer:
				hint.custom_minimum_size.x = minf(230,ceilf(hint.get_theme_font("font").get_string_size(hint.text,HORIZONTAL_ALIGNMENT_LEFT,-1,hint.get_theme_font_size("font_size")).x))
				hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",8)
	right.add_child(footer)
	var saved := TextureRect.new()
	saved.texture = load(ChoiceSkin.ASSETS.status)
	saved.custom_minimum_size = Vector2(16,16)
	saved.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	saved.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	saved.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(saved)
	var status := _label(model.get("status","选择后会保存进度。"),footer,"caption")
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not model.get("footer_action","").is_empty():
		_button(model.get("footer_label","刷新"),model.footer_action,footer,model.get("footer_enabled",true),true)
	show()
	_layout()
	right.modulate.a = 0.72
	content_fade = create_tween()
	content_fade.tween_property(right,"modulate:a",1.0,ChoiceSkin.duration("normal")).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not was_open:
		if fade != null: fade.kill()
		modulate.a = 0
		fade = create_tween()
		fade.tween_property(self,"modulate:a",1.0,ChoiceSkin.duration("normal")).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_focus_first.call_deferred(presentation_revision)

func _add_outcomes(results: Variant, parent: Control) -> Array:
	var chips: Array = []
	var entries := Outcomes.normalize(results)
	if entries.is_empty(): return chips
	var flow := HFlowContainer.new()
	flow.name = "ChoiceOutcomes"
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_theme_constant_override("h_separation",6)
	flow.add_theme_constant_override("v_separation",4)
	parent.add_child(flow)
	for entry in entries:
		var chip = OutcomeChip.new()
		chip.setup(entry)
		flow.add_child(chip)
		chips.append(chip)
	return chips

func _focus_first(revision: int) -> void:
	# Containers settle after replacement; never focus using their provisional geometry.
	for i in range(2): await get_tree().process_frame
	if revision != presentation_revision or not is_visible_in_tree(): return
	var active: Array[Button] = []
	for button in buttons:
		if not button.disabled: active.append(button)
	for index in range(active.size()):
		active[index].focus_neighbor_top = active[index].get_path_to(active[posmod(index-1,active.size())])
		active[index].focus_neighbor_bottom = active[index].get_path_to(active[(index+1)%active.size()])
		active[index].focus_neighbor_left = active[index].get_path_to(active[posmod(index-1,active.size())])
		active[index].focus_neighbor_right = active[index].get_path_to(active[(index+1)%active.size()])
		active[index].focus_next = active[index].get_path_to(active[(index+1)%active.size()])
		active[index].focus_previous = active[index].get_path_to(active[posmod(index-1,active.size())])
	if not active.is_empty():
		var first := active[0]
		for button in active:
			if button.get_meta("action_id","") != close_id:
				first = button
				break
		var scroll := find_child("ChoicesScroll",true,false) as ScrollContainer
		# Long prose starts at the beginning; focusing its distant action must be deliberate.
		if scroll != null and not scroll.get_global_rect().encloses(first.get_global_rect()):
			if close_enabled and not close_id.is_empty(): first = active[0]
			else:
				# A locked long story starts with its reader focused, before the choices.
				scroll.focus_mode = Control.FOCUS_ALL
				scroll.focus_next = scroll.get_path_to(first)
				scroll.focus_neighbor_bottom = scroll.get_path_to(first)
				first.focus_previous = first.get_path_to(scroll)
				scroll.grab_focus()
				return
		first.grab_focus()

func ensure_button_visible(button: Button) -> void:
	if not is_visible_in_tree() or not is_instance_valid(button): return
	var scroll := find_child("ChoicesScroll",true,false) as ScrollContainer
	if scroll == null or not scroll.is_ancestor_of(button): return
	var target: Control = button
	while target.get_parent() != null and not target is PanelContainer: target = target.get_parent() as Control
	if target.size.y > scroll.size.y: target = button
	var transform := scroll.get_global_transform_with_canvas().affine_inverse()*target.get_global_transform_with_canvas()
	var top := (transform*Vector2.ZERO).y
	var bottom := (transform*target.size).y
	if top < 0: scroll.scroll_vertical += floori(top)
	elif bottom > scroll.size.y: scroll.scroll_vertical += ceili(bottom-scroll.size.y)

func dismiss() -> void:
	presentation_revision += 1
	if content_fade != null: content_fade.kill()
	if return_feedback != null: return_feedback.kill()
	if fade != null: fade.kill()
	hide()
	modulate.a = 1
	for button in buttons:
		if is_instance_valid(button): button.release_focus()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	previous_focus = null

func notify_return_blocked() -> void:
	if not is_instance_valid(close_reason): return
	if return_feedback != null: return_feedback.kill()
	close_reason.modulate.a = 0.65
	return_feedback = close_reason.create_tween()
	return_feedback.tween_property(close_reason,"modulate:a",1.0,ChoiceSkin.duration("normal")).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func handle_input(event: InputEvent) -> bool:
	if not is_visible_in_tree(): return false
	if event.is_action_pressed("ui_cancel") and not close_id.is_empty():
		if close_enabled: action.emit(close_id)
		else: notify_return_blocked()
		return true
	return false
