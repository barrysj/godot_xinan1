@tool
class_name CampusUnit
extends Resource
const BattleAnimationSet = preload("res://game/content/battle_animation_set.gd")
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
@export var skill: CampusSkill
