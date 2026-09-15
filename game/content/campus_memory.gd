extends Resource
## Real photographs are supplied by the owner; an empty texture stays explicit.
@export var id = "library_photo"
@export var place = "library"
@export var title = "图书馆照片〔待提供〕"
@export_multiline var description = "尚未提供真实照片与共同经历。"
@export var photograph: Texture2D
@export var source_note = "待用户提供"
