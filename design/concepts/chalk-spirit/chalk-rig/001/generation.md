# 粉笔精灵分层骨骼原型 001

状态：待人工评审的抛弃式技术原型。它不替换已批准的角色动画 005，不写入正式资源或 Manifest。

## 验证问题

验证“固定角色部件 + Godot `Bone2D` 连续插值”能否减少逐帧重绘造成的主体宽高、朝向和锚点漂移，并把粉尘、弹体从主体尺寸中分离。范围只覆盖待机与远程攻击的待机 → 前摇 → 出手 → 收招，不尝试补齐七类正式动作。

## 资产来源与做法

- 唯一角色来源是已批准的 `assets/art/characters/chalk_spirit/locomotion_sheet.png` 待机第 1 帧，源 SHA-256 为 `15154f8e56377337a2a2e772cc23057d01942ff1c203d595813b9b145318c1e8`；没有重新生成或重绘角色。
- `build_parts.py` 在 384×384、脚底 `[192, 336]` 的统一画布内确定性切出主体、发射臂、两块浮游石和单颗粉尘；切层与枢轴写入 `rig_manifest.json`。
- Godot 原型构建 `Skeleton2D`，以主体骨骼为根，发射臂与两块浮游石使用独立 `Bone2D`。粉尘和已批准的弹体 001 是非骨骼独立层。
- 左侧仍运行正式 005 的 `BattleAnimation`，右侧对同一组固定部件做连续变换，便于在同一时钟下比较。

## 迭代记录

第一次切层用过宽多边形包住发射臂，连带切入脸侧阴影；发射骨旋转后出现黑紫裂口。修复方法不是缩放整帧，而是收紧发射臂遮罩，并在主体保留肩部覆盖片，再降低关节平移和旋转幅度。这个案例说明骨骼方案消除了逐帧体型漂移，但不会自动解决错误分层：关节、遮挡关系和可变形区域仍需一次人工设计。

## 结果与边界

- 主体始终复用同一张像素内容，四阶段不会出现横向变胖、纵向变矮或朝向突变；调节时序与动作幅度不需要重新生成图片。
- 粉尘与弹体不参与主体包围盒，可独立改变数量、寿命和速度，不再干扰主体尺度验收。
- 首次成本从“写更精确提示词”转移为“准备干净分层、枢轴和遮挡片”。对于大量复用待机、移动、前摇、后坐的角色，这个成本会被后续动作摊薄。
- 这是刚性切片骨骼，不含网格蒙皮。大幅透视变化、转身、倒地、形变和新的背面信息仍需替换部件或关键姿势；不建议强行用一个待机切片承担全部正式动作。
- 推荐正式生产采用混合流程：骨骼负责稳定循环和轻量动作，少量人工批准的关键姿势负责出手、受击和死亡，再在关键姿势内部使用骨骼与独立特效补间。

## 运行与证据

PowerShell 7 执行：

```powershell
pwsh.exe -File .\run-chalk-rig-prototype.ps1
pwsh.exe -File .\run-chalk-rig-prototype.ps1 -Check
pwsh.exe -File .\run-chalk-rig-prototype.ps1 -Capture
```

`-Capture` 由 Godot 输出四个阶段、三种分辨率和 40 帧连续画面，再由带 Pillow 的 Python 生成 `review/rig-preview.gif` 与 `review/rig-state-contact-sheet.png`。若 Codex 捆绑 Python 不在默认位置，使用 `-PythonPath` 指向安装了 Pillow 的 Python 3。

评审入口：

- `review/rig-preview.gif`：连续时序对比。
- `review/rig-state-contact-sheet.png`：待机、前摇、出手、收招总览。
- `review/rest-comparison.png`：原始待机与分层重组静态对比。
- `review/component-map.png`：源图连通区域检查。
