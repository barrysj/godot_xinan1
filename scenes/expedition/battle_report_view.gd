extends Control
## Shared read-only report. Original flow retains ownership of reward/retry/quit.
const Ui = preload("res://scenes/ui/campus_ui.gd")
const Codes = preload("res://game/combat/code_catalog.gd")
const HEADERS := ["成员／阵位", "伤害", "秒伤", "治疗", "承伤", "供盾", "吸收"]
const KEYS := ["name", "damage", "dps", "healing", "received", "shield_given", "absorbed"]
var hub
var canvas: Control
var title: Label
var totals: Label
var tabs: TabBar
var table: Tree
var detail: Label
var resource_title: Label
var resource_grid: GridContainer
var milestones: Label
var note: Label
var snapshot: Dictionary = {}
var legacy: Array[Dictionary] = []
var rows: Array = []
var duration := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = hub.theme
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.size = Vector2(1280,720)
	add_child(canvas)
	var content := VBoxContainer.new()
	content.position = Vector2(103,142)
	content.size = Vector2(1069,390)
	content.add_theme_constant_override("separation",8)
	canvas.add_child(content)
	title = Ui.label("",22)
	content.add_child(title)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",18)
	content.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",6)
	body.add_child(left)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",12)
	left.add_child(top)
	tabs = TabBar.new()
	tabs.focus_mode = Control.FOCUS_ALL
	tabs.custom_minimum_size.x = 150
	tabs.add_tab("我方")
	tabs.add_tab("敌方")
	tabs.add_theme_font_size_override("font_size",17)
	for state in ["selected","unselected","hovered"]:
		var tab_style := Ui.button_style("daily","pressed" if state == "selected" else "normal")
		tab_style.content_margin_top = 4
		tab_style.content_margin_bottom = 4
		tabs.add_theme_stylebox_override("tab_"+state,tab_style)
	for state in ["selected","unselected","hovered"]:
		tabs.add_theme_color_override("font_"+state+"_color",Color(Ui.colors().text_primary))
	tabs.tab_changed.connect(func(_index): _populate())
	top.add_child(tabs)
	totals = Ui.label("",16,"daily",true)
	totals.autowrap_mode = TextServer.AUTOWRAP_OFF
	totals.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	totals.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(totals)
	table = Tree.new()
	table.columns = HEADERS.size()
	table.hide_root = true
	table.column_titles_visible = true
	table.select_mode = Tree.SELECT_ROW
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.custom_minimum_size.y = 214
	table.add_theme_font_size_override("font_size",18)
	table.add_theme_font_size_override("title_button_font_size",16)
	table.add_theme_constant_override("v_separation",2)
	table.add_theme_color_override("font_color",Color(Ui.colors().text_primary))
	table.add_theme_color_override("font_selected_color",Color(Ui.colors().text_primary))
	table.add_theme_color_override("title_button_color",Color(Ui.colors().text_secondary))
	var empty := StyleBoxEmpty.new()
	table.add_theme_stylebox_override("panel",empty)
	for state in ["title_button_normal","title_button_hover","title_button_pressed"]:
		table.add_theme_stylebox_override(state,empty)
	var selected := StyleBoxFlat.new()
	selected.bg_color = Color(Ui.colors().accent_primary,0.17)
	selected.border_color = Color(Ui.colors().accent_primary)
	selected.border_width_left = 3
	table.add_theme_stylebox_override("selected",selected)
	table.add_theme_stylebox_override("selected_focus",selected)
	for index in HEADERS.size():
		table.set_column_title(index,HEADERS[index])
		table.set_column_expand(index,index == 0)
		table.set_column_custom_minimum_width(index,148 if index == 0 else 91)
	table.item_selected.connect(_select_row)
	left.add_child(table)
	detail = Ui.label("",16,"daily",true)
	detail.custom_minimum_size.y = 44
	left.add_child(detail)
	var divider := ColorRect.new()
	divider.color = Color(Ui.colors().accent_primary,0.28)
	divider.custom_minimum_size.x = 1
	body.add_child(divider)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 242
	right.add_theme_constant_override("separation",8)
	body.add_child(right)
	resource_title = Ui.label("程序与代码",19)
	right.add_child(resource_title)
	resource_grid = GridContainer.new()
	resource_grid.columns = 4
	resource_grid.add_theme_constant_override("h_separation",12)
	resource_grid.add_theme_constant_override("v_separation",7)
	right.add_child(resource_grid)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	milestones = Ui.label("",16,"daily",true)
	milestones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(milestones)
	note = Ui.label("",14,"daily",true)
	content.add_child(note)
	resized.connect(_layout)
	_layout()
	hide()

func _layout() -> void:
	var factor := minf(size.x/1280,size.y/720)
	canvas.scale = Vector2.ONE*factor
	canvas.position = (size-canvas.size*factor)/2

func present(value: Dictionary, old_rows: Array[Dictionary], old_duration: float) -> void:
	snapshot = value.duplicate(true)
	legacy = old_rows.duplicate(true)
	duration = float(snapshot.get("duration",old_duration))
	title.text = "%s   /   %.1f 秒%s" % [hub.run.node.get("name","战斗"),duration,"   · 调试跳过" if snapshot.get("skipped",false) else ""]
	tabs.set_tab_disabled(1,snapshot.is_empty())
	tabs.current_tab = 0
	note.text = "伤害／治疗只计实际生效值；供盾仅计实际增加量，吸收按受盾者记录。每秒伤害按整场时间计算。"
	if snapshot.is_empty(): note.text = "旧战报仅保存伤害和治疗，其他指标未记录。"
	_populate()
	_resources()

func _populate() -> void:
	table.clear()
	var root := table.create_item()
	var side := tabs.current_tab
	rows = legacy if snapshot.is_empty() else snapshot.rows.filter(func(row): return row.side == side)
	var damage := float(snapshot.get("program_damage",0)) if side == 0 else 0.0
	var survivors := 0
	var best := -1.0
	var selection: TreeItem
	for row in rows:
		damage += row.damage
		if not row.get("defeated",false): survivors += 1
		best = maxf(best,row.damage)
	for row in rows:
		var item := table.create_item(root)
		item.set_metadata(0,row)
		for index in KEYS.size():
			var key: String = KEYS[index]
			var text := "—"
			if key == "name": text = row.name+(" · %d" % [row.slot+1] if row.has("slot") else "")
			elif key == "dps" and not snapshot.is_empty(): text = "%.1f" % (row.damage/duration if duration > 0 else 0.0)
			elif row.has(key): text = "%.0f" % row[key]
			item.set_text(index,text)
			item.set_text_alignment(index,HORIZONTAL_ALIGNMENT_LEFT if index == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
			item.set_tooltip_text(index,"直接程序输出单独统计，不计入角色伤害／治疗／供盾。供盾为实际增加量；吸收仅计真实挡下的伤害。")
		if row.damage == best and selection == null: selection = item
	if selection != null: selection.select(0)
	totals.text = "总伤害 %.0f%s" % [damage,"   存活 %d/%d" % [survivors,rows.size()] if not snapshot.is_empty() else ""]
	_select_row()

func _select_row() -> void:
	var item := table.get_selected()
	if item == null:
		detail.text = "没有记录"
		return
	var row: Dictionary = item.get_metadata(0)
	if snapshot.is_empty():
		detail.text = row.name+" · 生命、行动次数与存活时间未记录"
		return
	var total := 0.0
	for entry in rows: total += entry.damage
	var share: float = row.damage/total*100 if total > 0 else 0.0
	detail.text = "%s · 阵位%d · 结束生命 %.0f/%.0f · %s · 存活 %.1f 秒\n普攻 %d 次 · 技能 %d 次 · 伤害占比 %.1f%% · 获盾 %.0f" % [row.name,row.slot+1,row.hp,row.max_hp,"已退场" if row.defeated else "存活",row.alive_time,row.attacks,row.skills,share,row.shield_gain]

func _resources() -> void:
	for child in resource_grid.get_children():
		resource_grid.remove_child(child)
		child.queue_free()
	for heading in ["代码","生成","消耗","溢出"]: _grid_label(Ui.label(heading,15,"daily",true))
	for kind in Codes.RULES.types:
		var name_label := Ui.label(Codes.RULES.types[kind].name,16)
		name_label.add_theme_color_override("font_color",Codes.RULES.types[kind].color.darkened(0.4))
		_grid_label(name_label)
		for key in ["generated","spent","overflow"]:
			var label := Ui.label("—" if snapshot.is_empty() else str(int(snapshot[key].get(kind,0))),16)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_grid_label(label)
	if snapshot.is_empty():
		milestones.text = "程序与退场时刻未记录"
		return
	var uses := 0
	var programs: Array[String] = []
	for id in snapshot.program_uses:
		uses += int(snapshot.program_uses[id])
		programs.append("%s ×%d" % [Codes.program(id).display_name,snapshot.program_uses[id]])
	var first := "未施放" if snapshot.first_core < 0 else "%.1f 秒" % snapshot.first_core
	var death_time := INF
	var death_names: Array[String] = []
	for row in snapshot.rows:
		if not row.defeated: continue
		if row.alive_time < death_time:
			death_time = row.alive_time
			death_names.clear()
		if is_equal_approx(row.alive_time,death_time): death_names.append(("我方·" if row.side == 0 else "敌方·")+row.name+"(%d)" % [row.slot+1])
	var death := "无退场" if death_names.is_empty() else "%.1f 秒 %s" % [death_time,"、".join(death_names)]
	milestones.text = "程序施放 %d 次\n首次核心 %s\n首个退场 %s\n%s\n程序伤害 %.0f · 治疗 %.0f\n程序供盾 %.0f" % [uses,first,death," / ".join(programs) if uses else "本场未施放程序",snapshot.program_damage,snapshot.program_healing,snapshot.program_shield]
	resource_grid.tooltip_text = "生成包含溢出；消耗包含程序支付和道具转换。到达上限后未入库的代码计入溢出。"

func _grid_label(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_grid.add_child(label)
