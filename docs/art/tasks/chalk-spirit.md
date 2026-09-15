# 美术任务：粉笔精灵

状态：进行中。概念 001、角色动画 005、混合动画 006、轻量弹体 001 均获人工批准；混合动画 006 已完成正式技术接入，接入效果待人工复核。资产候选 002、003、004 经评审需修改，仅保留追溯。生产与评审规则见[美术工作流](../WORKFLOW.md)。

## 目标与范围

- 用途：为高频远程敌人“粉笔精灵”落实已批准概念，制作可单独评审的角色候选与轻量弹体候选。
- 优先依据：`chalk` 已注册并在“整排攻击”和 Boss“放学铃”两套敌阵中各出现 2 次，覆盖 3 套敌群中的 2 套、合计 4 个席位；其优先后排的远程技能需要清楚轮廓。任务开始时使用 Kenney 图集 `Rect2(0, 144, 16, 16)` 占位且没有 `battle_animation`，本轮正式接入已替换该状态。
- 对应规范与场景：[角色视觉规范](../specs/CHARACTER_SPEC.md)的战斗比例和读性要求、[视觉方向](../STYLE_BIBLE.md)的异常层、[战斗动画](../../battle-animation.md)；主要出现于异变教室与终点 Boss 战。
- 不在本次范围：其他角色／敌人、替用户批准接入效果、Roadmap 调整。

## 当前版本与方案

- 当前使用版：`resources/content/enemies/chalk.tres` 已引用[正式动画资源](../../../resources/content/animations/chalk.tres)；头像取自正式待机／移动图集，远程弹道引用[正式弹体资源](../../../resources/content/animations/chalk_projectile.tres)。
- 已批准概念：[概念 001](../../../design/concepts/chalk-spirit/chalk-spirit/001/chalk_spirit_concept_001.png)，1254×1254 PNG；生成记录见[同目录 generation.md](../../../design/concepts/chalk-spirit/chalk-spirit/001/generation.md)。
- 已退回资产候选：[图集 002](../../../design/concepts/chalk-spirit/chalk-spirit/002/battle_sheet.png)，1254×1254 RGBA PNG；因朝向和动画连续性问题保留追溯，不作为当前推荐版。
- 已退回资产候选 003：[待机／移动](../../../design/concepts/chalk-spirit/chalk-spirit/003/locomotion_sheet.png)、[远程／施法](../../../design/concepts/chalk-spirit/chalk-spirit/003/combat_sheet.png)、[受击／濒危／退场](../../../design/concepts/chalk-spirit/chalk-spirit/003/reaction_sheet.png)三张 1254×1254 RGBA 图集；动作专属帧解决了 002 的复用抽动，但战斗图集主体比移动图集明显偏小，且旧 GIF 未展示返回待机的真实跳变。
- 已退回资产候选 004：[待机／移动](../../../design/concepts/chalk-spirit/chalk-spirit/004/locomotion_sheet.png)、[远程／施法](../../../design/concepts/chalk-spirit/chalk-spirit/004/combat_sheet.png)、[受击／濒危／退场](../../../design/concepts/chalk-spirit/chalk-spirit/004/reaction_sheet.png)；高度接近目标，但 ImageGen 重绘改变了横向体量，角色显得变胖。
- 已批准角色动画 005：正式文件位于 `assets/art/characters/chalk_spirit/`，从 003 原始帧做 1.30 倍等比变换，不重新生成角色；候选、处理参数和 QA 见[005 generation.md](../../../design/concepts/chalk-spirit/chalk-spirit/005/generation.md)。
- 已批准混合动画 006：候选快照位于[粉笔精灵 006](../../../design/concepts/chalk-spirit/chalk-spirit/006/generation.md)，正式文件继续使用稳定目录 `assets/art/characters/chalk_spirit/`。待机、移动、远程、施法、受击与濒危使用分层刚性骨骼，退场保留已批准 005 的序列帧。
- 已批准轻量弹体 001：正式文件位于 `assets/art/effects/chalk_projectile/`；单枚水平朝右粉笔由程序沿轨迹旋转，三颗递减点仍由程序绘制。候选与完整提示词见[候选生成记录](../../../design/concepts/chalk-spirit/chalk-projectile/001/generation.md)。
- 方案：粉笔块组成的非人浮游体，以黑板擦为核心；长粉笔前臂与环绕弹体表达远程攻击，青／品红裂纹只做局部异常强化。轮廓刻意区别于学生角色和大型 Boss。
- 需保留：真实课堂物件来源、粉笔白／黑板绿主色、非人阵营读性、低复杂度轮廓、明确远程姿态。
- 当前待决事项：无。
- 003 修订结果：44 个动作专属姿势；待机 4 帧、移动 8 帧、远程 8 帧、施法 8 帧、受击 4 帧、濒危 4 帧、退场 8 帧。第 1 格不再跨动作复用，常态动作统一朝右，退场只保留连续倒下所需的旋转。
- 技术依据：[005 切帧元数据](../../../design/concepts/chalk-spirit/chalk-spirit/005/battle_animation.frames.json)记录 384×384 统一画布、`anchor [0.5, 0.875]`、等比变换、各帧安全边距、跨图集高度比和横纵比漂移；[005 候选动画资源](../../../design/concepts/chalk-spirit/chalk-spirit/005/battle_animation.tres)使用 140×140 显示、出手比例 0.625、发射点 `[50, -52]` 和受击点 `[0, -42]`。头像裁切 `[70, 110, 250, 250]` 取自待机／移动图集；批准后这些参数已同步到正式资源和 Manifest。
- 批准与接入依据：用户于当前对话 2026-09-15 先回复“还不错。采用”批准轻量弹体 001，随后明确“角色动画005也一并采用”；正式接入后又回复“预览后看起来是可以的”，批准接入效果。

## 阶段评审

| 阶段 | 被评文件、版本与 SHA-256 | 人工决定 | 修改意见 | 决定来源与日期 |
| --- | --- | --- | --- | --- |
| 概念 | `chalk_spirit_concept_001.png`；001；`d408cc9668d5f3e4f35b5d03fc926fbb9905959183e25cbb7f71b9169b93b7ca` | 通过 | “这个概念不错”；保留当前整体造型方向 | 当前对话，2026-09-14 |
| 资产 | `battle_sheet.png`；002；`9fcaf9abffb5a5f4b3bf685e365aa259183154083f1c077a5c92a09aff90d41a` | 需修改 | 朝向不统一；动画像突然抽动、过渡帧过少，尤其混入第 1 格的多个动作跳变明显 | 当前对话，2026-09-14 |
| 资产 | 003 三张 RGBA 图集；哈希见 003 生成记录 | 待评审 | 依据 002 反馈重做为 44 个动作专属姿势 | 当前对话，2026-09-14 |
| 资产 | 003 三张 RGBA 图集；哈希见 003 生成记录 | 需修改 | 远程／施法主体比待机主体明显偏小；旧 GIF 只播放战斗片段并停末帧，没有暴露返回待机时的体型跳变 | 当前对话，2026-09-15 |
| 资产 | 004 三张 RGBA 图集；哈希见 004 生成记录 | 待评审 | 仅修复战斗图集主体尺度，并用待机→动作→待机 GIF 验证跨片段过渡 | 当前对话，2026-09-15 |
| 资产 | 004 三张 RGBA 图集；哈希见 004 生成记录 | 需修改 | 高度匹配后横向体量变胖；不能只检查高度，也不能让生成模型重绘确定性比例 | 当前对话，2026-09-15 |
| 资产 | 005 三张 RGBA 图集；哈希见 005 生成记录 | 通过 | “角色动画005也一并采用”；从 003 原始战斗帧做 1.30×1.30 等比缩放，保持原横纵比 | 当前对话，2026-09-15 |
| 资产 | `projectile.png`；轻量弹体 001；`007a244cdc3887d93322188f9f03a103f9ae5de934630c5c01c1063fd5a87820` | 通过 | “还不错。采用”；单枚弹体贴图加三颗程序尾迹点 | 当前对话，2026-09-15 |
| 接入效果 | 正式角色动画 005＋轻量弹体 001；接入提交 `6206374` | 通过 | “预览后看起来是可以的”；正式资源绑定、尺寸和尾迹节奏获准采用 | 当前对话，2026-09-15 |
| 资产 | 混合动画 006；SHA-256 见 006 构建元数据 | 通过 | “是的，批准成为正式资产”；六类骨骼动作与 005 退场序列帧并存 | 当前对话，2026-09-16 |
| 接入效果 | 混合动画 006；技术接入提交 `0cac80a` | 待评审 | 真实战斗与统一预览器从同一动画资源解析骨骼表现，退场回退序列帧 | 当前对话，2026-09-16 |

## 验证与结果

- 概念验收条件：先认出粉笔／黑板擦来源；小尺寸仍能区分敌我并读出远程身份；局部赛博强化不盖过校园物件。
- 技术检查：概念 001 为 1254×1254、8-bit RGB、不透明 PNG。资产候选 002 为 1254×1254、8-bit RGBA PNG，1,190,342 个全透明像素（75.70%）；16 格均非空，裁切区域与统一画布 margin 均为非负，SHA-256 与上表一致。
- Manifest 与运行资源：角色动画 005 与轻量弹体 001 已登记为 `approved`；正式路径、头像裁切、锚点、统一画布、动画与弹体资源引用已和运行配置同步。
- 布局／动画验证：候选 `battle_animation.tres` 已通过独立动作预览的待机、移动、近战、远程、施法、受击、退场七模式检查，`failures=0`；暂停、单步和 0.25×慢速检查通过。已在 1920×1080、2560×1440、1920×1200 捕获攻击、远程、施法、受击、退场共 15 张截图。预览未修改游戏角色定义。
- 人工视觉评审：技术检查通过不代表动画表现通过。当前 `move` 在移动姿势之间插入第 1 格，`attack`、`cast` 和 `hurt` 又以第 1 格直接起止；Godot 的 `SpriteFrames` 只替换贴图、不自动插值，因此姿势差异会直接表现为抽动。候选 002 据此判定需修改。
- 003 技术检查：三张最终图集均为 1254×1254、8-bit RGBA；全透明占比分别为 83.71%、86.66%、84.80%。44 格均非空，真实透明沟槽切分后的最小格边安全距离为 23 像素，最大裁切区域 264×285，小于 352×352 统一画布。
- 003 布局／动画验证：候选 `battle_animation.tres` 使用粉笔精灵角色元数据检查待机、移动、远程、施法、受击、濒危、退场七个可用模式，近战入口按远程能力置灰，`failures=0`；完成暂停、单步、0.25×慢速和 1920×1080、2560×1440、1920×1200 三分辨率捕获。七个动作片段均提供专属 GIF 以直接比较连续性，运行预览没有修改正式角色定义。
- 003 评审证据：[待机 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/idle-preview.gif)、[移动 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/move-preview.gif)、[远程 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/attack-preview.gif)、[施法 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/cast-preview.gif)、[受击 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/hurt-preview.gif)、[濒危 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/critical-preview.gif)、[退场 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/death-preview.gif)、[头像裁切](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/portrait-preview.png)、[远程运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/motion-preview-3-1920x1080.png)、[施法运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/motion-preview-4-1920x1080.png)、[受击运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/motion-preview-5-1920x1080.png)、[濒危运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/motion-preview-6-1920x1080.png)、[退场运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/motion-preview-7-1920x1080.png)、[检查日志](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/motion-preview-check.log)与[捕获日志](../../../design/concepts/chalk-spirit/chalk-spirit/003/review/motion-preview-capture.log)。
- 004 技术检查：44 格均非空且未越过格边；移动图集非透明轮廓高度中位数 280 px，战斗图集 290 px，比例 1.0357，进入 0.90–1.10 门槛。该指标只作自动拦截，仍通过[跨片段尺寸并排图](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/cross-clip-scale.png)人工比较头盔与黑板擦核心。
- 004 运行检查：待机、移动、远程、施法、受击、濒危、退场通过，近战按粉笔精灵元数据置灰，`failures=0`。远程和施法主预览改为待机→动作→待机，并按前摇 0.20 秒、后摇 0.25 秒、出手比例 0.625 反推各帧时长；纯动作帧另存为 `*-frames.gif`，避免混淆。
- 004 评审证据：[待机 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/idle-preview.gif)、[移动 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/move-preview.gif)、[远程过渡 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/attack-preview.gif)、[施法过渡 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/cast-preview.gif)、[受击过渡 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/hurt-preview.gif)、[濒危 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/critical-preview.gif)、[退场 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/death-preview.gif)、[远程运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/motion-preview-3-1920x1080.png)、[施法运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/motion-preview-4-1920x1080.png)、[检查日志](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/motion-preview-check.log)与[捕获日志](../../../design/concepts/chalk-spirit/chalk-spirit/004/review/motion-preview-capture.log)。
- 005 技术检查：战斗帧围绕统一脚底锚点执行 `1.30×1.30` 等比变换；移动／战斗轮廓高度中位数为 276／264.5 px，高度比 0.9583；战斗源／输出轮廓横纵比中位数为 0.8478／0.8463，漂移 0.0015；最小格边安全距离 4 px。
- 005 运行检查：待机、移动、远程、施法、受击、濒危、退场通过，近战按元数据置灰，`failures=0`。三分辨率捕获完成；运行时显示比例与 003 近似相同。
- 005 评审证据：[待机 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/idle-preview.gif)、[移动 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/move-preview.gif)、[远程过渡 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/attack-preview.gif)、[施法过渡 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/cast-preview.gif)、[受击过渡 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/hurt-preview.gif)、[濒危 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/critical-preview.gif)、[退场 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/death-preview.gif)、[尺寸并排图](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/cross-clip-scale.png)、[远程运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/motion-preview-3-1920x1080.png)、[施法运行截图](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/motion-preview-4-1920x1080.png)与[检查日志](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/motion-preview-check.log)。
- 轻量弹体 001 技术检查：生成源为 1254×1254 RGBA，清理低 alpha 噪声并等比缩放到 192×96 透明画布，有效内容 164×64，运行显示 32×16。候选资源加载、按方向旋转、后缘尾迹和无样式回退由 `skill_vfx_check.tscn` 覆盖，`failures=0`；粉笔精灵七个可用动作模式检查通过，近战按元数据置灰。
- 轻量弹体 001 评审证据：[静态与实际尺寸](../../../design/concepts/chalk-spirit/chalk-projectile/001/review/projectile-preview.png)、[远程 1920×1080](../../../design/concepts/chalk-spirit/chalk-projectile/001/review/motion-preview-3-1920x1080.png)、[2560×1440](../../../design/concepts/chalk-spirit/chalk-projectile/001/review/motion-preview-3-2560x1440.png)、[1920×1200](../../../design/concepts/chalk-spirit/chalk-projectile/001/review/motion-preview-3-1920x1200.png)。
- 正式接入检查：独立预览只传入 `resources/content/enemies/chalk.tres`，不再用 `-Animation` 或 `-Projectile` 候选覆盖；待机、移动、远程、施法、受击、濒危、退场通过，近战按元数据置灰，`failures=0`。正式头像、44 帧七动作、三张批准图集、弹体资源路径与 32×16 显示尺寸由 `skill_vfx_check.tscn` 断言。
- 正式接入证据：[1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/integration-motion-preview-3-1920x1080.png)、[2560×1440](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/integration-motion-preview-3-2560x1440.png)、[1920×1200](../../../design/concepts/chalk-spirit/chalk-spirit/005/review/integration-motion-preview-3-1920x1200.png)。预览标题显示“角色动作图集＋弹体”，证明组合来自正式角色资源而非命令行候选覆盖。
- 实际预览证据：[候选头像裁切](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/portrait-preview.png)、[远程 1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-3-1920x1080.png)、[施法 1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-4-1920x1080.png)、[退场 1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-6-1920x1080.png)、[检查日志](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-check.log)、[捕获日志](../../../design/concepts/chalk-spirit/chalk-spirit/002/review/motion-preview-capture.log)。头像预览为 250×250 RGBA，SHA-256 为 `36214bd7cec38f01c7c71370d3a74c720f412f55a2c1828e08efb3a16c21d35b`；其余 12 张为 `.godot/` 可重建缓存。
- 已知验证噪声：Godot 报告既有根证书读取错误及 `tiny-town.png`／`tiny-dungeon.png` 编辑器原图加载警告；完成标记、专项断言和候选纹理加载均正常。

## 骨骼＋序列帧混合方案 006

- 006 混合动画检查：六类骨骼动作与序列帧退场在统一预览器和真实战斗中共用时钟；`MOTION_PREVIEW_CHECK failures=0`、`PRESENTATION_CHECK PASS failures=0`、`SKILL_VFX_CHECK failures=0`、`ANIMATION CHECK: PASS`。远程后坐方向与弹体相反，施法使用青紫双环法阵；线性 mipmap 采样和显式骨骼属性消除了水波纹与 `Bone2D` 自动计算警告。
- 006 评审证据：[远程攻击 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/006/review/rig-preview.gif)、[七动作巡演 GIF](../../../design/concepts/chalk-spirit/chalk-spirit/006/review/rig-all-actions.gif)、[攻击四阶段](../../../design/concepts/chalk-spirit/chalk-spirit/006/review/codex-workflow/rig-attack-contact-sheet.png)、[七动作总览](../../../design/concepts/chalk-spirit/chalk-spirit/006/review/codex-workflow/rig-all-actions-contact-sheet.png)、[正式远程 1920×1080](../../../design/concepts/chalk-spirit/chalk-spirit/006/review/codex-workflow/asset-006-ranged-1920x1080.png)、[施法](../../../design/concepts/chalk-spirit/chalk-spirit/006/review/codex-workflow/asset-006-cast-1920x1080.png)与[序列帧退场](../../../design/concepts/chalk-spirit/chalk-spirit/006/review/codex-workflow/asset-006-death-1920x1080.png)。
- 006 目录归一：早期试验曾用同一对象的临时别名；正式批准后已将最终候选归入 `design/concepts/chalk-spirit/chalk-spirit/006/`，移除全部别名目录，正式运行资产回归无版本号稳定路径。Git 历史保留被淘汰试验的追溯信息。
- 未解决问题：混合动画 006 的正式接入效果仍待人工评审；后续若改变原图、运行尺寸、锚点、骨骼时序或尾迹节奏，按受影响阶段重新评审。
- 本地提交：概念批准 `a26fb1c`；轻量弹体候选与通用接口 `bde0942`；角色动画 005 正式资产与接入 `6206374`；混合方案验证 `aaf67f7`；资产 006 批准 `bcdac72`；混合运行时接入 `0cac80a`；Manifest 预览修复 `8bd5411`。
