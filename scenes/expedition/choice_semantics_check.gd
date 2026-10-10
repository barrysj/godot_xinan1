extends Node
## Actual main-flow reward click plus presentation-only consequence probes.
const Scene = preload("res://scenes/expedition/expedition.tscn")
const Outcomes = preload("res://scenes/expedition/choice_outcomes.gd")
var game
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("CHOICE_SEMANTICS: "+label)

func settle() -> void:
	for i in range(6): await get_tree().process_frame

func capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await get_tree().create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	expect(get_viewport().get_texture().get_image().save_png("res://.godot/choice-semantic-%s-%dx%d.png" % [label,resolution.x,resolution.y]) == OK,"capture "+label)

func pointer(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	get_viewport().push_input(event,true)

func click(button: Button) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = button.get_global_transform_with_canvas()*(button.size*0.5)
		get_viewport().push_input(event,true)
	await settle()

func luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return linear.r*0.2126+linear.g*0.7152+linear.b*0.0722

func verify_labels(page: Control) -> void:
	var roles: Dictionary = {}
	for label in page.find_children("*","Label",true,false):
		if label.has_meta("type_role"): roles[label.get_meta("type_role")] = label
	expect(roles.title.get_theme_font_size("font_size") > roles.body.get_theme_font_size("font_size"),"title stands above story body")
	expect(roles.option.get_theme_font_size("font_size") > roles.option_description.get_theme_font_size("font_size"),"option names stand above details")
	var axis: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	var title_font: FontVariation = roles.title.get_theme_font("font")
	var body_font: FontVariation = roles.body.get_theme_font("font")
	expect(body_font.variation_opentype.get(axis) == 400 and title_font.variation_opentype.get(axis) > body_font.variation_opentype[axis],"native font axis separates regular body and bold heading")

func verify_chips(page: Control, expected: Array) -> void:
	var seen: Array = []
	for chip in page.find_children("Outcome_*","PanelContainer",true,false):
		seen.append(chip.kind)
		var label: Label = chip.find_children("*","Label",true,false)[0]
		var style: StyleBoxFlat = chip.get_theme_stylebox("panel")
		var ink := luminance(label.get_theme_color("font_color"))
		var paper := luminance(style.bg_color)
		expect((maxf(ink,paper)+0.05)/(minf(ink,paper)+0.05) >= 4.5,"readable consequence "+chip.kind)
		expect(not label.text.is_empty() and chip.symbol != null,"consequence has text and symbol "+chip.kind)
		expect(chip.size.x <= chip.get_parent().size.x+0.5,"consequence stays within flow "+chip.kind)
	for kind in expected: expect(seen.has(kind),"visible category "+kind)

func verify_three_fit(page: Control) -> void:
	var scroll: ScrollContainer = page.find_child("ChoicesScroll",true,false)
	expect(not scroll.get_v_scroll_bar().visible,"three genuine rewards require no scroll")
	for button in page.buttons:
		if not button.get_meta("action_id","").begins_with("reward:"): continue
		var card: Node = button.get_parent()
		while not card is PanelContainer: card = card.get_parent()
		expect(scroll.get_global_rect().encloses(card.get_global_rect()),"entire reward card fits at initial scroll position")
		expect(scroll.get_global_rect().encloses(button.get_global_rect()),"all three actions stay visible")

func mixed_model() -> Dictionary:
	return {"tag":"界面展示检查","title":"收益与代价","description":"以下数值仅用于展示检查；此页不会发放奖励或改变属性。","body_label":"展示说明","options_label":"后果样例","compact":true,"close_id":"probe_back","close_label":"返回地点","status":"展示检查 · 不写入玩家存档","options":[
		{"id":"probe_tradeoff","label":"查看","title":"同时显示收益与代价","description":"同一选项可以包含正面与负面结果。","outcomes":[{"kind":"gain","text":"生命上限 +10"},{"kind":"loss","text":"攻击 -2"}]},
		{"id":"probe_item","label":"查看","title":"道具与消耗","description":"获得物品和支付资源分别呈现。","outcomes":[{"kind":"item","text":"代码补给 +1"},{"kind":"cost","text":"修复资源 -1"}]},
		{"id":"probe_other","label":"查看","title":"其他结果","description":"文字和符号共同标记结果，不只依靠颜色。","outcomes":[{"kind":"story","text":"记录线索"},{"kind":"build","text":"调整编队"},{"kind":"recruit","text":"本局候补"},{"kind":"resource","text":"修复资源 +1"},{"kind":"route","text":"返回地点"},{"kind":"unknown","text":"结果未明"}]}
	]}

func _ready() -> void:
	game = Scene.instantiate()
	game.progress.path = "res://.godot/choice-semantic-test-%d.json" % Time.get_ticks_usec()
	add_child(game)
	await settle()
	game.set_process(false)
	game.progress.campaign.prologue_done = true
	game.progress.campaign.routes_acquired = true
	var resolutions := [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)] if "--capture" in OS.get_cmdline_user_args() else [Vector2i(1920,1080)]
	for resolution in resolutions:
		get_window().size = resolution
		game._begin_region("library","region","protect")
		game._campaign_action("enter:0")
		game._victory()
		var pool: Array = game.RunModel.Rewards.for_build(game.run)
		var supply: Dictionary = pool.filter(func(offer): return offer.id == "code_supply")[0]
		var train: Dictionary = pool.filter(func(offer): return offer.operation == "train")[0]
		var gear: Dictionary = pool.filter(func(offer): return offer.id == "ribbon")[0]
		game.journey.data.offers = [supply,train,gear]
		game._save_campaign()
		var frozen: Array = game.journey.data.offers.duplicate(true)
		var before: Dictionary = game.run.to_dict()
		game._show_journey()
		await settle()
		var page: Control = game.campaign_panel.choice_page
		verify_labels(page)
		verify_three_fit(page)
		verify_chips(page,["item","gain"])
		expect(game.run.to_dict() == before and game.journey.data.offers == frozen,"painting does not change build or frozen offers")
		expect(Outcomes.reward(gear)[0].kind == "item","equipment remains an inventory reward, not immediate stat gain")
		await capture("reward",resolution)
		var button: Button = game.campaign_panel.action_button("reward:0")
		var box := button.get_global_rect()
		var chip = button.get_parent().get_parent().find_child("Outcome_item",true,false)
		pointer(Vector2(10,10))
		await settle()
		pointer(button.get_global_transform_with_canvas()*(button.size*0.5))
		expect(button.is_hovered() and chip.pulse != null,"real pointer starts consequence feedback")
		await get_tree().create_timer(0.22).timeout
		expect(chip.symbol.scale.is_equal_approx(Vector2.ONE) and button.get_global_rect() == box,"feedback settles and leaves hitbox stationary")
		var stock_before: int = game.run.code_supplies.supply
		# Re-present and click immediately after layout, while the reading fade can run.
		game._show_journey()
		await get_tree().process_frame
		button = game.campaign_panel.action_button("reward:0")
		expect(not button.disabled,"fade keeps valid choice enabled")
		await click(button)
		expect(game.run.code_supplies.supply == stock_before+1 and game.journey.visit.data.reward_taken,"native click grants existing item once")
		expect(not page.visible,"actual reward closes the modal")
		var claimed: Dictionary = game.run.to_dict()
		game._campaign_action("reward:0")
		expect(game.run.to_dict() == claimed,"feedback does not bypass original duplicate guard")
		var saved: Dictionary = game.progress.to_dict()
		page.present(mixed_model())
		await settle()
		verify_chips(page,Outcomes.KINDS)
		await capture("mixed",resolution)
		expect(game.run.to_dict() == claimed and game.progress.to_dict() == saved,"negative and mixed probes are presentation only")
		# Long single tags also wrap, not just flows with many small chips.
		var long_model: Dictionary = mixed_model()
		long_model.options = [{"id":"probe_long","label":"查看","title":"长结果说明","outcomes":[{"kind":"not_defined","text":"这是一段用于检查自动换行的较长结果说明，必须保持在选项卡内，不能挤出按钮或扩大整个界面。"}]}]
		page.present(long_model)
		await settle()
		verify_chips(page,["unknown"])
		if resolution == Vector2i(1920,1080): await capture("long",resolution)
		page.present(mixed_model())
		page.dismiss()
		await settle()
		expect(not page.visible,"rapid node replacement and dismissal cancel transient feedback")
	expect(Outcomes.event({"to":"END","set":{"trace":true}})[0].kind == "story","existing persisted clue is marked by typed effect")
	expect(Outcomes.event({"command":"protect"})[0].kind == "build","existing formation command is distinct from prose")
	var mixed: Array = Outcomes.event({"outcomes":[{"kind":"gain","text":"+1"},{"kind":"loss","text":"-1"}]})
	expect(mixed.size() == 2 and mixed[0].kind != mixed[1].kind,"explicit tradeoff metadata preserves both outcomes")
	print("CHOICE_SEMANTICS ",checks," checks / ",failures," failures")
	get_tree().quit(1 if failures else 0)
