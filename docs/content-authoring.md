# 内容录入指南

本项目使用 Godot 自定义 Resource 录入内容。一个 `.tres` 是一份静态定义；生命、穿戴、阵位、训练、奖励领取状态属于探索实例。添加已有机制下的人物、敌人、技能、装备、事件、地点，不需要修改游戏逻辑脚本。

## 从这里开始

- 总清单：`res://resources/content/manifest.tres`。
- 快速预览：`res://scenes/content/content_preview.tscn`，打开后按 **F6**。
- 示例人物：`characters/morning.tres`（晨读生）。
- 示例装备：`equipment/ribbon.tres`（晨光发带）。
- 示例技能：`skills/archer.tres`（穿云）。
- 示例事件：`events/morning_event.tres`（晨光书签）。
- 示例地点：`locations/reading.tres`（晨读教室）。
- 默认奖励池：`pools/campus.tres`。

上面的内容目录均相对于 `res://resources/content/`。建议先复制一个示例，完成一次“修改 → 校验 → 预览”，再批量录入。

## 通用录入步骤

1. 在 Godot 文件系统面板选中示例，右键复制（Duplicate），保存到对应内容目录。
2. 双击复制出的 `.tres`，在检查器先修改 **Id**，例如 `reader_lan`。推荐英文小写加下划线。同类内容 ID 必须唯一；名称可以改，已发布内容的 ID 不要改。
3. 填写 **Display Name**、**Description**、数值和图片。图片可直接拖入 Texture2D 字段，也可创建 AtlasTexture，设置图集与裁剪区域。
4. 展开技能、效果、事件选项等资源引用。要共用技能，拖入现有技能资源；要独立修改技能，另存为新 `.tres`、改 ID，并注册到技能清单。**修改共享引用会影响所有引用者。**
5. 打开 `manifest.tres`，给对应数组增加一项，将新资源拖进去。清单数组不能为空引用。仅创建文件不会让内容自动出现。
6. 根据下表接入获取途径或路线。保存资源后运行校验，停止并重新运行预览。

| 内容 | 加入的清单数组 | 还需要的关联 |
| --- | --- | --- |
| 人物 CampusUnit | Characters | 新建 Recruit 奖励引用人物；奖励注册后加入地点使用的奖励池，或作为事件结果 |
| 敌人 CampusUnit | Enemies | 加入 Encounter 的 Units，并配置对应 Slots，再让地点引用敌群 |
| 技能 CampusSkill | Skills | 人物或敌人的 Skill 引用它 |
| 装备 CampusEquipment | Equipment | 新建 Gear 奖励引用装备；加入奖励池或事件结果 |
| 奖励 CampusReward | Rewards | 加入 RewardPool.Rewards 或 EventOption.Results |
| 奖励池 CampusRewardPool | Reward Pools | 地点的 Rewards 引用它 |
| 事件 CampusEvent | Events | Event 类型地点的 Event 引用它 |
| 地点 CampusLocation | Locations | 配置 Route Pool；新探索生成时进入候选池 |
| 敌群 CampusEncounter | Encounters | 战斗地点的 Encounter 引用它 |

奖励与装备可以各自使用相同 ID，例如 `badge`，但同一类型内不能重复。人物与敌人请使用不同 ID。系统保留原有五个人物 ID、`shoe` 及现有内容，用于初始阵容和旧档迁移；扩展时复制新增，避免删除原资源。

## 人物、敌人与技能

人物和敌人使用同一种 CampusUnit，分别登记到清单的 Characters 和 Enemies。填写生命 Health、攻击 Attack、攻击间隔 Interval（秒）、防御 Defense、头像 Portrait、阵营标记色 Badge Color，以及 Skill。

人物身份与技能独立。例如晨读生与远射手都引用穿云。把晨读生复制成另一位同学、修改名字和头像，仍然可以直接用穿云；不必建立新的技能代码。

敌群的 **Units** 与 **Slots** 一一对应。槽位 0、1、2 是前排，3、4、5 是后排；同一个敌人资源可以放入多次，但槽位不能重复。每个实例都有自己的生命和技能计数。

技能字段：

- **Attacks To Trigger**：每几次普攻后触发，1～20 次，已有技能都是 3 次。
- **Effects**：可组合的 CampusEffect 数组。每个效果实际数值为 `Value + 当前攻击 × Attack Scale`。
- **Icon**：可选自定义技能图片；不填时使用 Glyph 指定的现有图标。

| Kind | 实际行为 |
| --- | --- |
| damage | 伤害，沿用现有防御减伤和护盾吸收 |
| heal | 治疗，不超过生命上限 |
| shield | 增加护盾，沿用总护盾上限 144 |
| max_hp | 增加生命上限，并恢复同等生命，仅当场战斗有效 |
| attack | 增加攻击，仅当场战斗有效 |
| interval | 将攻击间隔设置为结果值（秒），限制在 0.1～10 秒 |

目标 Target 支持：normal（前排优先）、back（后排优先）、low_enemy（最低生命比例敌人）、low_ally（最低生命比例友军）、adjacent（自身及上下左右相邻友军）、row（当前目标所在整排敌人）、self、all_allies、all_enemies。

同一轮先收集行动，再结算治疗、护盾和属性效果，最后结算伤害，保留原有同时行动顺序。描述文字不会执行效果；新机制如眩晕、召唤、持续毒伤，需要先实现并验证代码。

## 装备与奖励

装备支持 Health Bonus、Attack Bonus、Interval Multiplier（攻击间隔倍率，0.75 表示缩短 25%）。每位同学一件，每种装备本局一份；穿戴到另一个同学时自动转移，原装备回背包。装备可以跟随候补人物保存。背包与候补列表支持滚动。

奖励 Operation 支持：

- **gear**：给予 Equipment 引用的一件装备。已拥有时不再抽到。
- **recruit**：让 Character 引用的人物加入候补。已招募时不再抽到。
- **train**：为 Character 增加 Amount 级训练。每级生命 +50、攻击 +5，上限 100 级。人物须已在队伍中。
- **points**：增加 Amount 点本局修复资源；通关后带回基地。

Gear/Recruit 的 Amount 保持 1。奖励池等权、不重复抽取，默认抽三项；校验要求至少保留三项初始同学的训练，防止常规探索无法抽奖。高训练等级等极端状态导致可用奖励不足时，只展示实际可用项。没有可领取项的存档会拒绝恢复，请保留原档排查内容配置。

## 事件

事件拥有独立正文 Description、可选 Image，以及 1～3 个 Options。选项中的 Text 是玩家看到的选择，可以使用口语；Description 放支付和结果说明。

条件与结果：

- Minimum Points：本局资源门槛；Cost：实际支付的本局资源。
- Required Character / Required Equipment：队伍或背包需持有的内容，可为空。
- Results：按顺序执行的已注册奖励。
- Open Rewards：开启后进入当前地点的随机奖励选择；关闭则完成地点，回到地图。

显示选项和点击执行都会检查条件。所有结果先在临时状态中验证，成功后才支付并发奖。已执行标记随存档保存，不能重复点击获取收益。交换装备完成地点会正常获得该地点的探索资源，因此“花 1 点换装备，完成普通事件得 1 点”的净资源变化为零。

晨光书签示例：有至少 1 点本局资源时可换晨光发带；另一项给远射手训练后进入补给选择。若已经拥有发带，交换项会禁用。

## 地点与路线

本次保持五层、每层至多两条路、四人上阵，不扩展关卡规模。

Route Pool：Start 为起点（恰好一个），Final 为首领终点（恰好一个），Safe 至少四个候选，Risk 至少两个候选。新探索从 Safe 抽三条安全路，另抽一条与两条 Risk 组成分支；有多余候选时不保证每局出现。增加一个地点不会自动增加探索层数。

Kind 决定普通战斗、精英、事件或首领。战斗地点引用 Encounter，事件地点引用 Event；每个地点必须引用 Rewards 奖励池。

开启 **Depth Scaled** 时，Power 是深度基础强度的倍率：三层普通战斗基础强度为 0.68、0.78、0.88，精英为 0.78、0.88、0.98。默认倍率 1；关闭时直接使用 Power。起点和首领默认关闭，保留 0.62 / 1.25 原值。数值只缩放敌人生命和攻击。

## 校验与快速预览

在工程目录使用 PowerShell 7：

```powershell
pwsh.exe -File .\run-content.ps1 -Mode Validate
pwsh.exe -File .\run-content.ps1 -Mode Preview
pwsh.exe -File .\run-content.ps1 -Mode Check
```

引擎路径不同可附加 `-Godot '你的Godot路径'`。首次添加脚本或图片后，先用 Godot 编辑器打开工程，等待导入完成。

Validate 输出资源路径和具体问题，成功输出 `CONTENT_VALIDATION errors=0`。覆盖空/重复 ID、空引用、未注册引用、非法属性、技能效果、敌群槽位、事件、奖励池及路线配置。正式游戏启动时同样校验；失败时显示错误，不读取和覆盖探索存档。

Preview 打开与正常游戏共用战斗、队伍和事件逻辑的预览场景。在编辑器打开 `content_preview.tscn`，选根节点：

1. Preview Character 拖入已注册人物；Preview Equipment 拖入已注册装备。
2. Preview Location 可拖入已注册地点，不填则使用默认地点。
3. Preview Mode 选 battle 查看战斗，equipment 查看背包与穿戴，event 触发事件。
4. 按 F6。停下后修改资源，再按 F6 重新加载。

Event 模式想测试兑换发带时，先清空 Preview Equipment（否则预览已持有发带，交换项会禁用）。Event 模式建议地点留空（自动使用晨读教室），或明确拖入 Event 类型地点。预览会按地点前的进度提供本局资源，方便测试支付；实际数据校验测试另外覆盖资源不足情形。预览只使用内存探索；离开预览不会保存它。Check 使用 `.godot` 内独立测试夹具并输出实际运行截图，不覆盖 `user://` 档案。

## 修改内容对存档的影响

- 新存档使用字符串人物 ID，记录持有装备、训练和阵位，改名或调整清单展示顺序不会更换身份。
- 已生成路线、地点强度、事件正文/选项/结果，以及已抽取奖励的正文/结果进入快照。添加地点或改变奖励池不会重抽现有路线和待领奖励；开启新探索查看新配置。
- 未到达地点的奖励在进入地点时抽取，因此尚未抽取的奖励会采用当时的奖励池。
- 人物基础属性、技能、装备数值和图片在重新开始场景或恢复战斗时读取资源。中断战斗按原阵容重新开战，沿用既有续玩规则，不恢复半场 HP。
- 不存在的内容引用会使恢复失败，保留原档。不要为了改名删除资源或改 ID；将资源恢复后再续玩。
- 兼容旧 schema 1/2 的整数人物和固定装备字段，以及本次过渡 schema 3/4。旧随机路线用保留的原算法重建，随后升级为完整快照。`ShortRun.STAGES` 和旧生成函数仅承担兼容与历史验证，不是新内容录入口。
- 原来的原子写入、保存失败提示、派遣单次领取和通关单次结算保持使用。

## 维护边界

新增内容需要加入资源引用清单，导出由引用关系打包，不依赖编辑器文件扫描。不要修改共享 Resource 来记录运行状态。描述文字要与配置保持一致；图鉴读取同一份资源，但不会把自然语言解析为技能。一次新增少量内容并实战检查，通常比先录入几十条再集中修错更省力。
