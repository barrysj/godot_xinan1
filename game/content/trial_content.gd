@tool
class_name CampusTrialContent
extends Resource
@export var characters: Array[CampusTrialCharacter] = []
@export var synergies: Array[CampusSynergy] = []
@export var rewards: Array[CampusTrialReward] = []
@export var encounters: Array[CampusTrialEncounter] = []
@export var hack_goal: int = 100
@export var skill_progress: int = 4
@export var verification_progress: int = 16
@export var vulnerability_duration: float = 4.0
