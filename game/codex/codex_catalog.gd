extends RefCounted
## Read-only guide; all entries are visible in this prototype.
const Battle = preload("res://scenes/battle_demo/battle_demo.gd")
const Run = preload("res://game/run/short_run.gd")
const Meta = preload("res://game/meta/meta_catalog.gd")
const CATEGORIES = ["人物","敌人","道具","地点","事件"]

static func entries(category: int) -> Array:
	var result: Array = []
	match category:
		0:
			var notes = ["适合前排承伤，站在队友身边提供保护。","适合后排输出，优先处理敌方后排。","自动治疗，建议放在受保护的位置。","追击残血目标，帮助队伍完成击杀。","通过局内奖励招募，可从候补换上场。"]
			for i in range(Battle.ROLES.size()):
				result.append({"name":Battle.ROLES[i],"tag":"战斗同学","body":notes[i]+"\n\n自动技能\n"+Battle.SKILLS[i]+"。\n\n每 3 次普攻自动触发技能。胜利后全队恢复全部状态。","icon":i})
			for staff in Meta.STAFF:
				result.append({"name":staff.name,"tag":"后勤支援","body":"独立于战斗队伍的支援同学，可派遣到已解锁地点探索。\n\n出发时消耗修复资源；探索按现实时间推进，离线也可完成。领取成果后归队。\n\n"+("解锁后勤扩编后加入。" if staff.requires != "" else "派遣事务所开放后可派遣。"),"icon":staff.portrait})
		1:
			var names = ["纸甲守卫","巡游课桌","回声广播","飞页投手","错位黑板","粉笔精灵","粉笔巨像"]
			var roles = [0,3,2,1,4,1,4]
			for i in range(names.size()):
				result.append({"name":names[i],"tag":"终点首领" if i == 6 else "校园异变","body":"战斗方式\n"+Battle.SKILLS[roles[i]]+"。\n\n应对建议\n"+["保护己方后排，集中输出突破前排。","留意残血同学，利用护盾与治疗保护他们。","优先打击治疗者，避免战斗被拖长。","保护己方后排，避免脆弱角色独自承伤。","分散站位，减少整排技能同时命中。","注意后排压力，及时调整装备与站位。","终点的强化敌人。利用本局装备和训练，分散站位迎战。"][i]+"\n\n实际生命与攻击随路线地点强度变化。","icon":roles[i]})
		2:
			for item in preload("res://game/content/content_db.gd").MANIFEST.equipment:
				result.append({"name":item.display_name,"tag":"装备 · 每人一件","body":item.description,"texture":item.icon})
			result.append({"name":"修复资源","tag":"成长资源","body":"完成地点积累，通关后带回基地。用于成长与派遣。"})
		3:
			for stage in Run.STAGES:
				for place in stage:
					result.append({"name":place.name,"tag":"局内路线 · "+{"battle":"战斗","elite":"精英","event":"事件","boss":"首领"}[place.kind],"body":place.description+"\n\n每层只选择一个地点。胜利恢复全部状态，失败可以无限重试。"})
			for place in Meta.LOCATIONS:
				result.append({"name":place.name,"tag":"局外派遣地点","body":place.description+"\n\n出发消耗：%d 修复资源\n探索时长：%d 秒（现实时间）\n完成收益：%d 修复资源\n\n在校园成长中解锁后即可派遣；与局内路线进度独立。" % [place.cost,place.duration,place.reward]})
		4:
			result = [
				{"name":"图书角 · 旧借阅册","tag":"补给事件","body":"翻开旧借阅册，发现同学留下的补给。\n\n不需要战斗，点击收下心意后选择一份构筑奖励，继续探索。"},
				{"name":"同学补给站 · 出发整备","tag":"补给事件","body":"探索途中的整备机会。\n\n不需要战斗，从装备、训练或招募中选择一份奖励，为最终战斗做准备。"},
				{"name":"三选一构筑奖励","tag":"奖励规则","body":"战斗胜利或补给事件后，从随机抽出的三项不同奖励中选择一项。\n\n装备：未拥有的厚笔记本。\n招募：尚未加入的发明家。\n训练：已加入同学的本局生命 +50、攻击 +5，五种角色各有训练。\n\n训练可叠加，仅本局有效。读档和重试不会刷新当前奖励。"}]
	return result
