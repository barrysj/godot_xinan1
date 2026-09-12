# 推荐目录结构

目录职责与归档边界以 [AGENTS.md 的文档目录与归档规则](../../AGENTS.md#文档目录与归档规则) 为准。普通玩法、交互与实现说明归入 `docs/` 的对应主题文档；`tasks/` 专用于美术实施方案，不用于存放 Codex 自行整理的普通功能需求或开发记录。

```text
project/
├─ AGENTS.md
├─ docs/
│  ├─ game-design.md
│  ├─ battle-demo.md
│  ├─ research/
│  ├─ art/
│  │  ├─ STYLE_BIBLE.md
│  │  ├─ ART_CONTRACT.md
│  │  ├─ CHARACTER_SPEC.md
│  │  ├─ ENVIRONMENT_SPEC.md
│  │  ├─ UI_SPEC.md
│  │  └─ asset_manifest.yaml
│  ├─ pipeline/
│  │  ├─ WORKFLOW.md
│  │  ├─ TOKEN_OPTIMIZATION.md
│  │  └─ ASSET_HANDOFF_CHECKLIST.md
│  └─ prompts/
│     ├─ CHATGPT_ART_PROMPTS.md
│     └─ CODEX_PROMPTS.md
├─ data/visual/
├─ design/references/
├─ design/concepts/
├─ assets/art/
├─ tasks/                     # 美术实施方案（Visual Task Spec）
│  └─ templates/              # 模板与示例，不代表已批准方案
└─ .agents/skills/art-implementation/SKILL.md
```
