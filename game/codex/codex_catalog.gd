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
			for place in preload("res://game/content/content_db.gd").MANIFEST.locations:
				result.append({"name":place.display_name,"tag":"局内路线","body":place.description})
			for place in Meta.LOCATIONS:
				result.append({"name":place.name,"tag":"局外派遣地点","body":place.description+"\n\n出发消耗：%d 修复资源\n探索时长：%d 秒（现实时间）\n完成收益：%d 修复资源\n\n在校园成长中解锁后即可派遣；与局内路线进度独立。" % [place.cost,place.duration,place.reward]})
		4:
			for event in preload("res://game/content/content_db.gd").MANIFEST.events:
				var body = event.description
				for option in event.options: body += "\n\n"+option.text+"\n"+option.description
				result.append({"name":event.display_name,"tag":"校园事件","body":body,"texture":event.image})
			result.append({"name":"三选一构筑奖励","tag":"奖励规则","body":"从地点的奖励池抽取三项不同奖励。已持有装备和已招募同学不会重复出现。训练每级生命 +50、攻击 +5。待领奖励随存档保存。"})
	return result

static func unit_entry(unit, tag: String) -> Dictionary:
	return {"name":unit.display_name,"tag":tag,"body":unit.description+"\n\n"+unit.skill.display_name+"："+unit.skill.description+"\n每 %d 次普攻触发。\n\n基础生命 %d / 攻击 %d / 防御 %d / 间隔 %.2f 秒" % [unit.skill.attacks_to_trigger,unit.health,unit.attack,unit.defense,unit.interval],"texture":unit.portrait}
