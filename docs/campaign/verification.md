# 战役与地图验证

## 地点多场景与小地图

2026-10-11，基线 `78bb5b8` 加通行热点与紧凑场景栏修订。PowerShell 7 在项目根执行，下表省略公共参数 `--path .`；引擎路径见[共用说明](../development/verification.md)。

| 参数／入口 | 结果 | 覆盖 |
| --- | --- | --- |
| `--headless res://scenes/expedition/place_scenes_check.tscn` | 88／0 | 四张不同背景、非法配置、三区域通用配置、旧 Journey2 缺字段、JSON 往返、实际点击通行热点、封锁出口拒绝、单图地点回路线图、区域出口、教学目的地、楼层筛选、紧凑栏和长列表滚动、原调查及保存失败恢复、事件封锁 |
| `--rendering-method gl_compatibility res://scenes/expedition/place_scenes_check.tscn -- --capture` | 208／0 | 1920×1080、2560×1440、1920×1200；四场景与普通地点出口实机截图，控件包围框与热点遮挡检查；随后教学目的地文案补验包含于无头 88 项 |
| `--headless res://scenes/expedition/expedition.tscn -- --campaign-flow-check --order=012` | 149／0 | 原完整战役流程回归 |
| `--headless res://scenes/expedition/campus_playthrough_check.tscn` | 61／0（78bb5b8） | 原校园地点遍历、背景、热点与检查点回归 |
| `--headless res://scenes/content/campus_flow_preview.tscn -- --flow-preview-check` | 120／0（78bb5b8） | 配置资源及 JSON 快照完全往返；楼层数字恢复为整数 |

专项仅使用 `.godot/art-workflow/place-scenes/` 的隔离 profile；截图在同目录，正式交付预览随 UI 源包保存。守卫胜利是离场检查夹具，真实战斗由完整战役测试覆盖。初次导入需先运行 `--headless --editor --import --quit`；此工作树首次导入后方可运行。

运行日志仍有系统证书存储读取失败和原像素图集 Image.load_from_file 警告，不属于本功能脚本错误；上述完成标记均为 failures=0。UI、Manifest 与源包路径／格式检查通过，资源台 missing／mismatch／errors 为 0。仅桌面工程验证，未宣称真实建筑布局、真人体验、Web 或移动端通过。配置及新旧存档边界见[录入说明](flow-authoring.md#地点内多个场景)。

运行方式见[共用说明](../development/verification.md)。当前主线基线d99750b，既有运行结果不因文档搬迁重新计为新验收。

## 战役与访问

### 与完整地点地图导览整合

2026-10-13，`main` 基线 `301b838`＋`art/location-scenes` 三提交 squash 整合树。原生场景专项三尺寸 **218／0**、地图导览四尺寸 **511／0**、原 Campaign **149／0**、流程资源 **120／0**。更新旧界面断言，真实点击出口后检查最新 station_picker 绑定原 Journey，并截图 `route-return-*`；场景、楼层筛选、通道、旧检查点、保存失败及离场门槛继续通过。导览专项仍覆盖完整地理节点、当前站次权限、实验大楼(925,740)及会堂／商业街共用 end_c。

沿用上文相同入口与 Compatibility／headless 参数，日志位于 `.godot/art-workflow/place-scenes/integration-{scenes,campaign,flow,navigation}.log`，各专项使用隔离 profile。导览运行 `res://scenes/expedition/campus_navigation_check.tscn -- --capture`（Compatibility，quit-after 5000），其截图仍位于 `.godot/art-workflow/navigation-ui/`。三尺寸场景截图和出口返回截图已实际查看；最终无 Script／Parse 错误。原系统证书、shader缓存权限和Kenney直接读图告警仍存在。合入保留 `301b838` 的完整地点导览及地标配置，未扩展Web、手机或实体手柄验收范围。

### 原生热点布局与探索反馈

2026-10-11，基线 `e4da771` 加本次实现；PowerShell 7／Godot 4.7.2。最终三尺寸 GUI 专项 `place_scenes_check.tscn -- --capture` 为 **215／0**，完整战役 `expedition.tscn -- --campaign-flow-check --order=012` 为 **149／0**。命令公共参数为 `--path . --quit-after 3600 --log-file <绝对日志路径>`；GUI 加 `--rendering-method gl_compatibility`，战役用 `--headless`。

原生流程配置回归 `--headless res://scenes/content/campus_flow_preview.tscn -- --flow-preview-check` 为 **120／0**（`layout-authoring.log`），覆盖从磁盘深度重载后校验／预览；背景一致性按资源路径判断，避免相同文件的不同 Texture2D 实例被误报。文档链接检查195份文档、868个链接，错误0；`git diff --check` 通过。

覆盖 Marker2D 移动到快照、越界坐标与漏配守卫拒绝、按场景显示、通道名称真实点击、场景画板实例保留、楼层筛选保留、方向键跨热点／地图、当前场景点击不重播转场、原快照 JSON 往返与保存失败回退。三尺寸为1920×1080、2560×1440、1920×1200；截图／隔离档／日志位于 `.godot/art-workflow/place-scenes/`，截图 `atrium-*`、`shelves-*`、`corridor-*`、`entrance-*`，最终日志 `layout-gui.log` 与 `layout-campaign.log`。最终运行无 Script／Parse 错误，保留既有证书与像素图集警告。

原生布局场景已导入并通过实例化／移动坐标检查，未冒充人工逐节点拖拽体验验收；实体手柄、Web、移动端未验。提示音实现为短程序化 UI 音，未作真人听感验收。编辑指南见[原生布局录入](flow-authoring.md#在-godot-中拖动热点与通道)。

最近2026-10-10主线合并：expedition.tscn -- --campaign-flow-check为149／0，流程预览120／0，tools/game_launcher/legacy/run-debug.ps1 -Check174／0。地点检查134／0；三地区顺序、永久解锁、重复结算及终局按原场景覆盖。真实纪念内容、60～90分钟、最新Web和手机仍待验。

campus_playthrough_check.tscn覆盖15处地点与12张背景：无头61／0、三尺寸GUI105／0。它会为视觉遍历设置守卫结果，不代替真实战斗；后者由完整战役与starting_strategy_check覆盖。地图GUI检查使用expanded_campus_preview.tscn -- --expanded-map-check，按当前场景的完成标记判断。

## 区域流程与地图工具

## 区域流程资源与编辑器分工

2026-10-09，基线 `10fb33b` 加 `codex/campus-flow-config` 工作树；PowerShell7／Godot4.7.2 console／Node。下面Godot参数在 `--path . --quit-after 3000 --log-file .godot/<检查名>.log` 之后使用。所有探索测试使用 `.godot` 隔离档，不写玩家档。

| 入口与参数 | 结果 | 覆盖 |
| --- | --- | --- |
| `--headless scenes/content/campus_flow_preview.tscn -- --flow-preview-check` | 120／0 | 三区域资源、真实JSON、五站原控制器、配置错误及原主线状态保护、检查器校验与禁用、12站清单和重访 |
| 同入口改 `--rendering-method gl_compatibility`，用户参数加 `--capture` | 154／0 | 1280×720、1920×1080、1920×1200三桌面尺寸，三区域投影／命中／引用，五站原主线画面与长列表 |
| `--headless scenes/expedition/expedition.tscn -- --campaign-flow-check --order=012` | 149／0 | 原序章、派遣、三区域、领奖、终局、结算与恢复 |
| `--rendering-method gl_compatibility scenes/battle_demo/starting_strategy_check.tscn -- --capture` | 151／0 | 两套真实出发队伍、当前多轮人物交谈、10场实际战斗、冻结阶段JSON、临时／永久编队与奖励 |
| `--headless game/run/location_check.tscn` | 134／0 | 地点、热点及原检查点 |
| `--headless scenes/expedition/campus_playthrough_check.tscn` | 61／0 | 原校园地点／回忆交互 |
| `node --check tools/campus-map-editor/editor.mjs`，`node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs` | 语法通过，11／0 | 布局、几何、服务身份、读取、坏数据／并发覆盖拒绝、隔离保存与备份 |

Godot `--headless --editor --path . --quit --log-file .godot/campus-flow-final-import.log` 完成资源／插件导入，无脚本错误；退出仍有既有EditorSettings shutdown_adb_on_exit错误，不能把退出0称为无报错。运行检查仍有本机根证书和Kenney直接读图告警，没有最终Script／Parse错误。当前多轮人物事件已替代旧独立formation按钮，起始检查按真实事件按钮完成，不削弱战斗胜利与编队恢复断言。

实际浏览器127.0.0.1:8767核对地图选区切换、资源路径、路径拐点说明与配置指南；不保存或改动用户布局。GUI截图 `.godot/campus-flow-{library,region_b,region_c}-{1280x720,1920x1080,1920x1200}.png`，原主线五站截图 `.godot/campus-flow-main-five-stops-2560x1440.png`，已查看并在对话展示；本地验收缓存不入库。

边界：五／12站是明确的原内容夹具，五站遍历由测试设置胜利／领奖标记，不代表自然胜率；真实10战另由起始检查模拟。预览不执行战斗／发奖励／读写玩家存档。仅按站次前进、分叉后相邻层互通，未提供任意有向图。检查器组件按钮与插件导入已验，未逐字段鼠标录入原生Inspector；Web导出、触控和真人编辑可用性未验。负责人要求不做旧Journey兼容，当前schema2，旧活动探索需通过已有重开入口开始。

## 地图与编辑器

Node命令：node --test tools/campus-map-editor/editor-core.test.mjs tools/campus-map-editor/server.test.mjs；最新12／0。2026-10-09真实1280×720浏览器有侧栏切换、坐标拾取、保存／备份／并发拒绝与只读失败提示证据，用户布局字节保留；未验触控。旧分块拼接、树木位置和亮区每次微调的记录已删除，当前资产和源包见[校园图](../art/environments/campus-map.md)。

## 主工程合并后的资源导入

2026-10-13，实际main主工程E:/Documents/works/godot_xinan1、基线32cd09d。直接启动原expedition.tscn稳定复现scenes外部成员解析失败与scene.svg／passage.svg无资源加载器；Godot仍退出0，日志判错返回1。主工程缺少CampusPlaceScene全局类型缓存与两张SVG的导入记录。仅在该工程运行headless编辑器--import后，同一启动路径通过，未改玩法、类型字段或源素材；原生Compatibility三尺寸place_scenes_check.tscn -- --capture通过218／0，涵盖SVG通道、场景切换、小地图和返回当前地图导览。

截图在目标工程.godot/art-workflow/place-scenes/，日志为导入／启动／地点GUI；不入Git。执行方式及日志判错见[合并后本地导入](../development/verification.md#检出合并后的本地导入)。根证书、旧Kenney直接读图及编辑器退出EditorSettings告警仍为已有边界，最终运行无Script／Parse／依赖编译错误；未以本轮重新宣称真人或发布验收。


## 地图路线一致性

2026-10-15，基线 `742de3d` 加当前修正；核验编辑器数据、真实区域快照、节点表现和原保存／主线，并按负责人要求移除旧模板迁移与旧坐标纠偏。统一入口：

```powershell
pwsh.exe -NoProfile -File tools/development/tests/campus-map-sync.test.ps1 -EnginePath '<Godot console.exe>'
pwsh.exe -NoProfile -File tools/development/tests/campus-map-sync.test.ps1 -Capture -EnginePath '<Godot GUI.exe>'
```

| 检查 | 结果与覆盖 |
| --- | --- |
| `campus_map_sync_check.tscn` | 349／0；三区地标集合／坐标／标题、南门用途、背景复用与地点身份；当前格式全部站次的 route／visit／battle／report／reward 保留流程、构筑、访问及完成进度，JSON 往返稳定，教学／终局隔离；旧格式拒绝且不改写源数据 |
| `campus_flow_preview.tscn -- --flow-preview-check` | 120／0；原生资源、非法配置、五／12站边界、冻结快照与原控制器预览 |
| `expedition.tscn -- --campaign-flow-check --order=012` | 149／0；真实教学、三区守卫及奖励／保存、三阶段终局与回基地 |
| `campus_navigation_check.tscn -- --capture` | 555／0；1920×1080、2560×1440、1920×1200、1280×720，真实鼠标／键盘／缩放拖动、全部地标、当前／未来地点、会堂商业街共享一站、无残留南门文案，截图已查看并在聊天展示 |
| 编辑器 `editor-core.test.mjs`／`server.test.mjs` | 隔离8877端口13／0；新增区域唯一映射、原文件读写、并发拒绝、备份和错误提示。服务只用于检查，结束后关闭 |

源码布局 SHA-256 仍为 `826e443c1b89ffe32f3147a87e4f848d8dac1b5da48a88fcdfe6010c95f037ee`，未修改地标、边界、拐点、亮区或三态底图。编辑器与路线编辑仍分离，本次为数据校正与一致性校验；不支持旧探索迁移，不自动重置永久档。功能边界见 [CORE-02](core-02.md)；不代表新地点独立美术已制作、真人平衡或其他平台验收。截图仍在忽略的 `.godot/art-workflow/navigation-ui/`。

## 两人队伍与必定会合

2026-10-14，基线3d9a29f＋两人队伍改动：`Godot 4.7.2 --headless --path . --quit-after 1000 res://scenes/expedition/party_progression_check.tscn`为97／0；GUI移除headless，加`--rendering-method gl_compatibility`及`-- --capture`，97／0。隔离档均在.godot下。两条推荐队各实际打完四站，人数2/3/4/4；断点、招募保存失败、重复动作、冻结资格、非法阵位和终局四人均验证。自动策略为核心可用即施放、低血修复、首项合法奖励，不是随机胜率或真人平衡结论。实际截图按party-departure、party-meeting、party-formation前缀保存在.godot。会合／准备美术包装尚待同任务后续阶段。

原主线回归同期已随规则更新测试入口：`expedition.tscn -- --campaign-flow-check`为150／0，涵盖序章、教学交易、三区域四站与三阶段终局；`starting_strategy_check.tscn`为142／0，涵盖两条起始链真实按钮、程序首发、教室预警释放或在截止前被击败取消、奖励与存档。新普通探索不会再使用旧默认双核心程序夹具，未指定策略的内部新局入口采用护盾推荐。推荐招募站位按近战前排、远程／支援后排选择空格，玩家仍能修改。
