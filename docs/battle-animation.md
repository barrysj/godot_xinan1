# 战斗动画资源接入

战斗模拟、角色表现状态和素材播放器分离。`CampusUnit.battle_animation` 可选，未配置时沿用已有占位图及程序位移，不新增或替换正式美术。

## 接入序列帧

1. 用 `game/content/battle_animation_set.gd` 创建 `.tres`，在 `frames` 中配置 SpriteFrames（独立图片或 AtlasTexture 均可）。
2. 配置 `display_size`（1280×720 逻辑画布尺寸）与归一化 `anchor`。所有帧使用统一画布和脚底位置。
3. `impact_ratio` 表示攻击/施法片段中的出手位置，默认 0.45；前半段映射到模拟前摇，后半段映射到后摇。帧率不会改变伤害时刻。
4. 有方向的素材可启用 `flip_with_facing`；默认关闭，避免翻转旧正面占位图。基准素材朝右，左转时围绕锚点镜像。
5. 将资源赋给角色或敌人的 `battle_animation`。正式资产仍需按美术 Pipeline 批准登记。

| 动画名 | 触发与行为 |
| --- | --- |
| `idle` | 常态循环 |
| `move` | 移动循环；缺失时回退静止状态 |
| `attack` | 普攻前摇开始，与模拟动作阶段同步 |
| `cast` | 带技能的一次攻击，替代攻击片段；群体效果不重复播放 |
| `hurt` | 实际扣血，不能打断攻击或施法 |
| `critical` | 存活且血量不超过 `critical_ratio`（默认 25%），静止时循环 |
| `death` | 死亡打断动作，播放后停末帧；恢复生命后重置 |

待机、移动、濒死读取 FPS 和每帧相对时长并循环；单次动作忽略资源循环开关。缺失当前动作纹理时回退已有贴图。共享 Resource 不保存运行状态。暂停冻结全部表现，倍速同步，重开重新创建运行状态。

## 表现与结算

`game/combat/battle_simulation.gd` 负责前摇、出手、后摇和追踪弹道。具体规则与配置见 `docs/battle-demo.md` 的行动时序框架章节。无骨骼后端、根运动或物理击退。

`unit_presentation.gd` 负责每个角色的表现状态；在模拟位置之间插值，程序前摇、攻击位移、受击偏移不修改占位。已有素材提供对应片段时让素材负责动作姿势；闪白、退场淡化仍统一生效。单位按插值后的脚底纵坐标排序。

弹道直接显示模拟中的飞行状态，抵达后触发伤害数字和命中特效，移除旧的“扣血后再播放装饰弹道”。同目标连续数字错位排列，完全吸收伤害显示“格挡”，护盾耗尽触发破裂碎片。`pixel_battle.gd` 的 `presentation_cue(event)` 信号提供音效/镜头等后续消费者入口，当前没有接入音效或震屏。

结算前保留至少 0.65 秒收尾；如剩余死亡动画更长则等待其完成，之后才恢复胜利方并进入战报。headless 直接完成结算，不依赖动画时钟。

## 验证

使用 PowerShell 7 调用 Godot：

- `--headless --path . res://game/combat/action_check.tscn`：行动、命中与弹道边界。
- `--headless --path . res://scenes/battle_demo/animation_check.tscn`：原有帧时长、优先级、恢复、缺失、暂停、倍速与重开。
- `--headless --path . res://scenes/battle_demo/presentation_check.tscn`：移动片段、出手帧对齐、动画锁释放、插值、受击/死亡、30/60/144 FPS 和 1×/2×战斗结果与统计一致。
- `--path . res://scenes/battle_demo/battle_demo.tscn -- --autobattle-capture`：1920×1080、2560×1440、1920×1200 的运行截图，输出到 `.godot/`。

现有部署、寻路和完整冒险回归入口继续保留。
