# 美术任务：粉笔精灵分层骨骼试验

状态：资产 006 已批准并完成正式归档，Godot 接入待实施与评审。此任务验证并引入骨骼＋序列帧混合生产方法；轻量弹体 001 的已批准状态不变。

## 目标与范围

- 目标：用实际运行画面比较完整序列帧与分层刚性骨骼在主体一致性、过渡连续性和后续调参成本上的差异。
- 范围：粉笔精灵待机与远程攻击；待机、前摇、出手、收招四阶段；粉尘和弹体独立控制。
- 非目标：替换正式资源、补齐七类动作、制作网格蒙皮，或用单个待机姿势模拟转身、倒地等新视角。

## 候选与评审

- 候选 001：[生成与验证记录](../../../design/concepts/chalk-spirit/chalk-rig/001/generation.md)。角色部件来自已批准 005 的待机帧，程序生成 `Skeleton2D` / `Bone2D` 层级。
- 候选 001 评审：需修改。负责人于 2026-09-15 指出“预览的攻击动画，出手动作不是很明显”，并要求查看其他动作；同时认为原序列帧死亡动画很好。
- 候选 002：[生成与验证记录](../../../design/concepts/chalk-spirit/chalk-rig/002/generation.md)。远程强化前摇、快速出手、枪口光和后坐；新增移动、施法、受击与濒危骨骼动作，死亡明确保留正式 005 序列帧。
- 候选 002 评审：需修改。负责人于 2026-09-15 指出远程出手把主体推向前方，方向应为向后后坐；施法单色圆球表现粗糙。
- 候选 003：[生成与验证记录](../../../design/concepts/chalk-spirit/chalk-rig/003/generation.md)。远程改为前倾架枪、主体向左后坐、抬枪与浮游石惯性；施法改为青紫双环法阵、菱形核心、光晕与八颗旋转粉尘。
- 候选 003 运行反馈：负责人于 2026-09-15 在游戏内统一预览中发现骨骼拆件边缘呈水波纹，并报告叶骨骼无法自动计算长度和角度的警告。确认原因为骨骼场景继承像素战斗场景的最近邻采样，以及刚性枢轴误用 `Bone2D` 默认自动骨长计算；现改为线性 mipmap 采样，并为四根枢轴骨显式关闭自动计算。
- 候选 003 资产评审：负责人于 2026-09-16 回复“是的，批准成为正式资产”。该候选以新稳定版本 `asset_006` 登记，不能复用历史上已拒绝的 `asset_003`。
- 当前结论：资产 006 已批准并选用；已整理为 `assets/art/characters/chalk_spirit/006/` 下的自包含快照，包含骨骼拆件、正式 005 的序列帧回退、构建元数据和保存的 GIF。
- 批准边界：本次决定只批准正式资产，不等于批准游戏接入效果。在 Godot 实际接入、三分辨率截图和人工复核完成前，Manifest 的 `integration.active_variant` 继续指向 `asset_005`。

## 验证证据

- 候选 001 自检：4 个骨骼层、10 个独立粉尘实例、正式 005 序列帧对照和独立弹体均存在，`failures=0`。
- 候选 002 自检：待机、移动、远程、施法、受击、濒危、退场七动作可用；六类骨骼动作、正式 005 死亡序列、独立粉尘／弹体／枪口光／聚能球检查通过，`failures=0`。
- 动画：[强化远程 GIF](../../../design/concepts/chalk-spirit/chalk-rig/002/review/rig-preview.gif)由 Godot 实际渲染 40 帧；[七动作巡演 GIF](../../../design/concepts/chalk-spirit/chalk-rig/002/review/rig-all-actions.gif)输入 112 帧，重复画面合并后保存 105 帧。
- 关键画面：[攻击四阶段](../../../design/concepts/chalk-spirit/chalk-rig/002/review/rig-attack-contact-sheet.png)与[七动作总览](../../../design/concepts/chalk-spirit/chalk-rig/002/review/rig-all-actions-contact-sheet.png)。
- 适配：出手阶段完成 1920×1080、2560×1440、1920×1200 捕获；正式资源回归 `SKILL_VFX_CHECK failures=0`。
- 候选 003 自检：七动作可用，出手时主体后坐方向与弹体方向相反，双环法阵及八颗施法粉尘存在，死亡继续读取正式 005，`failures=0`。
- 候选 003 动画：[远程攻击 GIF](../../../design/concepts/chalk-spirit/chalk-rig/003/review/rig-preview.gif)、[七动作巡演 GIF](../../../design/concepts/chalk-spirit/chalk-rig/003/review/rig-all-actions.gif)、[攻击四阶段](../../../design/concepts/chalk-spirit/chalk-rig/003/review/rig-attack-contact-sheet.png)和[七动作总览](../../../design/concepts/chalk-spirit/chalk-rig/003/review/rig-all-actions-contact-sheet.png)。出手阶段完成三分辨率捕获。
- 候选 003 已适配统一动作预览器：骨骼表现与正式序列帧共用战斗模拟时钟并按动作选择后端，六个骨骼动作与正式 005 退场序列帧可在同一角色中并存；支持动作指定、任意倍率、暂停、单步、循环和巡演。远程弹体由标准模拟器绘制，骨骼层只保留枪口光与后坐，避免双重弹体和时序漂移。接入仍仅用于评审，不改变正式资源绑定。
- 统一预览证据：[远程 1920×1080](../../../design/concepts/chalk-spirit/chalk-rig/003/review/standard-preview-ranged-1920x1080.png)、[远程 2560×1440](../../../design/concepts/chalk-spirit/chalk-rig/003/review/standard-preview-ranged-2560x1440.png)、[远程 1920×1200](../../../design/concepts/chalk-spirit/chalk-rig/003/review/standard-preview-ranged-1920x1200.png)与[正式 005 退场回退](../../../design/concepts/chalk-spirit/chalk-rig/003/review/standard-preview-death-1920x1080.png)。水波纹修复后使用 `-Action` 与 `-Speed 0.25` 重新捕获；骨骼属性和纹理过滤回归检查为 `failures=0`，终端不再出现 `Bone2D` 自动计算警告。

## 制作建议

精确提示词和主体外效果限制仍值得保留，但只能降低重绘漂移概率，不能保证逐帧相同。对这种可拆成硬质石块的角色，优先采用“少量批准关键姿势 + 分层骨骼循环/补间 + 独立特效”的混合方式；纯序列帧保留给新视角、强形变、受击和死亡等骨骼无法凭现有信息可靠构造的动作。
