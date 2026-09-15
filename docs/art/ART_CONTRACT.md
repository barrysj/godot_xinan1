# Cyber Pop Campus 美术执行契约

美术任务从 [WORKFLOW.md](WORKFLOW.md) 开始。本契约负责资料分工与执行约束，不复制整份视觉规范。

当前方向沿用 v0.3：**清爽理工校园 × 轻数字美术 × 局部赛博强化**。本轮文档整理不改变已确定的风格、角色比例或 Token 数值。

## 资料职责

| 资料 | 唯一维护的内容 | 何时读取 |
| --- | --- | --- |
| [STYLE_BIBLE.md](STYLE_BIBLE.md) | 总体视觉目标、风格禁区、状态强度、配色用法、光影与 VFX | 设计概念、新视觉类别或需要核对总方向时 |
| [CHARACTER_SPEC.md](specs/CHARACTER_SPEC.md) | 角色比例、身份连续性、服装、表情与角色交付细则 | 人物设计、生成或修改 |
| [ENVIRONMENT_SPEC.md](specs/ENVIRONMENT_SPEC.md) | 校园空间、专业识别点、场景状态与分层交付 | 场景设计、生成或修改 |
| [UI_SPEC.md](specs/UI_SPEC.md) | 页面与组件视觉、排版、交互呈现与适配 | UI 设计或实现 |
| [data/visual/](../../data/visual) | colors：具体色值；typography：字体角色与字重；spacing：间距；animation：动效参数 | 只读本次涉及的 Token |
| [asset_manifest.yaml](../../assets/art/asset_manifest.yaml) 与 `assets/art/manifests/` | 受管对象、生产版本、文件哈希、选择、批准、预览、关系与真实生效绑定 | 生成、查找、登记、替换或接入资产 |
| [美术工作流](WORKFLOW.md) | 生产阶段、人工评审、资产检查、网页版备选与归档 | 推进阶段或交付时 |
| [美术任务模板](tasks/templates/VISUAL_TASK_SPEC_TEMPLATE.md) | 单项任务目标、选定版本、实施要求和评审记录 | 有具体美术任务时填写，不视为已批准 |

不同资料按职责互补。实际文件属性须验证后登记，不用提示词中的目标尺寸冒充实测值；精确视觉参数以 Token 为准。若批准稿与正式规范发生实质冲突，说明冲突并请负责人决定，不按文件版本号猜测优先级。

## 执行约束

- Codex 可在用户任务范围和当前方向内设计、生成、处理及接入美术；人工批准遵循工作流，AI 自检不替代评审。
- 复用现有批准资产和身份参考；替换或改变已批准设计须属于明确授权范围。读取规范本身不构成重设计授权。
- 复用现有 Godot Theme、共享组件、Token 和动画工具，不创建平行 UI、色板或资源体系，不做无关重构。
- 生图、图像编辑使用可用的 imagegen 能力；简单形状与已有矢量组件继续使用原生实现。只承诺实际可用的能力，不保证未验证的模型版本、输出尺寸或透明度。
- 资料读取方式由[项目美术技能](../../.agents/skills/art-implementation/SKILL.md)维护；普通修复不扫描全套规范和历史图片。

## 目录与运行时数据边界

美术文档集中在本目录，按用途查找：

```text
docs/art/
  WORKFLOW.md          # 美术主入口：制作与评审
  ART_CONTRACT.md       # 职责与执行约束
  STYLE_BIBLE.md        # 总方向
  specs/               # 角色、场景、UI 细则
  prompts/             # 美术任务提示词
  tasks/               # 具体美术任务与阶段评审
    templates/         # 未批准的填写模板
```

[data/visual/](../../data/visual) 是视觉参数的数据源，不是文档附件。`colors.json` 已由战斗详情界面读取，`animation.json` 已由部署界面读取；`typography.json` 和 `spacing.json` 当前用于规范参数，尚未统一映射到运行时 Theme。四份数据按同一用途留在数据层，不搬入 `docs/`，不为目录整理扩大为 Theme 重构。

正式图片、主索引及对象清单留在 [assets/art/](../../assets/art)。清单内路径统一相对项目根目录，不相对清单自身；它是生产管理权威入口，但尚未被游戏运行时直接读取。目录只保存文件，不决定对象归属或版本状态；参考与候选留在 [design/](../../design)。战斗动画的引擎资源、出手时序和验证入口见[战斗动画接入](../battle-animation.md)，不归入纯美术规范。
