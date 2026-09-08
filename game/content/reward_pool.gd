@tool
class_name CampusRewardPool
extends Resource
@export var id: String = ""
## 等权、不重复抽取三项。请至少提供四位初始同学可重复领取的训练奖励。
@export var rewards: Array[CampusReward] = []
