extends Control
const Card = preload("res://scenes/holo_card/holo_card_view.gd")
const Visual = preload("res://game/art/holo_card_visual.gd")
const SAMPLE = "res://assets/art/holo_cards/class_photo/card.tres"
const EVIDENCE = "res://design/concepts/class-photo-holo-card/review/codex-workflow/photo-foil-002"
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var card: Control
var layout: HBoxContainer
var holder: CenterContainer
var details: VBoxContainer
var heading: Label
var controls: GridContainer
var frame_button: Button
var photo_button: Button
var failures := 0
var checks: Array[String] = []
var checking := false
var full_photo: TextureRect
func _ready() -> void:
    theme = preload("res://resources/theme/theme-main.tres")
    add_theme_font_override("font",FONT)
    get_window().title = "校园记忆 · 全息照片卡"
    get_window().content_scale_size = Vector2i.ZERO
    checking = "--card-check" in OS.get_cmdline_user_args()
    var card_path = SAMPLE
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--card="): card_path = arg.trim_prefix("--card=")
    var data = load(card_path)
    if not data is Visual or data.photo == null:
        push_error("卡资源无效或缺少照片：" + card_path)
        get_tree().quit(1)
        return
    layout = HBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation",50)
    add_child(layout)
    holder = CenterContainer.new()
    holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.add_child(holder)
    card = Card.new()
    card.visual = data
    holder.add_child(card)
    var center = CenterContainer.new()
    layout.add_child(center)
    details = VBoxContainer.new()
    details.custom_minimum_size.x = 330
    details.add_theme_constant_override("separation",22)
    center.add_child(details)
    _label("MEMORY COLLECTION  /  001",16,Color("20d8f2"))
    heading = _label(data.title,42,Color("f4f8fc"))
    _label("一张合照，一段共同的时光。",20,Color("a5b4c6"))
    var line = HSeparator.new()
    details.add_child(line)
    _label("移动指针或轻拖卡片\n让光沿着记忆的边缘流动。",17,Color("8498b0"))
    controls = GridContainer.new()
    controls.columns = 3
    controls.add_theme_constant_override("h_separation",10)
    controls.add_theme_constant_override("v_separation",8)
    details.add_child(controls)
    _button("复位",func(): card.set_tilt(Vector2.ZERO,true))
    var motion = _button("静态",func(): card.set_reduced_motion(not card.reduced_motion))
    motion.toggle_mode = true
    frame_button = _button("框流光",func(): card.set_frame_effects_enabled(not card.frame_effects_enabled))
    frame_button.toggle_mode = true
    frame_button.button_pressed = true
    photo_button = _button("照片光",func(): card.set_photo_effects_enabled(not card.photo_effects_enabled))
    photo_button.toggle_mode = true
    photo_button.button_pressed = true
    photo_button.tooltip_text = "单独开关照片表面的虹彩扫光"
    _button("原图",_show_original)
    _label("PHOTO ARCHIVE\n原照保留 · 全图呈现",14,Color("71869e"))
    full_photo = TextureRect.new()
    full_photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    full_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    full_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    full_photo.texture = data.photo
    full_photo.mouse_filter = Control.MOUSE_FILTER_STOP
    full_photo.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed: full_photo.hide())
    full_photo.hide()
    add_child(full_photo)
    resized.connect(_layout)
    _layout()
    if "--card-layers" in OS.get_cmdline_user_args(): call_deferred("_export_layers")
    elif checking: call_deferred("_check")
func _label(text: String,font_size: int,color: Color) -> Label:
    var label = Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    details.add_child(label)
    return label
func _button(text: String,action: Callable) -> Button:
    var button = Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(64,44)
    button.add_theme_font_size_override("font_size",17)
    button.pressed.connect(action)
    controls.add_child(button)
    return button
func _show_original() -> void:
    full_photo.show()
func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"): full_photo.hide()
func _layout() -> void:
    if layout == null: return
    var small = size.x < 1100
    var margin: float = 20.0 if small else 72.0
    layout.offset_left = margin
    layout.offset_top = margin
    layout.offset_right = -margin
    layout.offset_bottom = -margin
    layout.add_theme_constant_override("separation",20 if small else 50)
    details.custom_minimum_size.x = 285 if small else 330
    heading.add_theme_font_size_override("font_size",28 if small else 42)
    details.add_theme_constant_override("separation",12 if small else 22)
    var available = Vector2(maxf(160,size.x-margin*2-details.custom_minimum_size.x-50),maxf(140,size.y-margin*2-30))
    var width = minf(available.x,available.y*8.0/7.0)
    card.custom_minimum_size = Vector2(width,width*7.0/8.0)
    queue_redraw()
func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color("090f19"))
    for i in range(12,0,-1):
        draw_circle(size*Vector2(0.33,0.43),float(i)*size.y*0.055,Color(0.07,0.14,0.19,0.045))
    draw_line(Vector2(size.x*0.06,size.y-28),Vector2(size.x*0.94,size.y-28),Color("1c2c3d"),1)
func _frames() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
func _snapshot(name: String) -> Image:
    await _frames()
    var image = get_viewport().get_texture().get_image()
    var error = image.save_png(EVIDENCE.path_join(name+".png"))
    _expect(error == OK,"save "+name)
    return image
func _expect(ok: bool,message: String) -> void:
    checks.append(("PASS " if ok else "FAIL ")+message)
    print(checks.back())
    if not ok: failures += 1
func _difference(a: Image,b: Image) -> float:
    var total := 0.0
    for y in range(0,a.get_height(),16):
        for x in range(0,a.get_width(),16):
            var ca = a.get_pixel(x,y)
            var cb = b.get_pixel(x,y)
            total += absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b)
    return total
func _check() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE))
    for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1920,1200),Vector2i(844,390)]:
        get_window().size = resolution
        await get_tree().create_timer(0.2).timeout
        card.set_tilt(Vector2.ZERO,true)
        await _snapshot("front-%dx%d" % [resolution.x,resolution.y])
        _expect(Rect2(Vector2.ZERO,size).encloses(card.get_global_rect()),"card fits "+str(resolution))
        _expect(Rect2(Vector2.ZERO,size).encloses(controls.get_global_rect()),"controls fit "+str(resolution))
    get_window().size = Vector2i(1920,1080)
    await get_tree().create_timer(0.2).timeout
    card.set_tilt(Vector2.ZERO,true)
    var strength: float = card.visual.photo_foil_strength
    var photo_region = Rect2i(card.global_position+card.size*Vector2(0.18,0.22),card.size*Vector2(0.64,0.52))
    card.material_instance.set_shader_parameter("photo_foil_strength",0.0)
    var before = await _snapshot("photo-before")
    card.material_instance.set_shader_parameter("photo_foil_strength",strength)
    var after = await _snapshot("photo-after")
    photo_button.button_pressed = false
    photo_button.pressed.emit()
    var photo_switch_off = await _snapshot("photo-switch-off")
    _expect(not card.photo_effects_enabled and card.frame_effects_enabled,"photo button changes only photo switch")
    _expect(_difference(before.get_region(photo_region),photo_switch_off.get_region(photo_region))<0.01,"photo switch restores source appearance")
    photo_button.button_pressed = true
    photo_button.pressed.emit()
    frame_button.button_pressed = false
    frame_button.pressed.emit()
    var frame_switch_off = await _snapshot("photo-only")
    _expect(card.photo_effects_enabled and not card.frame_effects_enabled,"frame button changes only frame switch")
    _expect(_difference(after.get_region(photo_region),frame_switch_off.get_region(photo_region))<0.01,"frame switch preserves photo coating")
    frame_button.button_pressed = true
    frame_button.pressed.emit()
    var photo_delta = _difference(before.get_region(photo_region),after.get_region(photo_region))
    _expect(photo_delta>1.0 if strength>0.0 else photo_delta<0.01,"photo coating changes photo pixels only when enabled")
    card.set_effects_enabled(false)
    var disabled = await _snapshot("photo-disabled")
    _expect(_difference(before.get_region(photo_region),disabled.get_region(photo_region))<0.01,"global toggle restores photo pixels")
    card.set_effects_enabled(true)
    card.set_tilt(Vector2(-0.85,0.4),true)
    var left = await _snapshot("tilt-left")
    card.set_tilt(Vector2(0.85,-0.4),true)
    var right = await _snapshot("tilt-right")
    _expect(_difference(left,right)>10.0,"opposite tilts change rendered pixels")
    card.set_effects_enabled(false)
    var off = await _snapshot("foil-off")
    _expect(_difference(right,off)>1.0,"foil toggle changes rendered pixels")
    card.set_effects_enabled(true)
    card.set_reduced_motion(true)
    card.set_tilt(Vector2.ONE,true)
    _expect(card.current_tilt == Vector2.ZERO,"reduced motion locks front")
    var still_a = await _snapshot("static")
    await get_tree().create_timer(0.3).timeout
    var still_b = get_viewport().get_texture().get_image()
    _expect(_difference(still_a,still_b)<0.01,"static render remains stable")
    card.set_reduced_motion(false)
    var source: Resource = card.visual
    var portrait = Image.create(300,600,false,Image.FORMAT_RGB8)
    portrait.fill(Color("267b83"))
    portrait.fill_rect(Rect2i(0,0,300,40),Color.WHITE)
    portrait.fill_rect(Rect2i(0,560,300,40),Color.YELLOW)
    var swapped = Visual.new()
    swapped.photo = ImageTexture.create_from_image(portrait)
    swapped.title = "换图测试 · 竖图"
    swapped.photo_foil_strength = strength
    card.set_visual(swapped)
    card.set_tilt(Vector2.ZERO,true)
    var portrait_on = await _snapshot("reuse-portrait")
    card.material_instance.set_shader_parameter("photo_foil_strength",0.0)
    var portrait_off = await _snapshot("reuse-portrait-off")
    var margin_region = Rect2i(card.global_position+card.size*Vector2(0.18,0.25),card.size*Vector2(0.1,0.45))
    _expect(_difference(portrait_on.get_region(margin_region),portrait_off.get_region(margin_region))<0.01,"portrait contain margins exclude photo coating")
    card.material_instance.set_shader_parameter("photo_foil_strength",strength)
    var second = Card.new()
    second.visual = source
    second.position = Vector2(-2000,-2000)
    second.size = Vector2(400,350)
    add_child(second)
    second.set_tilt(Vector2.ONE,true)
    _expect(card.material_instance != second.material_instance and card.target_tilt == Vector2.ZERO,"instances isolate uniforms")
    second.queue_free()
    card.set_visual(null)
    _expect(not card.face.visible,"empty photo hides cleanly")
    card.set_visual(source)
    card.set_tilt(Vector2.ZERO,true)
    var touch = InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = true
    touch.position = card.size*Vector2(0.8,0.3)
    card._gui_input(touch)
    _expect(card.touch_index == 0 and card.target_tilt.x>0,"touch drives tilt")
    touch.pressed = false
    card._gui_input(touch)
    _expect(card.touch_index == -1 and card.target_tilt == Vector2.ZERO,"release resets touch")
    card.set_tilt(Vector2.ZERO,true)
    await _snapshot("final")
    var file = FileAccess.open(EVIDENCE.path_join("checks.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"failures":failures,"checks":checks},"  "))
    file.close()
    print("HOLO_CARD_CHECK failures=",failures)
    get_tree().quit(failures)
func _export_layers() -> void:
    var dest = "res://design/concepts/class-photo-holo-card/card/001/ruic/assets"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dest))
    for layer in ["background","subject","lineart","text"]:
        card.art.layer = layer
        card.art.queue_redraw()
        card.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        await _frames()
        var image = card.viewport.get_texture().get_image()
        assert(image.save_png(dest.path_join(layer+".png")) == OK)
    print("HOLO_CARD_LAYERS_COMPLETE")
    get_tree().quit()
