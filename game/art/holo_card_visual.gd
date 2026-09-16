extends Resource
## Card-specific data; frame, shader and interactions are shared.
@export var photo: Texture2D
@export var title: String = "那年 · 我们"
@export var subtitle: String = "CAMPUS MEMORIES / 校园记忆"
@export var caption: String = "一起走过的日子，仍在这里。"
@export var edition: String = "MEMORY / 001"
@export_range(0.0, 1.0) var foil_strength: float = 0.7
@export_range(0.0, 0.02) var photo_depth: float = 0.004
