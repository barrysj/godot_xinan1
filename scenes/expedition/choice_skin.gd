extends RefCounted
## Scoped choice-page skin; shared campus palette and crisp, scalable vector art.
const Ui = preload("res://scenes/ui/campus_ui.gd")
const SHELL = "res://assets/art/ui/event_choice/shell.svg"
const PAPER = "res://assets/art/ui/event_choice/paper.png"
const ASSETS = {
	"card":"res://assets/art/ui/event_choice/card.svg",
	"card_active":"res://assets/art/ui/event_choice/card_active.svg",
	"card_disabled":"res://assets/art/ui/event_choice/card_disabled.svg",
	"illustration":"res://assets/art/ui/event_choice/illustration.svg",
	"arrow":"res://assets/art/ui/event_choice/arrow.svg",
	"status":"res://assets/art/ui/event_choice/status.svg",
}
const BUTTONS = {
	"button":{
		"normal":"res://assets/art/ui/event_choice/button_normal.svg",
		"hover":"res://assets/art/ui/event_choice/button_hover.svg",
		"pressed":"res://assets/art/ui/event_choice/button_pressed.svg",
		"disabled":"res://assets/art/ui/event_choice/button_disabled.svg",
		"focus":"res://assets/art/ui/event_choice/button_focus.svg"},
	"secondary":{
		"normal":"res://assets/art/ui/event_choice/secondary_normal.svg",
		"hover":"res://assets/art/ui/event_choice/secondary_hover.svg",
		"pressed":"res://assets/art/ui/event_choice/secondary_pressed.svg",
		"disabled":"res://assets/art/ui/event_choice/secondary_disabled.svg",
		"focus":"res://assets/art/ui/event_choice/secondary_focus.svg"},
}
const OUTCOME_NAMES = {"item":"获得道具","gain":"属性提升","loss":"属性损失","cost":"消耗","story":"线索","build":"构筑变化","recruit":"伙伴加入","resource":"获得资源","route":"继续探索","unknown":"未知结果"}
const TYPE_SIZES = {"title":26,"kicker":14,"section":12,"body":18,"option":18,"option_description":16,"caption":13,"outcome":13,"button":16}
static var fonts: Dictionary = {}
static var type_rules: Dictionary = {}
static var animation_rules: Dictionary = {}

static func font(role: String) -> Font:
	if fonts.has(role): return fonts[role]
	if type_rules.is_empty(): type_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/typography.json"))
	var token: String = "display" if role == "title" else "heading" if role in ["section","option","button","outcome"] else "mono" if role == "kicker" else "body" if role in ["body","option_description"] else "caption"
	var variant := FontVariation.new()
	variant.base_font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	# Static Medium face: preserve title hierarchy with modest synthetic emboldening.
	variant.variation_embolden = maxf(0.0,(float(type_rules.roles[token].weight)-500.0)/300.0)
	fonts[role] = variant
	return variant

static func type_label(item: Label, role: String) -> void:
	item.set_meta("type_role",role)
	item.add_theme_font_override("font",font(role))
	item.add_theme_font_size_override("font_size",TYPE_SIZES[role])
	item.add_theme_color_override("font_color",Color(Ui.colors().text_secondary if role in ["section","caption"] else Ui.colors().text_primary))
	if role == "body": item.add_theme_constant_override("line_spacing",5)

static func duration(role: String) -> float:
	if animation_rules.is_empty(): animation_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/animation.json"))
	return float(animation_rules.durations_ms[role])/1000.0

static func outcome_color(kind: String) -> Color:
	var colors := Ui.colors("semantic")
	match kind:
		"gain": return Color(colors.success).darkened(0.50)
		"loss": return Color(colors.danger).darkened(0.32)
		"cost": return Color(Ui.colors("evening").warm).darkened(0.53)
		"item","resource": return Color(colors.warning).darkened(0.53)
		"story","build": return Color(colors.info).darkened(0.42)
		"recruit": return Color(Ui.colors("brand").magenta).darkened(0.28)
		_: return Color(Ui.colors().text_secondary).darkened(0.12)

static func narrative_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1,1,1,0.68)
	style.border_color = outcome_color("story").lightened(0.3)
	style.border_width_left = 2
	style.content_margin_left = 14
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func texture_style(path: String, patch: int, padding: int = 12) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_texture_margin(side,patch)
		style.set_content_margin(side,padding)
	return style

static func button(item: Button, secondary: bool = false) -> void:
	item.add_theme_font_override("font",font("button"))
	item.add_theme_font_size_override("font_size",TYPE_SIZES.button)
	var family: String = "secondary" if secondary else "button"
	for state in BUTTONS[family]:
		var style := texture_style(BUTTONS[family][state],12,12)
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		item.add_theme_stylebox_override(state,style)
	var dark := Color(Ui.colors().text_primary)
	var light := Color(Ui.colors("night").text_primary)
	for state in ["font_color","font_hover_color","font_focus_color"]: item.add_theme_color_override(state,dark)
	item.add_theme_color_override("font_pressed_color",light)
	item.add_theme_color_override("font_disabled_color",Color(Ui.colors().text_secondary))
	if secondary: item.add_theme_color_override("font_hover_color",light)
	else:
		item.icon = load(ASSETS.arrow)
		item.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for state in ["icon_normal_color","icon_hover_color","icon_focus_color"]: item.add_theme_color_override(state,dark)
		item.add_theme_color_override("icon_pressed_color",light)
		item.add_theme_color_override("icon_disabled_color",Color(Ui.colors().text_secondary))
		item.add_theme_constant_override("h_separation",8)

static func card(item: PanelContainer, action: Button, enabled: bool, compact: bool = false, chips: Array = []) -> void:
	var normal := texture_style(ASSETS.card if enabled else ASSETS.card_disabled,16,14)
	var active := texture_style(ASSETS.card_active,16,14)
	if compact:
		for style in [normal,active]:
			style.content_margin_top = 6
			style.content_margin_bottom = 6
	item.add_theme_stylebox_override("panel",normal)
	if not enabled: return
	var refresh := func(): item.add_theme_stylebox_override("panel",active if action.has_focus() or action.is_hovered() else normal)
	var emphasize := func():
		for chip in chips: chip.emphasize()
	action.mouse_entered.connect(emphasize)
	action.focus_entered.connect(emphasize)
	action.mouse_entered.connect(refresh)
	action.mouse_exited.connect(refresh)
	action.focus_entered.connect(refresh)
	action.focus_exited.connect(refresh)
