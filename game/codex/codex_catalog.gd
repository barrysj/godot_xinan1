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
			for unit in preload("res://game/content/content_db.gd").characters():
				result.append(unit_entry(unit,"战斗同学"))
			for staff in Meta.STAFF:
				result.append({"name":staff.name,"tag":"后勤支援","body":"独立于战斗队伍的支援同学，可派遣到已解锁地点探索。\n\n出发时消耗修复资源；探索按现实时间推进，离线也可完成。领取成果后归队。\n\n"+("解锁后勤扩编后加入。" if staff.requires != "" else "派遣事务所开放后可派遣。"),"icon":staff.portrait})
		1:
			for unit in preload("res://game/content/content_db.gd").MANIFEST.enemies:
				result.append(unit_entry(unit,"校园异变"))
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

static func unit_entry(unit, tag: String) -> Dictionary:
	return {"name":unit.display_name,"tag":tag,"body":unit.description+"\n\n"+unit.skill.display_name+"："+unit.skill.description+"\n每 %d 次普攻触发。\n\n基础生命 %d / 攻击 %d / 防御 %d / 间隔 %.2f 秒" % [unit.skill.attacks_to_trigger,unit.health,unit.attack,unit.defense,unit.interval],"texture":unit.portrait}
