# 战役与地图验证

运行方式见[共用说明](../development/verification.md)。当前主线基线d99750b，既有运行结果不因文档搬迁重新计为新验收。

## 战役与访问

最近2026-10-10主线合并：expedition.tscn -- --campaign-flow-check为149／0，流程预览120／0，run-debug.ps1 -Check174／0。地点检查134／0；三地区顺序、永久解锁、重复结算及终局按原场景覆盖。真实纪念内容、60～90分钟、最新Web和手机仍待验。

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
