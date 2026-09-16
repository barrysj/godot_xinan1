extends Control
const Art = preload("res://scenes/holo_card/card_art.gd")
const ShaderCode = preload("res://scenes/holo_card/holo_card.gdshader")
@export var visual: Resource
var viewport: SubViewport
var art: Control
var face: TextureRect
var material_instance: ShaderMaterial
var current_tilt := Vector2.ZERO
var target_tilt := Vector2.ZERO
var reduced_motion := false
var effects_enabled := true
var frame_effects_enabled := true
var photo_effects_enabled := true
var touch_index := -1
var response_seconds := 0.12
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    focus_mode = Control.FOCUS_ALL
    response_seconds = float(JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/animation.json")).durations_ms.micro)/1000.0
    viewport = SubViewport.new()
    viewport.size = Vector2i(1600,1400)
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    add_child(viewport)
    art = Art.new()
    art.size = Vector2(1600,1400)
    viewport.add_child(art)
    face = TextureRect.new()
    face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    face.texture = viewport.get_texture()
    material_instance = ShaderMaterial.new()
    material_instance.shader = ShaderCode
    face.material = material_instance
    add_child(face)
    mouse_exited.connect(reset_view)
    visibility_changed.connect(reset_view)
    if visual != null: set_visual(visual)
func set_visual(value: Resource) -> void:
    visual = value
    if art == null: return
    art.visual = visual
    art.queue_redraw()
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    if visual == null or visual.photo == null:
        face.hide()
        material_instance.set_shader_parameter("photo",null)
        return
    face.show()
    material_instance.set_shader_parameter("photo",visual.photo)
    material_instance.set_shader_parameter("photo_size",visual.photo.get_size())
    material_instance.set_shader_parameter("foil_strength",visual.foil_strength)
    material_instance.set_shader_parameter("photo_foil_strength",visual.photo_foil_strength)
    material_instance.set_shader_parameter("photo_depth",visual.photo_depth)
    reset_view()
func set_reduced_motion(value: bool) -> void:
    reduced_motion = value
    reset_view()
    if value: set_tilt(Vector2.ZERO,true)
func set_effects_enabled(value: bool) -> void:
    effects_enabled = value
    material_instance.set_shader_parameter("effects_enabled",value)
func set_frame_effects_enabled(value: bool) -> void:
    frame_effects_enabled = value
    material_instance.set_shader_parameter("frame_effects_enabled",value)
func set_photo_effects_enabled(value: bool) -> void:
    photo_effects_enabled = value
    material_instance.set_shader_parameter("photo_effects_enabled",value)
func set_tilt(value: Vector2,immediate := false) -> void:
    target_tilt = Vector2.ZERO if reduced_motion else value.clamp(Vector2(-1,-1),Vector2.ONE)
    if immediate:
        current_tilt = target_tilt
        material_instance.set_shader_parameter("tilt",current_tilt)
func reset_view() -> void:
    touch_index = -1
    target_tilt = Vector2.ZERO
func _process(delta: float) -> void:
    if not is_visible_in_tree(): return
    current_tilt = current_tilt.lerp(target_tilt,1.0-exp(-delta/maxf(response_seconds,0.01)))
    if current_tilt.distance_to(target_tilt) < 0.0001: current_tilt = target_tilt
    material_instance.set_shader_parameter("tilt",current_tilt)
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and touch_index < 0:
        set_tilt((event.position/size-Vector2(0.5,0.5))*2.0)
    elif event is InputEventScreenTouch:
        if event.pressed and touch_index < 0:
            touch_index = event.index
            set_tilt((event.position/size-Vector2(0.5,0.5))*2.0)
        elif not event.pressed and event.index == touch_index: reset_view()
        accept_event()
    elif event is InputEventScreenDrag and event.index == touch_index:
        set_tilt((event.position/size-Vector2(0.5,0.5))*2.0)
        accept_event()
    elif event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_LEFT: set_tilt(target_tilt+Vector2(-0.2,0))
            KEY_RIGHT: set_tilt(target_tilt+Vector2(0.2,0))
            KEY_UP: set_tilt(target_tilt+Vector2(0,-0.2))
            KEY_DOWN: set_tilt(target_tilt+Vector2(0,0.2))
            KEY_HOME: reset_view()
func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset_view()
