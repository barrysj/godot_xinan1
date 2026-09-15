# 共享验证目录

> 记录来源：2026-09-14 初始统筹与后续 M0 功能验收，整理截至 2026-09-15。此次迁移未重跑测试。功能状态以各功能档案为准；本文件只维护跨功能共用检查入口，避免命令和结果复制多份。
>
> `audit-20260914-*` 为初始盘点日志命名，不能推定同名缓存已包含后来修复的 PASS；M0 结论以原功能提交、正式主题文档与重跑结果为依据。缓存缺失时重新验证，不补造永久证据。

2026-09-15 美术分支合并后的专项重跑另见 [E19](#美术集成验证-e19)，不覆盖未重跑的 M0 和发布结果。

引擎：`F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe`。在仓库根目录通过 PowerShell 7 运行：

```powershell
$engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
& $engine --headless --path . --log-file .godot/audit-20260914-action.log res://game/combat/action_check.tscn
# 按下表替换场景和参数；用户参数放在 -- 后。
# 图形检查移除 --headless，加 --rendering-method gl_compatibility。
```

探索简称指 [expedition.tscn](../../scenes/expedition/expedition.tscn)；测试进入独立 `.godot/` 档案，未操作玩家 `user://` 存档。图形检查中断或断言失败时不能只看进程退出码，应核对完成标记。

| 证据 | 场景／用户参数 | 最近登记结果与范围 | 日志后缀 |
| --- | --- | --- | --- |
| E01 | [action_check.tscn](../../game/combat/action_check.tscn) | PASS，failures=0；前后摇、死亡取消、弹道、同时结算、高攻速 | action |
| E02 | [auto_battle_check.tscn](../../game/combat/auto_battle_check.tscn) | PASS，failures=0；寻路占位、射程、换目标、暂停倍速 | auto |
| E03 | [deployment_check.tscn](../../scenes/battle_demo/deployment_check.tscn)，`--deployment-check` | PASS，failures=0；真实 Viewport 输入、点击立即部署／换人／换位、部署菜单空白收起、交换来源发光与自身格／右键取消、拖拽、撤回、部分部署恢复与下场沿用 | deploy |
| E04 | 探索，`--run-smoke` | PASS；三条固定兼容路线完成，资源 7/9/7；首战部署、后续沿用、奖励、恢复、续玩、候补、重试、结算 | run |
| E05 | 探索，`--meta-smoke` | 67 checks，failures=0；成长生效时机、迁移、检查点、离线派遣、回滚 | meta |
| E06 | 探索，`--map-check` | PASS；地点浏览、缩放拖动、详情空白关闭、锁定交互 | map |
| E07 | 探索，`--dispatch-check` | 36 checks，failures=0；多人校验、交易、旧任务迁移和 UI | dispatch |
| E08 | 探索，`--journey-check` | 17 checks，failures=0；出发到达、进度、领取、返程与失败回滚 | journey |
| E09 | [presentation_check.tscn](../../scenes/battle_demo/presentation_check.tscn) | PASS，failures=0；插值、动作同步、不同帧率／倍速统计一致 | presentation |
| E10 | [authored_assets_check.tscn](../../scenes/battle_demo/authored_assets_check.tscn)，`--require-two-models` | models=2，failures=0；真实图集与七动作元数据，不是美术审批 | assets |
| E11 | [skill_vfx_check.tscn](../../scenes/battle_demo/skill_vfx_check.tscn) | failures=0；护盾出手一次、暂停倍速、回收与收尾 | vfx |
| E12 | [battle_ui_check.tscn](../../scenes/battle_demo/battle_ui_check.tscn)，`--deployment-check` | failures=0；侧视投影、角色详情、装备弹窗空白关闭与操作后自动关闭、背包装卸转移、存档、战中只读 | ui |
| E13 | 探索，`--random-check`，图形 | PASS：200 种子生成 197 种地图、146 种奖励序列；40 路径、156 场战斗，四次失败均经战报→重配→重试获胜；待选奖励磁盘恢复通过 | random |
| E14 | 探索，`--content-check`，图形 | `CONTENT_CHECK_COMPLETE`；装备、共享技能隔离、字符串身份、事件交易、冻结快照、旧档及非法资源拒绝 | content |
| E15 | 探索，`--team-check`，图形 | PASS；地图／战斗面板、换装卸装、详情空白关闭、候补、阵容保存、只读和 Esc 恢复 | team |
| E16 | 探索，`--pause-flow-smoke`，图形 | PASS；关闭窗口确认取消、主菜单返回、Play 再入及退出动作 | pause-flow |
| E17 | [menu.tscn](../../scenes/menu/menu.tscn)，`--codex-check`，图形 | PASS：35 条图鉴逐项浏览；真实部署四人并开战后，从暂停进入图鉴时状态冻结，Esc 返回暂停，继续后战斗时间恢复推进 | codex |
| E18 | `build-web.ps1` release 包，Codex 应用内浏览器 | PASS（桌面范围）：完整五层路线、暂停恢复、结算与离开；Boss 前刷新恢复；修复后奖励／开战后立刻刷新分别恢复最新地图／同场战前 4/4 阵容。844×390 可进入和点选但文字与确认控件过小 | web |

E13 原失败均位于 stage=4：seed/path 为 `1/1`、`4/0`、`4/1`、`4/2`。定向枚举证明四条路径无需改变奖励或敌人数值，只需把默认站位中的应援者与冲刺手前后互换即可获胜；根因是旧检查把单一固定站位必胜误当作路线可完成。现检查保留默认站位首战，失败时必须走真实战报、重新部署和重试，再以替代站位获胜；胜利与路线完成断言未删除，且补跑了此前被提前退出遮断的磁盘恢复。该结果不替代真人难度与公平性数据。

E17 原夹具在 `_enter_node()` 清空部署后直接 `_start()`，被四人开战门槛拒绝。现通过实际部署组件依次部署四人，并在打开暂停前断言已进入战斗且时间推进；随后对图鉴冻结、关闭回到暂停及继续恢复逐项断言。原失败属于夹具前置过期，产品暂停／图鉴恢复行为在当前检查范围内正常。

所有引擎运行有根证书存储错误，部分有编辑器原图加载警告；通过项指专项断言通过，不是“引擎零报错”。`pixel_battle.gd::_load_atlas()` 已区分 editor 原图与导出 `load(Texture2D)` 路径，摘要所称“必须修复否则导出不可用”证据不足。M0 当前 Web 包已验证资源加载；其他平台不外推。

## 美术集成验证 E19

- 日期：2026-09-15；基线：main `1a2948e`、粉笔 `b661bad` 与资源台 `c44a862` 的合并树（首个合并提交 `17f7136`，最终合并见 Git 历史）。
- Python：`py -3 -B -m unittest discover -s tools/art/asset_manager/tests -v`，11 tests PASS；八对象、71 文件，无缺失或哈希不一致。包含真实内容修改的哈希拒绝检查，不更新登记基准。
- Godot：以本文件 `$engine` 命令运行 `game/combat/action_check.tscn`、`scenes/battle_demo/presentation_check.tscn`、`scenes/battle_demo/skill_vfx_check.tscn`、`scenes/battle_demo/deployment_check.tscn -- --deployment-check`；分别出现 ACTION_CHECK、PRESENTATION_CHECK、SKILL_VFX_CHECK、DEPLOYMENT_CHECK 的 `failures=0`。覆盖动作时序、表现同步、粉笔弹体/旧护盾回退及 main 的部署行为。
- 动作：`pwsh.exe -NoProfile -File ./run-motion-preview.ps1 -Check -Unit res://resources/content/enemies/chalk.tres -Animation res://resources/content/animations/chalk.tres`，七种受支持模式 PASS，近战 SKIP，`MOTION_PREVIEW_CHECK failures=0`。
- 渲染：将上述 `-Check` 替换为 `-Capture`，完成 1920×1080、2560×1440、1920×1200，日志有三个 `MOTION_PREVIEW_CAPTURE`；截图为 `.godot/motion-preview-3-<分辨率>.png`。
- 页面：`pwsh.exe -NoProfile -File ./run-art-manager.ps1 -Port 8771 -NoOpen` 冷启动成功；8770 同项目验收页显示八对象/71文件/0不一致，实际点击弹体预览启动粉笔 Unit、005 Animation 与001 Projectile，未回退默认对象。截图 `.godot/art-merge-overview.png`、`.godot/art-merge-preview-launch.png` 为本机缓存，不是跨 checkout 唯一证据。
- 修复范围：启动器 v2 健康标识、旧六对象测试假设、登记文本字节被 Git 换行转换的问题；详见 [ART-05](art-05.md)。没有重写哈希或改变资产批准状态。
- 边界：既有原图加载警告及无头环境证书警告仍存在；未重导出 Web、未重新验收全套 M0/手机/真人体验。美术批准继续以任务与 Manifest 为准。
