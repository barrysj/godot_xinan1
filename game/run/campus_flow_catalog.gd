extends RefCounted
const PATHS = {"library":"res://resources/campaign/regions/library.tres", "region_b":"res://resources/campaign/regions/region_b.tres", "region_c":"res://resources/campaign/regions/region_c.tres"}

const SPECIAL = {"prologue":"res://resources/campaign/prologue.tres", "finale":"res://resources/campaign/finale.tres"}

static func definition(region: String, usage: String = "region"):
	if not PATHS.has(region): return null
	if usage in SPECIAL: return load(SPECIAL[usage]) if region == "library" else null
	return load(PATHS[region]) if usage == "region" else null

static func snapshot(region: String, usage: String = "region") -> Dictionary:
	var flow = definition(region,usage)
	if not flow is CampusRegionFlow or flow.id != region or flow.usage != usage: return {}
	var errors: Array[String] = flow.validate()
	if not errors.is_empty():
		push_error("校园区域配置："+"；".join(errors))
		return {}
	return flow.snapshot()
