# Cyber Pop Campus 美术 → Codex 实现 Pipeline

这套目录用于 AI 驱动的 Godot 2D 游戏开发：

- **ChatGPT 网页版**：游戏设计、美术总监、概念设计、图像资产生成、视觉 QA。
- **Codex**：Godot 工程实现、UI/场景搭建、Shader、动画、数据绑定、验证与修复。
- **人类负责人**：最终审美判断、方向批准、关键取舍。

核心原则：

> 不让 Codex 重新设计美术，只让它实现已经冻结的设计。

## 日常工作流

```text
需求
 ↓
ChatGPT 网页版：设计 + 生成概念/正式资产
 ↓
批准资产
 ↓
更新 asset_manifest.yaml + 对应 Task Spec
 ↓
Codex：只读取 ART_CONTRACT + 对应 Spec + Manifest
 ↓
Codex 实现 Godot
 ↓
运行截图
 ↓
ChatGPT 网页版视觉 QA
 ↓
Codex 只修明确问题
```

## Codex 常规任务最小读取集

1. `docs/art/ART_CONTRACT.md`
2. 当前功能直接相关的一个 Spec
3. `docs/art/asset_manifest.yaml`
4. 必要时读取 `data/visual/` 中相关 Token

普通任务不要默认读取完整 `STYLE_BIBLE.md`。
