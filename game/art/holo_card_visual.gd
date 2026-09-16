extends Resource
## Card-specific data; frame, shader and interactions are shared.
@export var photo: Texture2D
@export var title: String = ""
@export var subtitle: String = ""
@export var caption: String = ""
@export var edition: String = ""
@export_range(0.0, 1.0) var foil_strength: float = 0.7
## Zero preserves the original frame-only cards.
@export_range(0.0, 1.0) var photo_foil_strength: float = 0.0
@export_range(0.0, 0.02) var photo_depth: float = 0.004
