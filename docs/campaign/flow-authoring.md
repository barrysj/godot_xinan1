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

### 地点内多个场景

每个 CampusRoutePlace 的 **Scenes** 数组可配置最多 12 个 CampusPlaceScene。第一项是进入地点时的默认场景；留空时沿用原背景，旧单图地点无需改配置。图书馆已配置中庭、书架区、窗边走廊、馆前广场四个场景，其他地点同样支持此结构，目前仍保留各自原单图，缺失的第二张背景没有用复制图冒充。

- **Id**：地点内唯一的小写英文标识；**Display Name**：2～6 字的场景名。
- **Background**：拖入 assets 目录内的 Texture2D。场景保存具体纹理路径；校园路线预览仍由地点 Background Id 决定。环境日／夜／异常变体不是不同房间，不自动混为场景。
- **Map Position**：0～1 的相对平面位置；**Floor**：-3～12 的整数，0 为地面、负数为地下、正数为楼层。颜色由楼层稳定派生，文字始终显示楼层。坐标只表示示意布局，不承诺建筑实测；录入时避免节点或名称过密，在实际界面检查全部楼层和单层视图。
- 玩家点击底部场景按钮、小地图或门形通行热点切换；左下场景栏标注“探索场景”，宽度随内容收拢，超出画板才滚动，没有上一处／下一处按钮。小地图楼层筛选只改变显示。各场景共用同次地点访问的调查、守卫和奖励状态，不重新抽取或增加战斗，不改变离场条件。
- 通行热点按 Scenes 数组顺序前往后续场景；最后一个场景（含单图地点）的热点成为出口，普通地点返回路线图，区域末站沿原区域结算，序章教学回基地。出口仅在守卫胜利并领奖后解锁，未解锁时置灰、加锁并在悬停提示原因。通行只派发原 scene／leave 动作，不新增访问热点快照；支持按房间分配调查热点，不支持自定义通路图或门锁规则。
- 新探索冻结场景定义，当前 scene_id 随原检查点保存；战斗、奖励、事件期间拒绝场景切换，保存失败沿原控制器恢复。已有 Journey2 缺少 Scenes／scene_id 时沿用原单图／默认场景，保留原冻结定义；想使用新配置需开始一次新探索，不需要重置永久档案。更旧 Journey schema 的边界不变。

改完在区域检查器执行“校验”并保存，再开始新探索。重复 ID、无效纹理、非法坐标或楼层会被拒绝。程序入口为 `game/content/campus_place_scene.gd`、`game/run/place_scenes.gd`、`scenes/expedition/place_scene_navigation.gd`；专项验证见 [验证页](verification.md#地点多场景与小地图)。

### 在 Godot 中拖动热点与通道

采用原生 `.tscn`＋`Node2D`＋`Marker2D`，不需要安装额外编辑插件。示例入口：[中庭布局](../../resources/campaign/layouts/library/atrium.tscn)，同目录的 shelves／corridor／entrance 分别为书架区、窗边走廊、馆前广场。

1. 在 Godot 文件系统双击布局 `.tscn`，切到 **2D**。背景按 1920×1080 参考画布显示，粉色半透明区域表示主要 HUD 避让区。
2. 在场景树选中 `person`、`memory`、`system`、`battle` 或 `passage` 标记，使用移动工具拖动；也可在检查器 **Transform → Position** 输入精确坐标。圆圈表示热点参考范围；通道还需为名称留出下方空间。不要移动、缩放或旋转根节点。
3. 标记名决定用途：`person`＝伙伴，`memory`＝记忆，`system`＝终端，`battle`＝守卫，`passage`＝通道。仅显示当前房间拥有的标记；标记不创造事件，同类型仍引用本次地点访问的原热点及共享完成状态。直接子节点使用这些固定名字，勿嵌套或改成其他名称。
4. 每间房必须保留一个 `passage`。其他四类可分散在不同房间；所有房间都使用布局时，地点整体必须覆盖四类，兼容不同等级开放内容，尤其不能漏掉守卫。新增标记可复制现有 Marker2D 并改成所需名字；同一房间每类限一个。
5. 为新场景复制一份布局，在根节点 **Background** 换图；在地点 `.tres` 的对应 **Scenes → Layout** 拖入新布局，并将 **Background** 设置为同一张图。根节点与场景背景不一致、未知标记或越界坐标会被流程校验拒绝。Layout 留空的场景保留原通用布局和全部热点。
6. Ctrl+S 保存布局和地点资源，在区域检查器执行“校验”，停止游戏后开始一次新探索。已保存探索继续使用冻结的坐标快照，避免修改开发资源改变玩家原有进度。

运行时按实际背景的居中裁切比例投影坐标，并为边缘保留点击安全区；极端边缘位置可能被安全区限制。示例尺寸之外仍应在实际窗口检查 HUD 遮挡。小地图的 **Map Position／Floor** 是独立的地点示意坐标，不随背景热点拖动。

切换场景保留楼层筛选与仍有效的焦点，背景短暂交叠；当前场景重复点击不保存或重播转场。通道图标和名称共用点击区域。小地图与场景栏悬停／焦点联动，连线表示数组配置的实际顺序通路，不表示建筑测绘。Tab 和方向键可遍历可见热点、通道、地图、场景栏和底部操作；详情的 Tab 循环留在详情内。

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
| CampusRoutePlace | Scenes | 地点内场景数组；空数组沿用旧背景 |
| CampusPlaceScene | Id / Display Name / Background / Layout / Map Position / Floor | 场景身份、纹理、原生热点布局、相对位置与楼层 |

Hotspot Template 沿用 `gate/walk/court/hall/library/end_b/end_c` 的原热点及等级开放规则；改站点 ID 不会生成新的永久回忆定义。多轮正文、选项、条件和结果仍维护于 `resources/content/events/hotspot_dialogues.json`。此处不新增事件池编辑，也不复制人物、敌人、技能和动作。

## 开发阶段与验证

按负责人要求不兼容旧探索检查点。Journey 使用 schema 2，首次更新后如有旧活动探索，请通过基地菜单的“重开存档”重新开始（会重置永久进度，原文件由现有重开流程备份）；不自动删除永久档案或地图布局。新格式正常保存、退出、续玩使用原检查点入口，保存本次流程和原访问／战斗／奖励状态。

专项入口：Godot `--headless --path . scenes/content/campus_flow_preview.tscn -- --flow-preview-check`。GUI 改用 `--rendering-method gl_compatibility` 并追加 `--capture`。覆盖现行三区域、非法配置、五站原主线推进、敌阵／强度引用、真实 JSON 往返和预览投影／命中。

完整原战役：`scenes/expedition/expedition.tscn -- --campaign-flow-check --order=012`。没有任意图跳转、事件池编辑、存档迁移或新校园内容的验收承诺。
