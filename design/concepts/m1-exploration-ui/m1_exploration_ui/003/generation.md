# 概念 003 · 场景优先与按需详情

日期 2026-09-17，基线 0a281bd。用户提供另一任务的图书馆概念作为生成参考，并明确禁止重复纳入该原图。

参考：本任务用户上传 codex-clipboard-c3055ae9-f207-45a2-a06e-0c1ace699e0a.png；未复制、未登记原参考图，也未据此声称真实校园复刻或环境已批准。

背景使用内置 imagegen，单次参考编辑；输出 exec-67856e9a-be97-42d9-9580-7e86aa648351.png 原样复制为 background-study.png。它仅服务本 UI 概念，不是独立正式环境资产。

## 生成提示

Edit the provided campus library concept as a BACKGROUND STUDY ONLY for a review-only exploration game UI. Preserve exact architecture, skylight, atrium floors, orange railings, stair positions, perspective and framing. Transform lighting to an uncanny digitally corrupted campus: slightly dim cool blue ambient light while keeping all architecture readable and recognizable, restrained cyan and violet luminous haze along a few balcony edges, a few short subtle horizontal signal displacement streaks away from central architecture. Keep warm orange railings, neutral pale walls, clear skylight. No new objects, no people, no text, no HUD, no icons, no buttons, no lightning scribbles, no dramatic destruction, no new architecture. Full bleed 16:9. Background must remain the main subject, spacious and detailed. This derivative is a UI concept study, not an approved environment asset.

## UI 与复现

独立 SVG 原生图形层：四热点 52px，位置分散；三个短闪电向守卫收束，移除大范围环状涂鸦。顶部与底部只保留小型悬浮提示。详情默认隐藏，点击后在热点旁显示 310×213 浮窗，保留关闭图标与短按钮。

node render.cjs 用 bundled sharp 渲染矢量层并合成 review-default.png、review-detail.png，均为 1600×900。SHARP_MODULE 可指定其他已安装 sharp 路径。这是审核合成图；正式 UI 须由原生组件或矢量实现，不使用整屏合成图接入。

状态：unselected / pending / not_integrated。原生成图与 UI 分层保存。静态两状态不等于点击交互已实现；未修改主游戏。
