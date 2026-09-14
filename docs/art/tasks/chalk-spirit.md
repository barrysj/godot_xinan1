# 美术任务：粉笔精灵

状态：概念 001 已获人工批准；正式资产候选 002 待人工评审，尚未进入接入阶段。生产与评审规则见[美术工作流](../WORKFLOW.md)。

## 目标与范围

- 用途：为高频远程敌人“粉笔精灵”落实已批准概念，并制作 1 个可单独评审的正式资产候选。
- 优先依据：`chalk` 已注册并在“整排攻击”和 Boss“放学铃”两套敌阵中各出现 2 次，覆盖 3 套敌群中的 2 套、合计 4 个席位；其优先后排的远程技能需要清楚轮廓。当前仍使用 Kenney 图集 `Rect2(0, 144, 16, 16)` 占位，且没有 `battle_animation`。
- 对应规范与场景：[角色视觉规范](../specs/CHARACTER_SPEC.md)的战斗比例和读性要求、[视觉方向](../STYLE_BIBLE.md)的异常层、[战斗动画](../../battle-animation.md)；主要出现于异变教室与终点 Boss 战。
- 不在本次范围：其他角色／敌人、Manifest 登记、正式角色资源替换、游戏内接入、替用户批准资产或接入效果、Roadmap 调整。

## 当前版本与方案

- 当前使用版：`resources/content/enemies/chalk.tres` 中的 Kenney 16×16 占位区域；未登记为正式美术资产。
- 已批准概念：[概念 001](../../../design/concepts/chalk-spirit/chalk-spirit/001/chalk_spirit_concept_001.png)，1254×1254 PNG；生成记录见[同目录 generation.md](../../../design/concepts/chalk-spirit/chalk-spirit/001/generation.md)。
- 本轮资产候选：[图集 002](../../../design/concepts/chalk-spirit/chalk-spirit/002/battle_sheet.png)，1254×1254 RGBA PNG；原始 RGB 输出、完整来源与透明处理记录见[002 generation.md](../../../design/concepts/chalk-spirit/chalk-spirit/002/generation.md)。
- 方案：粉笔块组成的非人浮游体，以黑板擦为核心；长粉笔前臂与环绕弹体表达远程攻击，青／品红裂纹只做局部异常强化。轮廓刻意区别于学生角色和大型 Boss。
- 需保留：真实课堂物件来源、粉笔白／黑板绿主色、非人阵营读性、低复杂度轮廓、明确远程姿态。
- 当前唯一待决事项：正式资产候选 002 的造型一致性与动作表现是否通过资产阶段。
- 技术依据：候选使用 4×4、16 姿势和七类动作；[切帧元数据](../../../design/concepts/chalk-spirit/chalk-spirit/002/battle_sheet.frames.json)记录 384×384 统一画布、`anchor [0.5, 0.875]`、各帧实测区域与 margin，并预备候选头像裁切 `portrait_region [42, 10, 250, 250]`；[候选动画资源](../../../design/concepts/chalk-spirit/chalk-spirit/002/battle_animation.tres)使用 128×128 显示、基准朝右、出手比例 0.4、发射点 `[50, -58]` 和受击点 `[0, -48]`。上述参数只随候选评审，不提前写入正式 Manifest。
- 提前试接入授权：无；概念获批也不等于资产或接入获批。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `chalk_spirit_concept_001.png`；001；`d408cc9668d5f3e4f35b5d03fc926fbb9905959183e25cbb7f71b9169b93b7ca` | 通过 | “这个概念不错”；保留当前整体造型方向 | 当前对话，2026-09-14 |
| 资产 | `battle_sheet.png`；002；`9fcaf9abffb5a5f4b3bf685e365aa259183154083f1c077a5c92a09aff90d41a` | 待评审 | | 当前对话，2026-09-14 |
| 接入效果 | 未开始 | 待评审 | | |

## 验证与结果

- 概念验收条件：先认出粉笔／黑板擦来源；小尺寸仍能区分敌我并读出远程身份；局部赛博强化不盖过校园物件。
- 技术检查：概念 001 为 1254×1254、8-bit RGB、不透明 PNG。资产候选 002 为 1254×1254、8-bit RGBA PNG，1,190,342 个全透明像素（75.70%）；16 格均非空，裁切区域与统一画布 margin 均为非负，SHA-256 与上表一致。
- Manifest 与运行资源：均未修改；候选参数尚未登记，现有 `portrait_region`、`anchor`、`normalized_canvas`、`animation_resource` 等正式信息未受影响。
- 布局／动画验证：候选 `battle_animation.tres` 已通过独立动作预览的待机、移动、近战、远程、施法、受击、退场七模式检查，`failures=0`；暂停、单步和 0.25×慢速检查通过。已在 1920×1080、2560×1440、1920×1200 捕获攻击、远程、施法、受击、退场共 15 张截图。预览未修改游戏角色定义。
- 实际预览证据：[候选头像裁切](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/portrait-preview.png)、[远程 1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-3-1920x1080.png)、[施法 1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-4-1920x1080.png)、[退场 1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-6-1920x1080.png)、[检查日志](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-check.log)、[捕获日志](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-capture.log)。头像预览为 250×250 RGBA，SHA-256 为 `36214bd7cec38f01c7c71370d3a74c720f412f55a2c1828e08efb3a16c21d35b`；其余 12 张为 `.godot/` 可重建缓存。
- 已知验证噪声：Godot 报告既有根证书读取错误及 `tiny-town.png`／`tiny-dungeon.png` 编辑器原图加载警告；完成标记、专项断言和候选纹理加载均正常。
- 未解决问题：等待资产 002 人工评审；通过后再把候选参数登记进正式 Manifest 并进入接入阶段，接入效果仍须单独评审。
- 本地提交：概念批准已提交为 `a26fb1c`；资产候选提交号以本文件 Git 历史为准。
