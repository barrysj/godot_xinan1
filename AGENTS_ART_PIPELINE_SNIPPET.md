# 将以下内容合并到项目根目录 AGENTS.md

## 美术实现工作流

本项目视觉方向为 `Cyber Pop Campus`。

普通视觉实现任务默认读取：
1. `docs/art/ART_CONTRACT.md`
2. 当前任务直接相关的一个 Spec
3. `docs/art/asset_manifest.yaml`
4. 必要时读取 `data/visual/` 中相关 Token

不要默认读取完整 `docs/art/STYLE_BIBLE.md`。

只有以下情况允许读取完整美术圣经：建立新视觉系统、引入新场景大类、引入新角色表现体系、重构全局 UI 语言、用户明确要求重新设计视觉方向。

### 资产规则
- 最终视觉资产位于 `assets/art/`。
- 默认只使用 Manifest 中 `status: approved` 的资产。
- 不要擅自重画、替换或重新设计已批准资产。
- Manifest 已包含尺寸、透明、Anchor、裁切等信息时，不要重复视觉分析图片。
- 不要生成新的正式美术资产，除非任务明确要求。

### UI 规则
- 优先复用 Godot Theme、共享组件和 Visual Token。
- 有 Token 时禁止重复硬编码品牌色。
- 优先使用 Container / Anchor 构建响应式布局。
- 至少验证 1920×1080、2560×1440、16:10。

### 工作方式
- 优先修改现有系统，不创建平行实现。
- 需求不明确时，不擅自扩大范围。
- 完成后运行相关 Godot 验证。
- 最终报告保持简洁：修改内容、验证结果、遗留问题。
