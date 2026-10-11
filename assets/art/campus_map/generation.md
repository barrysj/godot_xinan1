# 校园地图运行来源

当前全图三态来自 `design/concepts/environments/campus-map/campus-map/asset_006` 的可编辑 Blender 母版，包含西北／西南真实补景、沿原道路延长的外围，以及地面融合、右上角道路衔接和接缝建筑。桌面7680×3600、Web3200×1500；交互核心仍为1800×1500，宽图逻辑原点(-700,0)，逻辑画布3200×1500。使用源包 render.py 渲染，verify_bundle.py 核验自包含工程、尺寸及运行复制一致性；状态见[校园图](../../../docs/art/environments/campus-map.md)及[Manifest](../manifests/m1_campus_map.yaml)。

本目录 full-*.png（1600×1200）和 day／night／anomaly.png（1200×680）仍由旧双路线预览／旧战役组件实际引用，属于保留的兼容运行依赖，不是扩展全图的缩放版本；其投影不同，不能直接替换成新版全图。已删除与 full-* 字节相同的 runtime-sources 重复源，裁切入口 tools/art/campus_map/build_runtime_textures.py 直接读取本目录 full-*。

路线、选区及明暗继续由原 Godot 层维护，不烘焙入图片；本次不改用户布局 JSON。旧 Blender 版本、闲置概念和重复源已按负责人要求从工作区清理，Git 历史不重写。
