extends RefCounted
## Add unlocks, staff and locations here; rules do not depend on UI node names.
const UNLOCKS = [
	{"id":"supply", "name":"出发补给", "costs":[3], "requires":"", "description":"新探索可带厚笔记本：装备者生命 +80。"},
	{"id":"fitness", "name":"基础体能", "costs":[4,6,8], "requires":"", "description":"每级使新探索的全队生命 +20。"},
	{"id":"dispatch", "name":"派遣事务所", "costs":[3], "requires":"", "description":"开启人员派遣与图书馆探索。"},
	{"id":"gym", "name":"体育馆通行证", "costs":[4], "requires":"dispatch", "description":"开放体育馆派遣地点。"},
	{"id":"staffing", "name":"后勤扩编", "costs":[6], "requires":"dispatch", "description":"新增支援同学，并行派遣增至 2 队。"}
]
const STAFF = [
	{"id":"archivist", "name":"档案员 · 小林", "requires":"", "portrait":2},
	{"id":"liaison", "name":"联络员 · 小夏", "requires":"", "portrait":1},
	{"id":"technician", "name":"器材员 · 小禾", "requires":"staffing", "portrait":4}
]
const LOCATIONS = [
	{"id":"library", "name":"旧图书馆", "map_position":Vector2(330,260), "requires":"dispatch", "cost":2, "duration":60, "reward":4, "description":"整理遗落档案，找回修复材料。"},
	{"id":"gym", "name":"体育馆仓库", "map_position":Vector2(860,420), "requires":"gym", "cost":4, "duration":120, "reward":7, "description":"回收器材与工具，支援校园修复。"}
]
static func find(items: Array, id: String) -> Dictionary:
	for item in items:
		if item.id == id: return item
	return {}
