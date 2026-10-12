# 校园区域流程配置

区域流程在 Godot 检查器中维护；校园地图编辑器负责空间布局。两者通过地标 ID 关联。继续使用原探索、热点、战斗、领奖和终端结算，不新增人物、敌人、动作或事件池。

## 概念与职责

- 区域：一次探索的整体，目前仅图书馆、第二终端、第三终端。
- 地点：共享空间定义，包含显示名称、已有背景、地标和偏移。
- 探索站点：流程中的一次停留，引用地点、已有敌阵及热点模板。它有区域内唯一 ID，同一地点可被不同站点或区域引用。

Stages 数组的顺序就是站次；一个 Stage 的 Choices 是互斥岔路，完成其中之一后进入下一站。最后一站为终点。游戏连线按该流程生成；浏览器的“路径拐点”仅负责选区展示线，“关联地标”不安排游玩顺序。

## 最快开始

1. 在 Godot 文件系统打开 `res://resources/campaign/regions/`，双击 `library.tres`。另两个区域为 `region_b.tres`、`region_c.tres`。项目已启用“校园区域流程”插件；已有编辑器窗口若未扫描新类，请重新打开项目。
2. 检查器顶部显示“探索流程概览”。展开 **Stages**，用数组项拖动手柄调整站次；展开某站的 **Choices** 查看候选。
3. 展开候选引用，或双击 `resources/campaign/stops/<区域>/<站点>.tres`。**Place** 引用地点；**Encounter** 拖入已有敌阵；**Power** 设置战斗强度。
4. 点击“校验”。它会报告空项、重复 ID、缺失地标、未注册敌阵、无效背景或强度。修改子资源后再次校验即可刷新概览。
5. 点击“流程预览”，在校园全图查看站次和分支，点击清单或地图站点查看内容引用。这个入口包含当前检查器中未保存的修改，缓存仅写入 `.godot/campus-flow-preview.json`。
6. **保存资源，停止运行，再从原游戏入口重开探索**。预览不替你保存 `.tres`；已运行的游戏可能缓存旧资源，正式新探索读取资源配置。

独立预览：打开 `res://scenes/content/campus_flow_preview.tscn` 后按 F6。下拉框切换区域，“刷新配置”重新读取磁盘中的区域及引用资源。独立预览会先采用最近一次检查器预览缓存；切换区域或刷新即回到已保存配置。预览不读写玩家存档、不执行战斗、不发奖励。

## 修改顺序、增加站次与分支

- 调整顺序或删站：移动／删除 Stages 整项。最后一项自动成为区域终点，但移站不会自动替换它引用的敌阵。
- 添加站点：在 `resources/campaign/stops/<区域>/` 复制一个站点 `.tres`，改文件名、Resource Name 和 **Id**，替换 Place、Encounter 并调整 Power。Id 使用英文小写、数字、下划线，在区域内唯一，例如 `lake_detour`。
- 添加一站：Stages 增加一项，选择“新建 CampusRouteStage”，在它的 Choices 中拖入站点文件。
- 添加岔路：只在既有站次的 Choices 中增加另一个站点引用。仅创建文件不会自动加入流程。
- 复制一个 Stage 时，站点引用可能仍共享；要独立修改候选，请先复制站点文件并替换引用。

第一版支持 1～12 站、每站 1～4 个候选，按站次单向推进。相邻两站的候选全部互通：第二站 A/B、第三站 C/D 时，A、B 均可前往 C 或 D。不支持 A 只通 C、B 只通 D、跨站跳转、回头或循环。末站可有多个候选，完成其中一个即可沿用原终端结算。每次访问仍须守卫胜利并领取奖励才能离开。

## 调整地点

地点资源位于 `resources/campaign/places/`。**Landmark＋Offset** 得到地图位置：Landmark 对应浏览器地图地标的英文 ID，Offset 使用 1800×1500 原图坐标。移动地标会带动所有引用它的地点；仅移动一个地点时改该地点的 Offset。

Background Id 选择现有校园背景。Library Interior 启用原图书馆室内与照片交互，路线预览仍显示正面。修改共享地点会影响所有引用者；要独立位置或名称，先复制地点资源、改 ID，再替换站点的 Place。地点不包含玩家访问状态。会堂商业街在地图导览中展开成电会堂／商业街两个图标，共用同一站点Choices和原进入动作；新增图标不会新增访问／战斗站次。精确旧占位快照的落点可由表现层校正；后续自定义Landmark／Offset仍有效。

## 字段与内容边界

| 资源 | 字段 | 含义 |
| --- | --- | --- |
| CampusRegionFlow | Id / Display Name / Revision | 已有区域身份、标题、修订号；修订号不代替保存 |
| CampusRegionFlow | Stages | 顺序站次，末站自动为终点 |
| CampusRouteStage | Choices | 本站互斥候选 |
| CampusRouteStop | Id / Place | 唯一访问身份、共享地点引用 |
| CampusRouteStop | Encounter / Power | 已注册敌阵、0.1～3 强度系数 |
| CampusRouteStop | Hotspot Template | 原七种热点／回忆模板引用 |
| CampusRoutePlace | Landmark / Offset | 地标引用与偏移 |
| CampusRoutePlace | Background Id / Library Interior | 已有背景与图书馆室内行为 |

Hotspot Template 沿用 `gate/walk/court/hall/library/end_b/end_c` 的原热点及等级开放规则；改站点 ID 不会生成新的永久回忆定义。多轮正文、选项、条件和结果仍维护于 `resources/content/events/hotspot_dialogues.json`。此处不新增事件池编辑，也不复制人物、敌人、技能和动作。

## 开发阶段与验证

按负责人要求不兼容旧探索检查点。Journey 使用 schema 2，首次更新后如有旧活动探索，请通过基地菜单的“重开存档”重新开始（会重置永久进度，原文件由现有重开流程备份）；不自动删除永久档案或地图布局。新格式正常保存、退出、续玩使用原检查点入口，保存本次流程和原访问／战斗／奖励状态。

专项入口：Godot `--headless --path . scenes/content/campus_flow_preview.tscn -- --flow-preview-check`。GUI 改用 `--rendering-method gl_compatibility` 并追加 `--capture`。覆盖现行三区域、非法配置、五站原主线推进、敌阵／强度引用、真实 JSON 往返和预览投影／命中。

完整原战役：`scenes/expedition/expedition.tscn -- --campaign-flow-check --order=012`。没有任意图跳转、事件池编辑、存档迁移或新校园内容的验收承诺。
