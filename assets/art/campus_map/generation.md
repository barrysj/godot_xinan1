# 校园地图运行来源

当前全图三态来自design/concepts/environments/campus-map/campus-map/asset_001中的可编辑Blender源，桌面5400×4500、Web1800×1500，逻辑坐标1800×1500。源包验证检查模型依赖和输出一致性；[当前范围](../../../docs/art/environments/campus-map.md)与[Manifest](../manifests/m1_campus_map.yaml)维护最终状态。

旧核心区源PNG保留在design/concepts/environments/campus-map/runtime-sources，day／night／anomaly为1200×680裁切；full-*为1600×1200源图副本。它们仍服务旧战役与双路线预览，不是当前扩展全图。处理入口为tools/art/campus_map/build_runtime_textures.py。

路线、选区和明暗均由原Godot层维护，不烘焙进图片。用户布局JSON独立于源图；修改图像投影须复核落点。只保留必要来源与最终使用边界，不保留逐次光照修订和审核过程。
