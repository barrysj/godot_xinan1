# 战斗动画资源接入

当前仅实现代码支持，不新增或替换正式美术。角色和敌人共用 `CampusUnit.battle_animation`，未配置时保留原有静态贴图表现。

## 接入序列帧

1. 使用 `game/content/battle_animation_set.gd` 创建 Resource，保存为 `.tres`。
2. 在 `frames` 中创建 SpriteFrames，可使用独立图片或 AtlasTexture 图集区域。动画名称见下表。
3. 设置 `display_size`（1280×720 逻辑画布中的尺寸）和归一化 `anchor`（默认脚底附近）。所有帧应使用统一画布和脚底位置。
4. 将资源赋给角色或敌人定义的 `battle_animation`。正式资产仍需按美术 Pipeline 批准登记。

| 动画名 | 触发与行为 |
| --- | --- |
| `idle` | 常态循环 |
| `attack` | 普攻出手，播放一次 |
| `cast` | 技能出手，替代同次攻击动作；群体效果只触发一次 |
| `hurt` | 实际扣血，播放一次；不打断攻击或施法 |
| `critical` | 存活且血量比例不超过 `critical_ratio`，默认 25%；动作结束后循环，治疗脱离阈值后恢复 |
| `death` | 生命归零，打断动作，播放后停在末帧；恢复生命后重置 |

播放使用 SpriteFrames 的 FPS 和每帧相对时长；攻击、施法、受击、死亡忽略资源中的循环开关。优先级为死亡 > 施法 > 攻击 > 受击 > 待机。缺少动作时跳过，缺少濒死动作时用待机，缺少当前状态纹理时回退原有贴图。暂停冻结动画，战斗倍速同步推进；重新编队和开战创建独立播放状态。共享资源不保存角色运行状态。

动画仅负责表现，伤害仍在原有模拟时刻结算；没有新增前摇判定、根运动或骨骼播放器。本接口直接支持序列帧，骨骼资产需后续根据交付格式接入。

## 验证

使用 PowerShell 7 调用 Godot：`--headless --path . res://scenes/battle_demo/animation_check.tscn`。检查帧时长、动作优先级、濒死恢复、死亡末帧、资源缺失、暂停、倍速和重开；原有战斗回归入口为 `pwsh.exe -File ./run-battle-demo.ps1 -Smoke`。
