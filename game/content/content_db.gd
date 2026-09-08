extends RefCounted
const MANIFEST = preload("res://resources/content/manifest.tres")

static func gear(id: String):
	for item in MANIFEST.equipment:
		if item != null and item.id == id: return item
	return null

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var ids = {}
	for item in MANIFEST.equipment:
		if item == null:
			errors.append("manifest: 装备引用为空")
			continue
		var location = item.resource_path
		if item.id.is_empty() or ids.has(item.id): errors.append(location+": 空 ID 或重复 ID: "+item.id)
		ids[item.id] = true
		if item.display_name.is_empty(): errors.append(location+": 名称为空")
		if item.health_bonus < 0 or item.health_bonus > 10000 or item.attack_bonus < 0 or item.attack_bonus > 1000 or not is_finite(item.interval_multiplier) or item.interval_multiplier < 0.1 or item.interval_multiplier > 3:
			errors.append(location+": 装备数值越界")
	return errors
