extends Node
var BASE: String = get_script().resource_path.get_base_dir()+"/"
var textures := {}
var report: Array = []
var failures: Array = []
var board

class ReviewBoard extends Node2D:
	var tex := {}
	var font = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
	var palette = preload("res://game/combat/code_catalog.gd").RULES.types
	func t(id: String,at: Vector2,dim: Vector2,tint := Color.WHITE) -> void:
		draw_texture_rect(tex[id],Rect2(at,dim),false,tint)
	func label(value: String,at: Vector2,px: int = 16,color := Color("17202b")) -> void:
		draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
	func panel(at: Vector2,dim: Vector2) -> void:
		var style := StyleBoxTexture.new()
		style.texture = tex["style_tooltip"]
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_texture_margin(side,10)
		draw_style_box(style,Rect2(at,dim))
	func stock(kind: String,count: int,at: Vector2) -> void:
		var color: Color = palette[kind].color
		t("stock_frame",at,Vector2(174,52))
		t("code_tile",at+Vector2(9,11),Vector2(30,30),color)
		t("code_"+kind,at+Vector2(13,15),Vector2(22,22),Color("11151c"))
		label(palette[kind].name,at+Vector2(48,19),13,Color("cdd9e1"))
		label("%d / 6" % count,at+Vector2(47,44),24,Color("f4f8fc"))
		for i in 6: t("slot_filled" if i<count else "slot_empty",at+Vector2(106+i*10,33),Vector2(9,9),color if i<count else Color.WHITE)
	func counter(kind: String,count: int,at: Vector2) -> void:
		var color: Color = palette[kind].color
		t("counter_frame",at,Vector2(96,26))
		t("code_"+kind,at+Vector2(4,5),Vector2(16,16),color)
		for i in 3: t("slot_filled" if i<count else "slot_empty",at+Vector2(24+i*12,8),Vector2(10,10),color if i<count else Color.WHITE)
		label("%d/3" % count,at+Vector2(64,19),15,Color("f4f8fc"))
	func bar(at: Vector2,ratio: float,color: Color) -> void:
		t("bar_frame",at,Vector2(104,14))
		var source := Rect2(0,0,196*ratio,16)
		draw_texture_rect_region(tex.bar_fill,Rect2(at+Vector2(3,3),Vector2(98*ratio,8)),source,color)
	func status(at: Vector2,hp: float,progress: float,enemy: bool,cast: bool) -> void:
		var hp_color := Color("ff4d6d") if enemy else Color("36d399")
		var action_color := Color("ffbf66") if cast else Color("20d8f2")
		t("health",at+Vector2(0,-1),Vector2(16,16),hp_color)
		bar(at+Vector2(20,0),hp,hp_color)
		t("intent_charge" if cast else "intent_attack",at+Vector2(0,19),Vector2(16,16),action_color)
		bar(at+Vector2(20,20),progress,action_color)
		if progress > 0.15: t("action_tip",at+Vector2(22+98*progress-10,23),Vector2(10,8),Color("11151c"))
		label("施法 0.8秒" if cast else "普攻 0.8秒",at+Vector2(20,52),12)
	func intent(id: String,at: Vector2,focus := false) -> void:
		t("intent_plate",at,Vector2(32,32))
		if focus: t("intent_focus",at,Vector2(32,32),Color("ffbf66"))
		t("intent_"+id,at+Vector2(6,6),Vector2(20,20),Color("ffbf66") if focus else Color("f4f8fc"))
	func _draw() -> void:
		var viewport := get_viewport_rect().size
		var factor := minf(viewport.x/1280,viewport.y/800)
		draw_rect(Rect2(Vector2.ZERO,viewport),Color("dce5e9"))
		draw_set_transform((viewport-Vector2(1280,800)*factor)/2,0,Vector2.ONE*factor)
		draw_rect(Rect2(0,0,1280,800),Color("eef4f7"))
		draw_rect(Rect2(0,0,1280,90),Color("11151c"))
		label("战斗信息组件",Vector2(40,48),30,Color("f4f8fc"))
		label("正式资产候选 01  /  SVG + 2× PNG  /  Godot 实际渲染",Vector2(42,73),14,Color("a9c1ce"))
		label("CYBER POP CAMPUS",Vector2(967,48),18,Color("20d8f2"))
		label("01  库存与产码",Vector2(40,131),20)
		var kinds := ["red","blue","green","purple"]
		for i in 4: stock(kinds[i],[2,1,3,1][i],Vector2(40+i*194,152))
		t("absorb_frame",Vector2(858,152),Vector2(174,52))
		t("intent_shield",Vector2(867,162),Vector2(28,28),palette.purple.color)
		label("全队吸收",Vector2(905,171),12,Color("d6c7ee"))
		label("48 / 80",Vector2(904,192),23,Color("f4f8fc"))
		label("个人有效命中",Vector2(40,245),14)
		for i in 3: counter(kinds[i],i,Vector2(40+i*140,260))
		label("类型图形 + 节点 + 分数",Vector2(500,278),14,Color("677482"))
		draw_rect(Rect2(906,196,112,3),Color("394653"))
		draw_rect(Rect2(906,196,112*0.6,3),palette.purple.color)
		label("库存与全队吸收独立表达",Vector2(858,245),14,Color("677482"))
		draw_line(Vector2(40,312),Vector2(1240,312),Color("c2d1d9"))
		label("02  血量与唯一行动条",Vector2(40,349),20)
		status(Vector2(48,377),0.8,0.65,false,false)
		status(Vector2(253,377),0.6,0.4,true,true)
		t("shield_plate",Vector2(177,376),Vector2(44,18))
		t("intent_shield",Vector2(179,378),Vector2(14,14),Color("c287ff"))
		label("30",Vector2(195,389),12,Color("f4f8fc"))
		label("普通攻击",Vector2(50,466),14)
		label("技能蓄力",Vector2(255,466),14)
		label("03  意图图标",Vector2(540,349),20)
		var ids := ["attack","ranged","area","shield","heal","charge"]
		var names := ["普攻","远程","范围","护盾","治疗","蓄力"]
		for i in 6:
			intent(ids[i],Vector2(540+i*79,379),i==2)
			label(names[i],Vector2(540+i*79,438),13)
		label("小图形 20px  ·  底板 32px  ·  高亮单独叠层",Vector2(540,466),14,Color("677482"))
		draw_line(Vector2(40,494),Vector2(1240,494),Color("c2d1d9"))
		label("04  背景对比与伸缩检查",Vector2(40,530),20)
		# Actual current game background, used only as a preview surface.
		draw_texture_rect(tex.courtyard,Rect2(40,550,630,168),false)
		draw_rect(Rect2(40,634,630,84),Color("11151c",0.76))
		for row in 2:
			var at := Vector2(65,571+row*82)
			t("health",at,Vector2(16,16),Color("36d399"))
			bar(at+Vector2(22,1),0.72,Color("36d399"))
			bar(at+Vector2(22,19),0.6,Color("20d8f2"))
			counter("blue",2,at+Vector2(159,8))
			intent("area",at+Vector2(292,4),true)
			label("亮背景" if row==0 else "暗背景",at+Vector2(373,25),14,Color("f4f8fc") if row else Color("17202b"))
		panel(Vector2(724,550),Vector2(496,168))
		intent("area",Vector2(742,566),true)
		label("范围攻击",Vector2(790,589),20,Color("f4f8fc"))
		label("对锁定区域内目标造成伤害",Vector2(742,627),17,Color("d7e4ee"))
		label("剩余 2.1 秒",Vector2(742,661),19,Color("ffbf66"))
		label("文字、数值和填充均为独立绘制",Vector2(742,698),13,Color("9fb3c3"))
		label("原尺寸排布 / 图标与框均有真实 Alpha / 不含烘焙文字 / 当前仅资产预览，未替换游戏组件",Vector2(40,761),15,Color("677482"))

func _ready() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(BASE+"png")
	for folder in ["frames","icons"]:
		var dir := DirAccess.open(BASE+folder)
		for name in dir.get_files():
			if not name.ends_with(".svg"): continue
			var id := name.get_basename()
			var image := Image.new()
			var error := image.load_svg_from_string(FileAccess.get_file_as_string(BASE+folder+"/"+name),2.0)
			if error != OK: failures.append("SVG parse "+id); continue
			var bytes := image.get_data()
			var alpha_min := 255
			var alpha_max := 0
			for i in range(3,bytes.size(),4):
				alpha_min = mini(alpha_min,bytes[i]); alpha_max = maxi(alpha_max,bytes[i])
			if alpha_min != 0 or alpha_max != 255: failures.append("Alpha "+id)
			if image.get_pixel(0,0).a > 0.0: failures.append("Corner clipped "+id)
			image.save_png(BASE+"png/"+id+"@2x.png")
			textures[id] = ImageTexture.create_from_image(image)
			report.append({"id":id,"size_2x":[image.get_width(),image.get_height()],"format":image.get_format(),"alpha_min":alpha_min,"alpha_max":alpha_max})
	var native := Image.new()
	native.load_svg_from_string(FileAccess.get_file_as_string(BASE+"frames/tooltip_frame.svg"),1.0)
	textures.style_tooltip = ImageTexture.create_from_image(native)
	textures.courtyard = load("res://assets/art/backgrounds/battle_courtyard/day.png")
	board = ReviewBoard.new()
	board.tex = textures
	var layer := CanvasLayer.new()
	layer.layer = 10000
	add_child(layer)
	layer.add_child(board)
	for dim in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200)]:
		get_window().size = dim
		board.queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/hud-asset-review-%dx%d.png" % [dim.x,dim.y])
	var output := FileAccess.open(BASE+"validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"assets":report,"failures":failures,"viewports":[[1920,1080],[2560,1440],[1920,1200]]},"  "))
	print("HUD asset review: %d vectors / %d failures" % [report.size(),failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
