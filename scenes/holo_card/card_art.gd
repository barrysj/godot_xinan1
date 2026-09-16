extends Control
## Code-native frame. Layer mode also exports RuiC-compatible source textures.
const FONT = preload("res://assets/fonts/SourceHanSansSC-Medium.otf")
var visual: Resource
var layer: String = "frame"
var palette: Dictionary
func _ready() -> void:
    palette = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual/colors.json"))
func _draw() -> void:
    if visual == null or palette.is_empty(): return
    var ink = Color(palette.night.surface)
    var white = Color(palette.night.text_primary)
    var cyan = Color(palette.night.cyan)
    if layer == "subject":
        if visual.photo != null:
            var box = Rect2(64,120,1472,1104)
            var factor: float = minf(box.size.x/visual.photo.get_width(),box.size.y/visual.photo.get_height())
            var extent: Vector2 = visual.photo.get_size()*factor
            draw_texture_rect(visual.photo,Rect2(box.get_center()-extent/2,extent),false)
        return
    if layer == "lineart":
        draw_rect(Rect2(0,0,1600,1400),Color.WHITE)
        draw_rect(Rect2(64,120,1472,1104),Color.BLACK,false,3)
        return
    if layer in ["background","frame"]:
        draw_rect(Rect2(0,0,1600,1400),ink)
        draw_rect(Rect2(64,120,1472,1104),Color(palette.brand.black))
        for x in range(50,1570,30):
            draw_line(Vector2(x,1390),Vector2(x+70,1300),Color(1,1,1,0.025),1)
        if layer == "background": return
    draw_rect(Rect2(18,18,1564,1364),cyan,false,3)
    draw_line(Vector2(64,93),Vector2(1536,93),Color(cyan,0.3),1)
    draw_string(FONT,Vector2(64,68),visual.subtitle,HORIZONTAL_ALIGNMENT_LEFT,1120,24,cyan)
    draw_string(FONT,Vector2(1250,68),visual.edition,HORIZONTAL_ALIGNMENT_LEFT,280,21,white)
    draw_string(FONT,Vector2(64,1295),visual.title,HORIZONTAL_ALIGNMENT_LEFT,1350,42,white)
    draw_string(FONT,Vector2(66,1345),visual.caption,HORIZONTAL_ALIGNMENT_LEFT,1400,22,Color("9cacbd"))
    draw_circle(Vector2(1503,1290),11,cyan)
    draw_arc(Vector2(1503,1290),25,0,TAU*0.75,32,Color(palette.daily.text_secondary),2,true)
