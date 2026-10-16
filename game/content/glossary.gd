extends RefCounted
## Player-facing explanations; combat rules and Resources remain the authority.
const TERMS = {
	"代码": ["#f5cf79", "战斗中积攒、用于释放破解程序的资源。分为指令、数据、协议、权限；每色最多6块，战斗结束后不保留。"],
	"指令": ["#ff897f", "红色代码。红色角色每3次有效普攻命中产生1块；命中护盾也算，落空不算。"],
	"数据": ["#76c5ff", "蓝色代码。蓝色角色每3次有效普攻命中产生1块；漏洞研究羁绊成功验证时还可额外产生。"],
	"协议": ["#79e8b1", "绿色代码。绿色角色每3次有效普攻命中产生1块，可用于反冲护盾等程序。"],
	"权限": ["#c699ff", "紫色代码。全队护盾每实际吸收80点伤害产生1块；仅获得护盾、护盾到期或被替换不会产生。"],
	"破解": ["#f5cf79", "玩家主动释放的程序。先积攒配方所需代码，再选择程序、查看效果与目标，点击释放。自动攻击和角色技能会自行执行。"],
	"追踪破解": ["#76c5ff", "消耗3数据和1指令，选择已确认敌人，造成45点原始伤害并使其暴露5秒；暴露期间各友军首次有效普攻可追加追击。"],
	"追踪": ["#76c5ff", "此处指追踪破解的进攻路线：分析挂上漏洞，另一名队友普攻验证，敌人变为已确认后才可释放追踪破解。"],
	"漏洞": ["#76c5ff", "分析技能留下的待验证标记，持续6秒。另一名存活友军有效普攻命中后验证，同一份机会只能使用一次。"],
	"验证": ["#76c5ff", "挂上漏洞后，由另一名友军有效普攻命中，使敌人成为已确认。漏洞研究羁绊还可触发追击和额外数据，受共享冷却限制。"],
	"已确认": ["#76c5ff", "漏洞被队友验证后的状态，持续8秒；这是追踪破解的合法目标条件。"],
	"暴露": ["#ffad81", "追踪破解施加的5秒状态。每名友军首次有效普攻命中该敌人时，追加一次自身攻击倍率为1的追击。"],
	"追击": ["#ffad81", "额外的一次即时伤害，仍会受到防御和护盾影响；不产代码、不触发技能或下一次追击。"],
	"反冲盾": ["#c699ff", "由反冲护盾程序给予的特殊护盾，优先吸收伤害；耗尽或到期时在持有者周围爆炸。普通护盾不会爆炸。"],
	"护盾": ["#79e8b1", "先于生命承受伤害的保护量，有持续时间和总上限。实际吸收会积攒权限代码，普通护盾到期不会造成伤害。"],
	"羁绊": ["#f5cf79", "队伍中满足指定标签人数后生效的协作效果。当前漏洞研究和容错工程都由2人启用；额外同标签角色不会解锁更高档。"]
}

static func markup(value: String, dark_ink: bool = false) -> String:
	var keys := TERMS.keys()
	keys.sort_custom(func(a,b): return a.length() > b.length())
	var result := ""
	var cursor := 0
	while cursor < value.length():
		var found := false
		for term in keys:
			if value.substr(cursor,term.length()) != term: continue
			var tint := Color(TERMS[term][0])
			if dark_ink: tint = tint.darkened(0.48)
			result += "[url=%s][color=#%s][u]%s[/u][/color][/url]" % [term,tint.to_html(false),term]
			cursor += term.length()
			found = true
			break
		if not found:
			result += "[lb]" if value[cursor] == "[" else value[cursor]
			cursor += 1
	return result
