# 粉笔精灵轻量弹体 001 正式资产记录

状态：正式资产。用户于 2026-09-15 回复“还不错。采用”，批准轻量弹体 001；候选与评审证据保留在原目录。

## 设计与生成

- 日期：2026-09-15。
- 工具：Codex 内置 ImageGen。
- 身份参考：`chalk-spirit/001/chalk_spirit_concept_001.png`；战斗比例与朝向参考：`chalk-spirit/005/combat_sheet.png`。
- 设计：单枚朝右的断裂白粉笔弹体，左端为炭黑断面，中部仅保留少量青／品红异常裂纹；源图不烘焙尾迹、环境、命中特效或角色。
- 运行目标：约 32×16 逻辑像素；由程序按飞行方向旋转，并在弹体后方绘制三颗递减尾迹点。

生成提示词：

```text
Use case: stylized-concept
Asset type: single lightweight 2D Godot projectile sprite for the Chalk Spirit
Input images: Image 1 is the authoritative character identity, material, palette, and rendering-style reference; Image 2 is the authoritative in-game combat sprite style and right-facing orientation reference.
Scene/backdrop: genuine transparent alpha background
Subject: exactly one short broken white classroom chalk projectile, flying horizontally to the right. It should look like a compact chalk slug cut from the same white chalk material as the character, with one dark charcoal broken end and only tiny cyan and magenta anomaly cracks near the middle.
Style/medium: clean hand-painted 2D game sprite matching the references, strong readable silhouette, crisp dark outline, restrained texture, suitable for downscaling to approximately 30 by 18 logical pixels.
Composition/framing: one object only, centered, horizontal side view, nose pointing right, generous transparent padding on all sides. No rotation in the source; runtime will rotate it along the trajectory.
Lighting/mood: same soft top-left lighting as the reference character.
Color palette: chalk white and warm pale gray, charcoal broken end, very small cyan and magenta accents.
Constraints: a single isolated projectile; no character; no hands; no muzzle; no environment; no separate debris; no motion trail; no glow cloud; no impact burst; no text; no symbols; no border; no watermark; no checkerboard pixels. Preserve a simple silhouette that remains recognizable at very small size. Output one square PNG with real transparency.
```

## 确定性处理

`design/concepts/chalk-spirit/chalk-projectile/001/build_projectile.py` 读取同候选目录的 `projectile_source_rgba.png`，将 alpha 小于 8 的生成噪点清零，按非透明包围盒裁切，再保持原横纵比缩放到 192×96 透明画布。有效内容为 164×64，运行显示尺寸为 32×16；脚本同时重建候选 `.tres`、元数据和静态尺寸预览。

- 原始图：1254×1254 RGBA；有效包围盒 `[370, 518, 898, 724]`。
- 原始 SHA-256：`d279a2797bd9271f70fe3d5b82c0cb0a62f456b5ad1d360fd9c7db25cc316046`。
- 输出 SHA-256：`007a244cdc3887d93322188f9f03a103f9ae5de934630c5c01c1063fd5a87820`。
- 运行资源：`resources/content/animations/chalk_projectile.tres`，锚点 `[0.5, 0.5]`，尾迹间距 2 逻辑像素。
- 正式运行资源 SHA-256：`a6d9adaac60e654bcad964285928575af7876177a1fb185ccb5b39e3ea587c86`。

## 评审入口

- 单体与实际尺寸：[projectile-preview.png](review/projectile-preview.png)。
- 真实战斗渲染：[远程 1920×1080](review/motion-preview-3-1920x1080.png)、[2560×1440](review/motion-preview-3-2560x1440.png)、[1920×1200](review/motion-preview-3-1920x1200.png)。
- 预览命令：`pwsh.exe -File ./run-motion-preview.ps1 -Unit 'res://resources/content/enemies/chalk.tres' -Animation 'res://design/concepts/chalk-spirit/chalk-spirit/005/battle_animation.tres' -Projectile 'res://design/concepts/chalk-spirit/chalk-projectile/001/chalk_projectile.tres'`。

资产已获批准；接入后的实际战斗效果仍需负责人按运行截图单独验收。
