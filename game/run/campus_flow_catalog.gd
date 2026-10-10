extends RefCounted
const PATHS = {"library":"res://resources/campaign/regions/library.tres", "region_b":"res://resources/campaign/regions/region_b.tres", "region_c":"res://resources/campaign/regions/region_c.tres"}

static func definition(region: String):
	return load(PATHS[region]) if PATHS.has(region) else null

static func snapshot(region: String) -> Dictionary:
	var flow = definition(region)
	if not flow is CampusRegionFlow: return {}
	var errors: Array[String] = flow.validate()
	if not errors.is_empty():
		push_error("校园区域配置："+"；".join(errors))
		return {}
	return flow.snapshot()
