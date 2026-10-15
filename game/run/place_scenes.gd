extends RefCounted
## Shared scene interpretation for authoring, checkpoints and the original visit UI.
const LocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")
const ExplorationSkin = preload("res://scenes/expedition/exploration_skin.gd")
const PlatformPaths = preload("res://game/visual/platform_asset_paths.gd")

static func entries(stop: Dictionary) -> Array:
	var configured: Array = stop.get("scenes", [])
	if not configured.is_empty(): return configured
	var path := LocationSkin.path(str(stop.get("background","south_gate")),"anomaly")
	if stop.get("library_interior",false): path = ExplorationSkin.library_environment_path("anomaly","atrium-down")
	return [{"id":"default", "title":str(stop.get("title","地点")), "background":path, "position":[0.5,0.5], "floor":0}]

static func find(stop: Dictionary, id: String) -> Dictionary:
	for scene in entries(stop):
		if scene.id == id: return scene
	return {}

static func path(scene: Dictionary) -> String:
	return PlatformPaths.resolve(str(scene.background))

static func floor_label(floor_index: int) -> String:
	if floor_index == 0: return "地面"
	return "地下 %d 层" % absi(floor_index) if floor_index < 0 else "%d 层" % floor_index

static func validate(value: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not value is Array or value.size() > 12: return ["场景需为数组且最多 12 项"]
	var ids := {}
	var occupied := {}
	var pattern := RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]{0,63}$")
	for scene in value:
		if not scene is Dictionary:
			errors.append("场景定义无效")
			continue
		var id: Variant = scene.get("id")
		if scene.has("layout"):
			var layout: Variant = scene.layout
			if not layout is Dictionary or not layout.has("passage"):
				errors.append("场景布局需要 passage 通道标记")
			else:
				for key in layout:
					var point_value: Variant = layout[key]
					if key not in ["memory","person","system","battle","passage"]:
						errors.append("未知布局标记："+str(key))
					if not point_value is Array or point_value.size() != 2:
						errors.append("布局标记坐标无效")
						continue
					for axis in point_value:
						if not (axis is int or axis is float) or not is_finite(float(axis)) or axis < 0 or axis > 1:
							errors.append("布局标记必须位于背景画布内")
		if not id is String or pattern.search(id) == null or ids.has(id): errors.append("场景 ID 无效或重复")
		else: ids[id] = true
		if not scene.get("title") is String or scene.title.strip_edges().length() < 2 or scene.title.length() > 6: errors.append("场景名称需为 2～6 字")
		var background: Variant = scene.get("background")
		if not background is String or not background.begins_with("res://assets/"):
			errors.append("场景需引用 assets 内已有纹理")
		else:
			var resolved := PlatformPaths.resolve(background)
			if not ResourceLoader.exists(resolved,"Texture2D"): errors.append("场景需引用 assets 内已有纹理")
		var floor_index: Variant = scene.get("floor")
		if not (floor_index is int or floor_index is float) or not is_finite(float(floor_index)) or int(floor_index) != floor_index or floor_index < -3 or floor_index > 12: errors.append("场景楼层需为 -3～12 的整数")
		var point: Variant = scene.get("position")
		if not point is Array or point.size() != 2:
			errors.append("场景相对位置无效")
			continue
		var valid := true
		for axis in point:
			if not (axis is float or axis is int) or not is_finite(float(axis)) or axis < 0 or axis > 1: valid = false
		if not valid:
			errors.append("场景相对位置需在 0～1 内")
			continue
		var key := "%s/%s/%s" % [floor_index,point[0],point[1]]
		if occupied.has(key): errors.append("同层场景位置不能重合")
		occupied[key] = true
	if not value.is_empty() and value.all(func(scene): return scene is Dictionary and scene.get("layout") is Dictionary):
		for kind in ["memory","person","system","battle"]:
			if not value.any(func(scene): return scene.layout.has(kind)):
				errors.append("地点布局缺少可到达的热点："+kind)
	return errors
