# 校园大地图运行时三态

2026-09-28路径整理：下述为仍在用的旧核心区地图，原源PNG已迁至runtime-sources。扩展全图的当前Blender整套在`design/concepts/m1-campus-map/campus-map/asset_001/`，运行图在`expanded_neutral/`；两者不是同一裁切版本。001～053旧目录已删除，历史细节从Git恢复。

032只修改Godot运行时选择表现：`campus_route_focus.gdshader`对源图进行连续区域柔边聚焦，区域来自`campus_route_geometry.gd/AREAS`。原PNG、裁切与锚点不变；未选择时恢复原样采样。此效果未烘焙到任何地图资产，新接入评审见地图任务032。

031路线预览另使用`full-day.png`、`full-night.png`、`full-anomaly.png`：它们是下表三份1600×1200源图的原样复制，并非重新生成。`build_runtime_textures.py`可同步重建。原生地图按(200,260,1200,800)等比显示，包含完整主楼；区域、线条和标签均为Godot叠层，不烘焙进图片。031试接入待评审，原战役底图裁切与批准边界不变。

当前030异常资产及所展示的异常态接入效果已获用户批准（2026-09-22，提交39f4a4d）；日间、夜间不在本次批准范围，三态组合仍为review。三张图使用同一裁切框`(200,260)–(1400,940)`，输出1200×680 RGB PNG，确保日间、夜间、异常状态像素对齐。

| 状态 | 来源 |
| --- | --- |
| day | `design/concepts/m1-campus-map/runtime-sources/core-day.png` |
| night | `design/concepts/m1-campus-map/runtime-sources/core-night.png` |
| anomaly | `design/concepts/m1-campus-map/runtime-sources/core-anomaly.png` |

重建命令（PowerShell 7）：

```powershell
& 'C:/Users/SongJun/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/art/campus_map/build_runtime_textures.py
```

裁切围绕主楼、图书馆、品学楼、立人楼、东湖、时光广场与银杏大道的核心关系。028加强日间光照；030在原14块异常区域基础上加入有效的全局双色照明、建筑窗光／屋檐灯带、局部扩散光晕和水纹高光。校园原几何与相机保持固定。当前路线节点仍是机制示意，不声称已经对应真实地点坐标；其余两个区域和终点身份确认后再做节点落位。夜间资产已导入但尚未绑定剧情时机，避免擅自决定状态切换。
