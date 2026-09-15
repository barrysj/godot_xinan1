@tool
class_name CampusUnit
extends Resource
const ActionProfile = preload("res://game/content/battle_action_profile.gd")
const BattleAnimationSet = preload("res://game/content/battle_animation_set.gd")
const ATTACK_MELEE := 1
const ATTACK_RANGED := 2
const ATTACK_ALL := ATTACK_MELEE | ATTACK_RANGED
## 人物与敌人共用静态定义；战斗实例保存自己的生命、护盾和计数。
@export_group("身份与展示")
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var portrait: Texture2D
@export var battle_animation: BattleAnimationSet
@export var badge_color: Color = Color("69d9bd")
@export_group("战斗属性")
@export_range(1, 10000) var health: int = 200
@export_range(1, 1000) var attack: int = 20
@export_range(0.1, 10, 0.05) var interval: float = 1.5
@export_range(0, 1000) var defense: int = 5
## 射程和移速以逻辑格计；画面投影不改变距离。
@export_range(1, 6, 0.05) var attack_range: float = 1.45
@export_range(0.5, 8, 0.1) var move_speed: float = 2.4
@export var action_profile: ActionProfile
## 预览与未来多攻击入口共用的能力标记；0 兼容旧资源并从当前攻击方式推断。
@export_flags("近战", "远程") var attack_modes: int = 0
@export var skill: CampusSkill

func resolved_attack_modes() -> int:
	if attack_modes != 0:
		return attack_modes & ATTACK_ALL
	if action_profile != null:
		if action_profile.delivery == "melee":
			return ATTACK_MELEE
		if action_profile.delivery == "projectile":
			return ATTACK_RANGED
	return ATTACK_RANGED if attack_range > 1.5 else ATTACK_MELEE
