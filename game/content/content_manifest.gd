@tool
class_name CampusManifest
extends Resource
## 导出时随资源引用打包；文件存在不代表已经注册。
@export var equipment: Array[CampusEquipment] = []
