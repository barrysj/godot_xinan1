extends Node
## Actual rendered silhouette test: the pointer-side edge must recede on both axes.
const Card = preload("res://scenes/holo_card/holo_card_view.gd")
const SAMPLE = preload("res://design/concepts/class-photo-holo-card/card/002/card.tres")
const OUTPUT = "res://design/concepts/class-photo-holo-card/review/codex-workflow/tilt-direction"
var failures := 0
var results: Array = []
func _ready() -> void:
    call_deferred("_check")
func _frames() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
func _span(image: Image, horizontal: bool, fixed_pixel: int) -> int:
    var count := 0
    for pixel in range(800):
        var color = image.get_pixel(pixel,fixed_pixel) if horizontal else image.get_pixel(fixed_pixel,pixel)
        if color.a > 0.5: count += 1
    return count
func _check() -> void:
    var viewport = SubViewport.new()
    viewport.size = Vector2i(800,800)
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(viewport)
    var card = Card.new()
    card.visual = SAMPLE
    card.position = Vector2(80,120)
    card.size = Vector2(640,560)
    viewport.add_child(card)
    await _frames()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
    for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
        var event = InputEventMouseMotion.new()
        event.position = card.size*(Vector2(0.5,0.5)+direction*0.4)
        card._gui_input(event)
        card.set_tilt(card.target_tilt,true)
        await _frames()
        var image = viewport.get_texture().get_image()
        var horizontal = direction.y != 0.0
        var sign_value = direction.y if horizontal else direction.x
        var near_pointer = _span(image,horizontal,400+int(sign_value*150))
        var opposite = _span(image,horizontal,400-int(sign_value*150))
        var label = "up" if direction == Vector2.UP else "down" if direction == Vector2.DOWN else "left" if direction == Vector2.LEFT else "right"
        var error = image.save_png(OUTPUT.path_join(label+".png"))
        var passed = near_pointer < opposite-4 and error == OK
        if not passed: failures += 1
        results.append({"direction":label,"pointer_side_span":near_pointer,"opposite_span":opposite,"passed":passed})
        print("PASS " if passed else "FAIL ",label,": pointer side=",near_pointer,", opposite=",opposite)
    var file = FileAccess.open(OUTPUT.path_join("checks.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"failures":failures,"results":results},"  "))
    file.close()
    print("TILT_DIRECTION_CHECK failures=",failures)
    get_tree().quit(failures)
