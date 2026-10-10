extends RefCounted
## Presentation metadata only. Never grants resources or guesses effects from prose.
const Rewards = preload("res://game/run/reward_catalog.gd")
const KINDS = ["item","gain","loss","cost","story","build","recruit","resource","route","unknown"]

static func normalize(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array: return result
	for entry in value:
		if not entry is Dictionary: continue
		var kind: String = str(entry.get("kind","unknown"))
		result.append({"kind":kind if kind in KINDS else "unknown","text":str(entry.get("text",""))})
	return result

static func reward(offer: Dictionary) -> Array[Dictionary]:
	var kind := "unknown"
	var detail := ""
	match offer.get("operation",""):
		"gear": kind = "item"; detail = "装备入库"
		"item": kind = "item"; detail = "库存 +%d" % int(offer.amount)
		"train": kind = "gain"; detail = "本局"
		"recruit": kind = "recruit"; detail = "本局候补"
		"points": kind = "resource"; detail = "修复资源 +%d" % int(offer.amount)
		"combat":
			var definition = Rewards.find_combat(str(offer.target))
			if definition != null:
				kind = "gain" if definition.category == "训练" else "item" if definition.category == "装备" else "build"
				detail = "指定携带者" if definition.category == "装备" else "本局" if definition.category == "训练" else definition.category+"强化"
	return [{"kind":kind,"text":detail}]

static func event(choice: Dictionary) -> Array[Dictionary]:
	# Authors can describe future trade-offs explicitly without this renderer executing them.
	if choice.has("outcomes"): return normalize(choice.outcomes)
	if not choice.get("set",{}).is_empty(): return [{"kind":"story","text":"记录线索"}]
	if not str(choice.get("command","")).is_empty(): return [{"kind":"build","text":"调整编队"}]
	if choice.get("to","") == "END": return [{"kind":"route","text":"返回地点"}]
	return [{"kind":"story","text":"继续阅读"}]
