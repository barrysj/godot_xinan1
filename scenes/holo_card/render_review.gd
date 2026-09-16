extends Node
const Card = preload("res://scenes/holo_card/holo_card_view.gd")
const Visual = preload("res://game/art/holo_card_visual.gd")
func _ready() -> void:
    call_deferred("_render")
func _fail(message: String) -> void:
    push_error(message)
    get_tree().quit(1)
func _render() -> void:
    var card_path := ""
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--card="): card_path = argument.trim_prefix("--card=")
    if not card_path.begins_with("res://assets/art/holo_cards/") or card_path.get_file() != "card.tres" or ".." in card_path:
        _fail("Expected res://assets/art/holo_cards/<id>/card.tres")
        return
    var visual = load(card_path)
    if not visual is Visual or visual.photo == null:
        _fail("Card must use holo_card_visual.gd and contain a photo")
        return
    var viewport = SubViewport.new()
    viewport.size = Vector2i(1600,1400)
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(viewport)
    var card = Card.new()
    card.visual = visual
    card.size = Vector2(1600,1400)
    viewport.add_child(card)
    card.set_reduced_motion(true)
    card.set_effects_enabled(true)
    card.set_frame_effects_enabled(true)
    card.set_photo_effects_enabled(true)
    for i in range(4):
        await get_tree().process_frame
        await RenderingServer.frame_post_draw
    var rendered = viewport.get_texture().get_image()
    if rendered == null or rendered.is_empty() or rendered.get_used_rect().size == Vector2i.ZERO:
        _fail("Renderer returned an empty card")
        return
    var output = ProjectSettings.globalize_path(card_path.get_base_dir().path_join("review.png"))
    var temporary = output + ".pending"
    if rendered.save_png(temporary) != OK:
        _fail("Could not save review PNG")
        return
    if DirAccess.rename_absolute(temporary,output) != OK:
        _fail("Could not replace review PNG")
        return
    print("HOLO_REVIEW_COMPLETE ",output)
    get_tree().quit()
