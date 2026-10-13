# Debug 战斗修改器

双击 `CampusDebugLauncher.exe`，点击“战斗试玩”。游戏内按 F8 或点击右上角“调试”，再点“战斗修改”。完整校园调试里的未结算战斗／战报也可以使用，需已部署四名同学。

## 可调整内容

- 六个敌方位置：图标显示实际敌人，悬停显示简要属性，点击后在右侧编辑。可从现有10种敌人中选择、设为空位或重复放置同一种敌人，至少保留一名。
- 战斗背景：跟随地点，或选择已有庭院日间／实验室夜间／教室异常图，右侧即时预览。
- 当前敌人：生命、攻击、防御、攻击间隔、射程、移速，均编辑最终战斗属性。
- 己方：生命、攻击倍率，在原阵容、装备和成长计算后应用。

打开时暂停战斗，编辑是草稿。“应用重开”提交草稿，恢复全体状态、清空本场统计并立即开战；“恢复默认”先恢复草稿，仍需点“应用重开”。“返回调试”或 F8／Esc 返回，未应用的编辑不影响实战。自定义属性启用时，普通难度选择禁用；恢复默认后重新开放，避免倍率与绝对属性混用。

这些设置只存在于当前 Debug 进程，绑定活动局、地点、站次／终局阶段和遭遇；进入另一场清除。关闭游戏后不保留。敌人 Resource、背景素材、原构筑、正常玩家档和存档 schema 均沿用现有定义，Release 拒绝修改器。

## 实现与验证

- `game/debug/battle_tuning.gd`：注册内容查询、输入校验、草稿快照、战斗作用域和应用／回退。
- `scenes/expedition/battle_tuning_panel.gd`：共享 Theme／颜色、敌方图标网格、属性面板和操作信号。
- `debug_panel.gd`：F8 页面切换、暂停和现有弹窗布局。
- `campaign_hub.gd`：仅 Debug 接入临时敌阵、背景与属性；`battle_demo.gd` 用遭遇获取接口继续交给原模拟和呈现系统。

先用原重开入口保存检查点，再应用参数并通过原开战入口重建。保存失败保留旧参数，原 Campaign 解码会省略临时战斗节点，修改器回退补回同一遭遇上下文；不生成另一套存档。敌阵改变在原单位初始化前完成，单位 ID／位置、技能、代码效果与动画仍来自原模拟。属性在原成长／装备／强度计算后作用于实例，不写共享资源。

内部回归命令：

```powershell
pwsh.exe -NoProfile -File tools/development/tests/battle-tuning.test.ps1 -EnginePath '<Godot console.exe>'
pwsh.exe -NoProfile -File tools/development/tests/battle-tuning.test.ps1 -Capture -EnginePath '<Godot GUI.exe>'
```

回归在真实原 Campaign 实例中操作 F8 和图标／应用按钮，覆盖草稿隔离、数值／背景生效、原模拟推进、重复敌人、反复应用不叠加、非法／非有限数拒绝、保存失败、默认恢复、地点切换和玩家档／资源不变。实际结果、基线和平台边界归 [DEV-01](dev-01.md)。图标尺寸使用共享主题常量，[Godot Button 契约](https://docs.godotengine.org/en/stable/classes/class_button.html#class-button-theme-constant-icon-max-width)。

本轮不提供永久资源编辑、预设导入导出、敌人技能创造或跨平台验收。
