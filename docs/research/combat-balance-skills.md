# 战斗数值设计技能检索（2026-10-01）

检索范围：本机 C:/Users/SongJun/.codex/skills、C:/Users/SongJun/.agents/skills、项目 .agents/skills；rg --files -L -g *SKILL.md 返回185条路径（含链接/重复，不等于185个独立技能）；按balancing、economy、damage formula、数值设计检索，并查项目git ls-files。不是对全部磁盘穷举。

本机可用相关技能：game-concept-architect用于目标与假设；game-design-review用于设计审视；rpg包含成长与伤害公式，roguelike偏类型框架。未发现专用战斗数值优化技能；本项目Git跟踪的技能只有art-implementation，与本任务不匹配。

## GitHub候选

1. [nitzangames/headless-game-balance](https://github.com/nitzangames/headless-game-balance/blob/main/SKILL.md)：已读取完整原始SKILL.md。适合本项目已有确定性模拟层，要求复用真实规则、固定策略/种子、记录结果后迭代。推荐作为后续验证技能；不是现成的Godot平衡器，也不能为尚未实现的规则直接给出可靠胜率。本次采用其证据边界，未安装或执行外部脚本。
2. [AbsolutelySkilled/AbsolutelySkilled](https://github.com/AbsolutelySkilled/AbsolutelySkilled)：仓库README列出game-balancing，涵盖经济、难度、成长和试玩；本次访问对应skills/game-balancing/SKILL.md返回404，不能确认当前包可用，不作为已可安装推荐。
3. [dreamteam-hq/brigid 的 game-economy-design](https://github.com/dreamteam-hq/brigid/blob/main/skills/game-economy-design/SKILL.md)：搜索摘要显示资源来源/消耗建模方向；尚未完整审查，作为后续局外经济候选，不声称适配战斗。

未安装技能、未更改本机配置；本次数值为项目原创初值，并非从上述技能抄取。技能不替代主线实机和真人试玩。

## 本次设计结论

完整规则归docs/battle-demo.md的“双流派数值提案v0.1”。两条链路为漏洞验证追击与护盾吸收反冲。初值检查重点是特殊盾返还不能持续独立支付自身，而非简单禁止某次返还2紫（余量可能导致该情况）。首发时间取决于真实攻击与承伤，纸面算式仅检查可行条件。
