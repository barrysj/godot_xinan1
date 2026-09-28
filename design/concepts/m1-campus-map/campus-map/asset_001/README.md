# asset_001 · 校园地图三态整套源文件

- `day.blend`、`night.blend`、`anomaly.blend`：最新可编辑模型，来自历史053，不依赖旧 Blender 或外部纹理／链接模型。
- 同名 PNG：5400×4500 高清底图，与 `assets/art/campus_map/expanded_neutral/` 对应文件完全相同；游戏地点、路线和亮区仍使用 1800×1500 逻辑坐标。
- `runtime-*.png`：此前实际游戏评审截图；`build-*.json`、`*-validation.json`：搬迁前的历史验证证据，里面的053路径是历史信息，不是当前入口。
- 原始DXF／GLB及真实参考见 [参考入口](../../../../references/m1-campus-map/README.md)，旧053施工记录从Git提交0144849恢复。保留授权不等于视觉批准，三态仍为 review。

## 修改与渲染

直接用 Blender 打开需要修改的状态；先另存到同级新 `tmp_###/`，日／夜／异常放在同一个临时目录。保持相机和1800×1500基准画幅的宽高比与坐标不动；改相机或整体投影会影响地点／路线对齐。旧场景可能记录053的输出路径，渲染前必须把 Output 路径改到该 tmp 目录，不能覆盖留存版。

`render_hd.py` 在内存中把画幅设为5400×4500并输出到同级`tmp_001/`，不保存或修改Blend。需要重新生成时，先确认临时目录编号和输出路径，再在项目根使用 PowerShell 7：

```powershell
New-Item -ItemType Directory design/concepts/m1-campus-map/campus-map/tmp_001 -Force
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 0 --python design/concepts/m1-campus-map/campus-map/asset_001/render_hd.py -- --state day
```

候选不会自动覆盖游戏底图或修改 `expanded_campus_layout.json`。阶段收尾确认保留项后，再统一正式命名、复制运行图、更新最小 Manifest、验证和提交；不再执行001～053的历史串行构建链。

只读验证（不渲染、不保存场景、不改布局）：

```powershell
& 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe' -b -t 2 --python-exit-code 1 --python design/concepts/m1-campus-map/campus-map/asset_001/verify_bundle.py
```
