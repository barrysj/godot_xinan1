# 战斗状态与产码组件

当前：已留存概念concept_001与组件asset_001；主线试接入已授权，资产与接入视觉效果仍为review。分支art/enemy-animation-assets，功能基线e15be65＋当前接入工作树。规则与实现验证分别归docs/battle-demo.md、UI-02，不在此复制战斗数值。

## 人工决定与版本

| 日期 | 对象 | 用户决定 | 状态 |
| --- | --- | --- | --- |
| 2026-10-07 | 修正版概念图 | 看起来不错，生成正式资产吧 | 概念批准；SHA绑定如下 |
| 2026-10-07 | 当前组件套件 | 尝试接入吧 | 放行原主线试用，视觉待评审 |
| 2026-10-07～08 | 运行布局 | 状态框缩小、保留图标底色、生命护盾合条、思考泡泡、产码收拢、破解操作强化 | 已授权修改，当前效果待评审 |
| 2026-10-08 | 当前概念、组件和必要实机证据 | 保留当前版本与必要证据（推荐） | 留存收尾授权，不自动批准视觉 |

临时编号已分配上限002；当前concept上限001、asset上限001。来源tmp_001→concept_001、tmp_002→asset_001，不复用临时号。旧错误概念styleboard-draft.png（1,923,605字节，SHA 1ad194e8566ec0fd35df84e3a94af964fb743291b8681d1a320a9d99dbd9a6e6）及旧trial/compact/vitals截图、重复交付ZIP按本次决定删除；历史失败原因和提示词保存在概念generation.md。不曾提交的草稿不宣称可从Git恢复。

## 当前留存与依赖

- 概念：design/concepts/battle-status-components/hud-family/concept_001/styleboard.png，1448×1086 RGB、1,863,661字节，SHA 22eb41470ed5959d958e47c0ab5fb89106931e38c04a6f3c9ee0fd11cea3abcf；保留完整生成记录与metadata。
- 组件源：同层asset_001，15份框／填充／节点SVG＋11份图标SVG、26份2×RGBA PNG、8份相对引用StyleBoxTexture；保留可编辑源、元数据、生成记录、制作脚本和可重建预览场景。没有概念裁图、烘焙文字、外部图标包或新人物／敌人动作。
- 稳定运行子集：assets/art/ui/battle_status；源纹理与样式逐字节一致，运行布局归components.json的runtime_layout。文字、数值与状态来自原模拟，不读取design截图。
- 登记：assets/art/manifests/battle_status_components.yaml；主Manifest加载该子表，concept批准、asset review、integration authorized_active分开记录。
- 必要证据：review/codex-workflow/下asset-family、feedback、programs、playback、debug及final-status截图；只供评审／验证，不在运行资源或资源台中登记。旧实施档案中的trial/compact/vitals路径为历史证据，已按留存决定清理，以本节当前截图为准。

## 设计修订依据

概念初稿曾把盾量与全队吸收混同、堆叠三条计时／状态条；修正版纠正后被选定。正式组件用SVG原生几何复刻所选视觉家族；原生字体与数值避免AI烘字。运行试用后按用户反馈缩为细生命／行动条与图标节点；生命独立刻度、右侧盾段、数字居中，敌人意图改为身体旁思考泡泡。库存为顶部辅助单行，破解卡作为底部主操作；三格完成→收拢→类型徽亮→代码飞向库存。当前画面和逻辑入口为原Campaign，不新建平行战斗。

## 技术验收与边界

2026-10-08，PowerShell7 / Godot4.7.2 Compatibility：HUD105／0、反馈链实机15／0、破解布局三尺寸67／0、播放实际输入51／0、页面清理64／0、调试无头74／0及实机86／0；产码队列33／0与原两条起始链133／0见COMBAT-02，最新入口与覆盖范围见UI-02／verification。源包原生导入26SVG、15框／8样式直接加载零失败；尺寸、Alpha及无文本XML检查归delivery-validation.json。收尾移动后再核验Godot加载、源／运行一致与全库Manifest，结果在下方补充。

保留决定只完成归档和提交边界；资产与最终接入效果不升级approved。未验证移动端、Web导出、实体手柄或任意极端拥挤。人物、敌人动作只复用其他专门会话已有资产。


留存后复验（2026-10-08，e15be65＋本阶段工作树）：status_hud_check.tscn -- --capture 105／0，三尺寸、真实意图／详情输入和密集盾队截图为final-status-*；AssetCatalog全库53对象／1526文件，0缺失、0不一致、0错误，HUD133登记文件全部匹配。60份SVG／PNG／StyleBox源与运行逐字节相同，批准概念SHA匹配，无tmp目录。运行副本仅保留实际组件与元数据，完整生成／校验记录归asset_001。登记核验记录为review/codex-workflow/retention-validation.json。未扩大到移动端或全量旧玩法套件；视觉评审状态不变。

留存后的组件预览再次运行26 vectors／0 failures（.godot/hud-retained-assets.log）。SVG统一LF并重算交付哈希，以与Git文本规范化一致；源／运行60份文件仍逐字节一致。
