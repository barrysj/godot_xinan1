---
name: art-implementation
description: 按已批准的 Cyber Pop Campus 美术规范，在 Godot 中实现 UI、场景、视觉资源与动效。
---

# Art Implementation Skill

执行视觉实现任务时：
1. 读取 `docs/art/ART_CONTRACT.md`。
2. 读取当前任务明确指定的 UI / Character / Environment Spec。
3. 通过 `docs/art/asset_manifest.yaml` 查资产路径与元数据。
4. 只在需要时读取 `data/visual/` 对应 Token。
5. 不默认读取完整 `STYLE_BIBLE.md`。
6. 不重新设计已批准美术。
7. 不生成替代图片，除非任务明确要求。
8. 优先复用 Godot Theme、共享组件与 Token。
9. 使用 Anchor / Container 构建适配布局。
10. 视觉验证优先检查 1920×1080、2560×1440、16:10。
11. 只有出现实际视觉问题时才使用截图分析。
12. 完成后只报告：修改文件、实现结果、验证结果、未解决问题。

如果任务要求“重新设计”而不是“实现”，停止扩大范围，先要求提供冻结后的视觉 Spec，或由 ChatGPT 网页版先完成设计。
