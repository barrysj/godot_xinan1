# COMBAT-03 · 战斗结算、详细战报与重试

- 功能 ID：COMBAT-03
- 所属系统：战斗
- 当前状态：已验证
- 最近验证：2026-10-13；基线 `5894923` 加本次工作树，Windows／Godot 4.7.2。

## 玩家能力与接入范围

主线与 Debug 战斗试玩共用详细结算页。我方／敌方页签显示成员与阵位、有效伤害、整场秒伤、有效治疗、生命承伤、实际供盾及实际吸收；点击行查看结束生命、存活时长、退场状态、普攻／技能释放次数、角色伤害占比和获得的盾量。同类敌人按阵位区分。

右侧显示实际程序次数／种类、首次成功施放核心程序的时刻、首个退场及同时退场者、四色代码生成／消耗／溢出，以及直接程序伤害／治疗／供盾。信息使用共享 Theme／颜色，原纸面框架与 1280×720 等比画布；长记录可滚动，页签和行可用键盘导航。

主线胜利仍全员恢复并领取奖励，失败保留构筑重试。试玩仍只有“退出游戏”“重新战斗”两个结束操作，重开返回整备并保留配置。回退失败保留原战报。

## 实现与规则入口

- [battle_report.gd](../../game/combat/battle_report.gd)：原模拟器事件的有界统计与快照校验；不存完整事件历史。
- [battle_simulation.gd](../../game/combat/battle_simulation.gd)、[code_battle_simulation.gd](../../game/combat/code_battle_simulation.gd)：真实命中／动作、程序来源和转换消耗。
- [battle_report_view.gd](../../scenes/expedition/battle_report_view.gd)、[expedition.gd](../../scenes/expedition/expedition.gd)：共享界面与恢复前的结束快照。
- 原 Campaign／Run 检查点保存可选 `report_details`，沿用原原子存档、schema 和恢复流程。旧报告缺少的新数据显示“未记录”，不据当前单位重算历史。
- 规则事实源：[战斗规则](rules.md)；试玩操作见[战斗调试](../development/battle-tuning.md)，跨系统边界见[集成约束](../development/integration.md)。

## 统计口径

伤害排除护盾挡下、过量与无效伤害，保留原同批命中的比例分摊。承伤仅计实际生命损失；治疗排除过量治疗。供盾为来源实际增加量，获盾及吸收按受盾者记录；到期、覆盖、移除不算吸收。胜利回血前冻结结束生命；重开清零。秒伤以原模拟整场时间为分母，不受渲染帧率、倍速或暂停时长影响。

直接追踪／修复／反冲供盾独立于角色贡献；原角色追击、特性治疗和受盾者的后续反冲爆炸仍按实际执行者归属。生成包含溢出，消耗包含程序支付及转码器转换；剩余库存参与收支验证。热修复计入总程序次数，不计首次核心。

## 验证与证据

```powershell
pwsh.exe -NoProfile -File tools/development/tests/battle-report.test.ps1 -EnginePath '<Godot console.exe>'
pwsh.exe -NoProfile -File tools/development/tests/battle-report.test.ps1 -Capture -EnginePath '<Godot GUI.exe>'
pwsh.exe -NoProfile -File tools/development/tests/battle-tuning.test.ps1 -Capture -EnginePath '<Godot GUI.exe>'
```

- 统计专项覆盖同批过量伤害、公平归属、有效治疗、盾上限／到期、真实普攻／施法释放、直接程序与排队追击分别归属、首次核心、代码转换收支、非法快照、事件消费隔离和重开清零。
- 实机覆盖原自然胜利、双方／六敌阵、真实鼠标选择／键盘页签、恢复前生命、新旧 Campaign／Run JSON 报告、主线领奖、试玩重开、两玩家档字节不变，以及 1920×1080、2560×1440、1920×1200。截图在忽略的 `.godot/battle-report-*.png`，已在对话展示。
- 原修改器／直接整备／自然胜败两个结束动作和失败回退通过；原命中分摊、产码、表现时钟、领奖清理回归通过。完整结果见[战斗验证](verification.md)。

## 已知边界与统筹状态

统计不等于胜负原因分析；不提供虚构暴击、击杀归属、最佳阵容评分或因果结论。旧战报无法恢复未保存的数据。仅 Windows 本地源码与三桌面尺寸验收，未验手机、Web 或实体手柄。

待统筹：原战斗结算升级为双方详细报告，原存档新增可选报告快照；没有另建战斗／存档系统，奖励与试玩结束流程沿用原实现。总览仍为 2026-10-10 快照，由统筹核验后汇总。

## 派遣分支合入适配（2026-10-14，待统筹）

适配main基线7146bb5与派遣分支7db24ce：详细战报沿用原两人出发、会合后3／4人的主线队伍，不恢复固定四人限制。应急护盾按道具实际供盾单列，受盾／吸收仍属于目标，不虚记首名队员贡献。复苏后结束状态按真实生命判定，存活时间累计各存活区间；首个退场仍保留首次倒下时刻。新字段item_shield／first_defeat为原报告的可选扩展，旧报告仍可读取；不变更存档主版本或另建统计系统。验证入口与本次结果见[战斗验证](verification.md)。
