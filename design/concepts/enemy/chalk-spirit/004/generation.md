# 粉笔精灵战斗动画候选 004 修复记录

- 阶段：正式资产候选，待人工评审；未批准、未接入
- 日期：2026-09-15
- 位图修改工具：Codex 内置 ImageGen
- 身份与动作来源：候选 003；003 保留为问题证据，不覆盖
- 可复现处理：`build_candidate.py`
- 本机复现命令：使用包含 Pillow 与 NumPy 的 Python 3 运行 `build_candidate.py`；本工作区的裸 `python` 指向 Python 2.7，不能用于本脚本。

## 问题与修复边界

候选 003 的统一 352×352 画布只统一了贴图容器，没有保证跨图集主体尺度一致。实测移动图集的非透明轮廓高度中位数为 280 px，003 战斗图集约为 210 px；运行时 `stretch=(1,1)`，因此远程／施法进入与返回待机时会发生真实的体型跳变，不是 Godot 额外缩放。

候选 004 仅重做 `combat_sheet_source_rgb.png`：保留 4×4 格、16 帧顺序、远程／施法分组、朝右三分之四视角和角色设计，将每格主体统一放大到移动图集的视觉尺度。待机／移动与受击／濒危／退场继续沿用 003 原始图，不修改正式角色定义、Manifest 或运行时代码。

## ImageGen 最终提示词

类型：`identity-preserve`。

> IMAGE 1 is the exact combat sprite sheet to edit and is the authoritative source for every pose, effect, frame order, orientation, line, color, costume detail, and timing. IMAGE 2 is a scale-only reference for the same character. Preserve the exact 4 columns x 4 rows layout and all 16 combat frames in the same cells and order. Preserve every combat pose and effect exactly: rows 1-2 are ranged attack frames, rows 3-4 are casting/skill frames. Preserve the consistent right-facing three-quarter orientation. Increase only the character subject scale in every cell so the helmet, dark green chalkboard-eraser torso core, white floating limbs, and magenta face match the apparent character size in IMAGE 2. Apply one consistent scale correction across all 16 combat cells. Keep each subject centered and fully inside its cell with safe padding. Do not redesign, redraw, simplify, add, remove, rotate, flip, recolor, add text, labels, borders, guides, checkerboard pixels, scenery, or a background. Output one square PNG sprite sheet with a genuine transparent alpha background. This is a surgical scale-consistency edit, not a new illustration.

ImageGen 实际返回 1254×1254 RGB 棋盘图，生成文件为 `exec-1bf808c2-059e-4fc1-a84a-75d14b11ec2d.png`。因未提供真实 Alpha，按既有确定性流程只移除与画布边缘连通的中性棋盘背景；角色、粉尘与弹体不做二次绘制。

## 文件与哈希

- `locomotion_sheet_source_rgb.png`：`db52be8cb7eabe5898406f7b6983304db0b9014f694f38a07810282744bf6334`（沿用 003）
- `combat_sheet_source_rgb.png`：`af3bbe6589b39ca1467a7fbd971b5ce339c461e4e0b9ff93132a97b0b98412fd`（004 ImageGen 修复源）
- `reaction_sheet_source_rgb.png`：`7535f09106a054342457258a9c306757c8de25e79a1f54bc2a54d86bdab37d57`（沿用 003）
- `locomotion_sheet.png`：`15154f8e56377337a2a2e772cc23057d01942ff1c203d595813b9b145318c1e8`
- `combat_sheet.png`：`5c1c38b269228a82e97f10695059a7bab78fb8e712c48ef18ce40782f0a9bb97`
- `reaction_sheet.png`：`4426f95e712b0c641cdd606df2c2c6120935098fa5c7c14ffa29af8ab91a927e`

## 跨片段 QA 与预览规则

- 自动门槛：移动图集非透明轮廓高度中位数 280 px，战斗图集 290 px，战斗／移动比例 1.0357；允许区间 0.90–1.10。
- 视觉门槛：`review/cross-clip-scale.png` 并排显示待机、远程首／末帧、施法首／末帧，人工核对头盔与黑板擦核心，而不是只看尾迹包围盒。
- `attack-preview.gif` 与 `cast-preview.gif` 是运行时语义预览：待机 2 帧 → 动作 8 帧 → 待机 2 帧。动作帧按默认前摇 0.20 秒、后摇 0.25 秒和出手比例 0.625 反推时长；前 5 帧约 40 ms／帧，后 3 帧约 83 ms／帧。
- `*-frames.gif` 是纯片段逐帧检查，不承担跨状态验收。不得再用动作末帧的额外停留代替“返回待机”预览。
- Godot 独立动作检查：待机、移动、远程、施法、受击、濒危、退场通过；粉笔精灵仅远程，近战入口按元数据正确置灰；`failures=0`。

## 结论

004 已解决本次可量化的跨图集主体尺度问题，并补齐真实状态过渡预览。它仍是待评候选；人工需要重点观察远程／施法进入与返回待机时是否还有可感知的缩放跳变，以及 ImageGen 修复是否引入不能接受的局部绘制差异。
