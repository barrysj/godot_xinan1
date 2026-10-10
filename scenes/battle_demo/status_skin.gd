extends RefCounted
## Shared imported textures; values, fill ratios and input remain native.
const TEXTURES = {
	"absorb_frame": preload("res://assets/art/ui/battle_status/png/absorb_frame@2x.png"),
	"action_tip": preload("res://assets/art/ui/battle_status/png/action_tip@2x.png"),
	"bar_fill": preload("res://assets/art/ui/battle_status/png/bar_fill@2x.png"),
	"bar_frame": preload("res://assets/art/ui/battle_status/png/bar_frame@2x.png"),
	"code_blue": preload("res://assets/art/ui/battle_status/png/code_blue@2x.png"),
	"code_green": preload("res://assets/art/ui/battle_status/png/code_green@2x.png"),
	"code_purple": preload("res://assets/art/ui/battle_status/png/code_purple@2x.png"),
	"code_red": preload("res://assets/art/ui/battle_status/png/code_red@2x.png"),
	"code_tile": preload("res://assets/art/ui/battle_status/png/code_tile@2x.png"),
	"counter_frame": preload("res://assets/art/ui/battle_status/png/counter_frame@2x.png"),
	"health": preload("res://assets/art/ui/battle_status/png/health@2x.png"),
	"intent_area": preload("res://assets/art/ui/battle_status/png/intent_area@2x.png"),
	"intent_attack": preload("res://assets/art/ui/battle_status/png/intent_attack@2x.png"),
	"intent_charge": preload("res://assets/art/ui/battle_status/png/intent_charge@2x.png"),
	"intent_focus": preload("res://assets/art/ui/battle_status/png/intent_focus@2x.png"),
	"intent_heal": preload("res://assets/art/ui/battle_status/png/intent_heal@2x.png"),
	"intent_plate": preload("res://assets/art/ui/battle_status/png/intent_plate@2x.png"),
	"intent_ranged": preload("res://assets/art/ui/battle_status/png/intent_ranged@2x.png"),
	"intent_shield": preload("res://assets/art/ui/battle_status/png/intent_shield@2x.png"),
	"shield_plate": preload("res://assets/art/ui/battle_status/png/shield_plate@2x.png"),
	"slot_empty": preload("res://assets/art/ui/battle_status/png/slot_empty@2x.png"),
	"slot_filled": preload("res://assets/art/ui/battle_status/png/slot_filled@2x.png"),
	"stock_focus": preload("res://assets/art/ui/battle_status/png/stock_focus@2x.png"),
	"stock_frame": preload("res://assets/art/ui/battle_status/png/stock_frame@2x.png"),
	"tooltip_frame": preload("res://assets/art/ui/battle_status/png/tooltip_frame@2x.png"),
	"tooltip_tail": preload("res://assets/art/ui/battle_status/png/tooltip_tail@2x.png"),
}
const DETAIL = preload("res://assets/art/ui/battle_status/styles/tooltip_frame.tres")

static func draw(canvas: CanvasItem,id: String,rect: Rect2,tint := Color.WHITE) -> void:
	canvas.draw_texture_rect(TEXTURES[id],rect,false,tint)

static func bar(canvas: CanvasItem,at: Vector2,ratio: float,tint: Color,size := Vector2(104,14),inset := 3.0) -> void:
	draw(canvas,"bar_frame",Rect2(at,size))
	var value := clampf(ratio,0,1)
	if value <= 0: return
	canvas.draw_texture_rect_region(TEXTURES.bar_fill,Rect2(at+Vector2.ONE*inset,Vector2((size.x-2*inset)*value,size.y-2*inset)),Rect2(0,0,196*value,16),tint)

static func intent_icon(unit: Dictionary,intent: Dictionary) -> String:
	if intent.get("kind","attack") == "attack":
		return "intent_ranged" if unit.action_profile.is_projectile(unit.attack_range) else "intent_attack"
	if intent.get("icon","") in ["shield","area","heal"]: return "intent_"+intent.icon
	for effect in unit.skill.effects:
		if effect.kind == "heal": return "intent_heal"
		if effect.kind == "shield": return "intent_shield"
	return "intent_charge"
