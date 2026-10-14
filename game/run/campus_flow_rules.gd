extends RefCounted
const Manifest = preload("res://resources/content/manifest.tres")
const LocationSkin = preload("res://scenes/expedition/campus_location_skin.gd")
const TEMPLATES = ["gate","walk","court","hall","library","end_b","end_c"]
const REGIONS = ["library","region_b","region_c"]

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and int(value) == value and value >= minimum and value <= maximum

static func _identifier(value: Variant) -> bool:
	if not value is String or value.length() > 64: return false
	var pattern := RegEx.new()
	pattern.compile("^[a-z][a-z0-9_]*$")
	return pattern.search(value) != null

static func registered_encounter(encounter: Resource) -> bool:
	if encounter == null or encounter.resource_path.is_empty(): return false
	for known in Manifest.encounters:
		if known != null and known.id == encounter.id and known.resource_path == encounter.resource_path: return true
	return false

static func validate_snapshot(value: Variant, region: String) -> Array[String]:
	var errors: Array[String] = []
	if not value is Dictionary: return ["流程快照格式无效"]
	if value.get("schema") != 1 or value.get("region") != region or region not in REGIONS: return ["区域 ID 或流程版本无效"]
	if value.has("map_contract") and value.map_contract != 1: errors.append("地图配置契约无效")
	if value.has("usage") and value.usage not in ["region","prologue","finale"]: errors.append("流程用途无效")
	if not value.get("title") is String or value.title.strip_edges().is_empty(): errors.append("区域名称为空")
	if not _integer(value.get("revision"),1,100000): errors.append("修订号无效")
	if not value.get("layers") is Array or value.layers.is_empty() or value.layers.size() > 12: return ["流程需配置 1～12 站"]
	if not value.get("stops") is Dictionary: return ["探索站点定义无效"]
	var backgrounds: Array = []
	for entry in LocationSkin.LOCATIONS: backgrounds.append(entry.id)
	var encounters: Array = []
	for entry in Manifest.encounters:
		if entry != null: encounters.append(entry.id)
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/run/expanded_campus_layout.json"))
	var landmarks: Dictionary = layout.get("places",{}) if layout is Dictionary else {}
	var used := {}
	for i in range(value.layers.size()):
		var layer = value.layers[i]
		if not layer is Array or layer.is_empty() or layer.size() > 4:
			errors.append("第 %d 站需有 1～4 个候选" % (i+1))
			continue
		for id in layer:
			if not _identifier(id) or used.has(id):
				errors.append("站点 ID 无效或重复："+str(id))
				continue
			used[id] = true
			var stop: Variant = value.stops.get(id)
			if not stop is Dictionary:
				errors.append("站点缺少定义："+id)
				continue
			if not stop.get("title") is String or stop.title.strip_edges().is_empty() or not _identifier(stop.get("place_id")): errors.append(id+"：地点名称或 ID 无效")
			if stop.get("background") not in backgrounds: errors.append(id+"：未引用已有地点背景")
			if not stop.get("landmark") is String or not landmarks.has(stop.landmark): errors.append(id+"：地图地标不存在")
			var offset: Variant = stop.get("offset")
			if not offset is Array or offset.size() != 2:
				errors.append(id+"：地图偏移无效")
			else:
				var valid_offset := true
				for axis in offset:
					if not (axis is float or axis is int) or not is_finite(float(axis)) or absf(float(axis)) > 1800: valid_offset = false
				if not valid_offset:
					errors.append(id+"：地图偏移越界")
				elif landmarks.has(stop.get("landmark")):
					var anchor: Array = landmarks[stop.landmark].point
					var size: Array = layout.size
					if anchor[0]+offset[0] < 0 or anchor[0]+offset[0] > size[0] or anchor[1]+offset[1] < 0 or anchor[1]+offset[1] > size[1]: errors.append(id+"：地点落在地图外")
			if not stop.get("library_interior") is bool: errors.append(id+"：室内标记无效")
			for error in preload("res://game/run/place_scenes.gd").validate(stop.get("scenes",[])): errors.append(id+"："+error)
			if stop.get("hotspot_template") not in TEMPLATES: errors.append(id+"：热点模板无效")
			if stop.get("encounter_id") not in encounters: errors.append(id+"：敌阵未注册")
			var power: Variant = stop.get("power")
			if not (power is float or power is int) or not is_finite(float(power)) or power < 0.1 or power > 3: errors.append(id+"：战斗强度需为 0.1～3")
	if used.size() != value.stops.size(): errors.append("存在未被站次引用的站点")
	# Old frozen journeys omit this marker. Fresh authored flows must match the editor.
	if value.get("map_contract",0) == 1:
		var usage: String = str(value.get("usage","region"))
		if usage not in ["region","prologue","finale"]: errors.append("流程用途无效")
		var mapped := {}
		for stop in value.stops.values():
			if not stop is Dictionary: continue
			if usage != "prologue" and stop.get("place_id") == "south_gate": errors.append("南门仅用于教学，不得加入正式路线或终局")
			var components: Variant = stop.get("map_landmarks",[])
			if not components is Array or components.size() > 4:
				errors.append("地图地标组件无效")
				continue
			var ids: Array = [stop.get("landmark","")] if components.is_empty() else components
			for landmark in ids:
				if not landmark is String or not landmarks.has(landmark): errors.append("地图地标组件不存在："+str(landmark))
				mapped[landmark] = true
		if usage == "region":
			var expected := {}
			var matching := 0
			for route in layout.get("routes",[]):
				if route.campaign_region != region: continue
				matching += 1
				for landmark in route.places: expected[landmark] = true
			if matching != 1: errors.append("地图编辑器需为每个战役区域配置唯一选区")
			for landmark in mapped:
				if not expected.has(landmark): errors.append("探索地点不属于地图选区："+str(landmark))
			for landmark in expected:
				if not mapped.has(landmark): errors.append("关联地标缺少探索站点："+str(landmark))
	return errors
