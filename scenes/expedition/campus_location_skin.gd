extends RefCounted
## Approved 4K campus exteriors. Preview order matches the art task's release list.

const LOCATIONS: Array[Dictionary] = [
	{"id": "south_gate", "label": "南门"},
	{"id": "pinxue_courtyard", "label": "品学楼单区庭院"},
	{"id": "pinxue_atrium", "label": "品学楼组团中庭"},
	{"id": "xuezi_cafeteria", "label": "学子食堂"},
	{"id": "student_activity_center", "label": "学生活动中心"},
	{"id": "west_lake_center", "label": "西湖中心"},
	{"id": "chengdian_auditorium_commercial_street", "label": "成电会堂＋商业街"},
	{"id": "yinhua_halal_cafeterias", "label": "银桦＋清真食堂"},
	{"id": "basic_laboratory_building", "label": "基础实验大楼"},
	{"id": "west_lake_entrance", "label": "西湖入口"},
	{"id": "sports_field", "label": "操场"},
	{"id": "library_front", "label": "图书馆正面"},
]
const STATES: Array[String] = ["daily", "anomaly"]

static func path(location_id: String, state: String) -> String:
	if not STATES.has(state): return ""
	for location in LOCATIONS:
		if location.id == location_id:
			return "res://assets/art/backgrounds/m1_campus_locations/%s/%s.png" % [location_id, state]
	return ""
