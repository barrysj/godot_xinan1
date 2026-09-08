extends RefCounted
const DEFINITIONS = [
	{"id":"badge","title":"厚笔记本","description":"装备者生命上限 +80。\n战前可自由分配。","role":-1},
	{"id":"recruit","title":"招募 · 发明家","description":"新同学加入候补。\n自动技能攻击一整排。","role":-1},
	{"id":"guard_training","title":"坚守训练","description":"守护者本局生命 +50。\n攻击 +5，可叠加。\n不占装备槽。","role":0},
	{"id":"archer_training","title":"专注训练","description":"远射手本局生命 +50。\n攻击 +5，可叠加。\n不占装备槽。","role":1},
	{"id":"healer_training","title":"应援练习","description":"应援者本局生命 +50。\n攻击 +5，可叠加。\n不占装备槽。","role":2},
	{"id":"striker_training","title":"冲刺特训","description":"冲刺手本局生命 +50。\n攻击 +5，可叠加。\n不占装备槽。","role":3},
	{"id":"inventor_training","title":"改良实验","description":"发明家本局生命 +50。\n攻击 +5，可叠加。\n候补也能保留强化。","role":4}
]
static func find(id: String) -> Dictionary:
	for entry in DEFINITIONS:
		if entry.id == id: return entry.duplicate(true)
	return {}
static func eligible(badge_owned: bool, roster: Array) -> Array:
	return DEFINITIONS.filter(func(entry):
		if entry.id == "badge": return not badge_owned
		if entry.id == "recruit": return not roster.has(4)
		return roster.has(entry.role))
