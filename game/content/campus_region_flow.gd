@tool
class_name CampusRegionFlow
extends Resource
const Rules = preload("res://game/run/campus_flow_rules.gd")
@export_enum("library", "region_b", "region_c") var id: String = "library"
@export var display_name: String = ""
@export_range(1, 100000, 1) var revision: int = 1
## 数组顺序就是站次，最后一站为终点；1～12 站，每站 1～4 个候选。
@export var stages: Array[CampusRouteStage] = []
@export_enum("region", "prologue", "finale") var usage: String = "region"

func snapshot() -> Dictionary:
	var result := {"schema":1, "region":id, "title":display_name, "revision":revision, "layers":[], "stops":{}, "usage":usage, "map_contract":1}
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/run/expanded_campus_layout.json"))
	if usage == "region":
		for route in layout.routes:
			if route.campaign_region == id: result.title = route.title
	for stage in stages:
		var layer: Array = []
		if stage == null: return {}
		for stop in stage.choices:
			if stop == null or stop.place == null or stop.encounter == null: return {}
			layer.append(stop.id)
			if result.stops.has(stop.id): return {}
			result.stops[stop.id] = {"title":stop.place.display_name, "place_id":stop.place.id,
				"background":stop.place.background_id, "landmark":stop.place.landmark,
				"offset":[stop.place.offset.x, stop.place.offset.y], "library_interior":stop.place.library_interior,
				"map_landmarks":Array(stop.place.map_landmarks), "hotspot_template":stop.hotspot_template, "encounter_id":stop.encounter.id, "power":stop.power}
			if usage == "region":
				var landmarks: Array = stop.place.map_landmarks if not stop.place.map_landmarks.is_empty() else [stop.place.landmark]
				var names: Array[String] = []
				for landmark in landmarks:
					if layout.places.has(landmark): names.append(layout.places[landmark].title)
				if not names.is_empty(): result.stops[stop.id].title = "＋".join(names)
			var scenes: Array = []
			for scene in stop.place.scenes:
				scenes.append(scene.snapshot() if scene != null else {})
			result.stops[stop.id].scenes = scenes
		result.layers.append(layer)
	return result

func validate() -> Array[String]:
	var errors: Array[String] = []
	var ids := {}
	for i in range(stages.size()):
		var stage = stages[i]
		if stage == null:
			errors.append("第 %d 站：未创建站次资源" % (i+1))
			continue
		for j in range(stage.choices.size()):
			var stop = stage.choices[j]
			var prefix := "第 %d 站候选 %d：" % [i+1,j+1]
			if stop == null:
				errors.append(prefix+"未创建探索站点")
				continue
			if ids.has(stop.id): errors.append(prefix+"站点 ID 重复："+stop.id)
			ids[stop.id] = true
			if stop.place == null: errors.append(prefix+"缺少地点引用")
			if stop.encounter == null: errors.append(prefix+"缺少已有敌阵引用")
			elif not Rules.registered_encounter(stop.encounter): errors.append(prefix+"敌阵需引用清单中已登记的资源文件")
	if not errors.is_empty(): return errors
	return Rules.validate_snapshot(snapshot(),id)

func overview() -> String:
	var lines := PackedStringArray()
	for i in range(stages.size()):
		var names := PackedStringArray()
		if stages[i] != null:
			for stop in stages[i].choices:
				names.append(stop.place.display_name if stop != null and stop.place != null else "未配置")
		lines.append("第 %d 站%s：%s" % [i+1,"（终点）" if i == stages.size()-1 else ""," / ".join(names)])
	return "\n↓\n".join(lines)
