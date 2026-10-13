# 验证入口与证据规则

本页维护共用执行方式，各领域的结果和覆盖保存在同目录验证页。本次整理基线d99750b；旧M0检查是历史验收，不能用旧PASS证明现行战役和双流派通过。

## 运行方式

在仓库根目录用PowerShell7执行，引擎路径可按本机修改：

```powershell
$engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
& $engine --headless --path . --quit-after 3000 --log-file .godot/check.log res://game/combat/action_check.tscn
```

图形检查移除--headless并加--rendering-method gl_compatibility，用户参数放在--之后。检查明确完成标记、失败数与脚本错误，不能只看退出码。每个测试用独立.godot档案；缓存和可重建截图不入Git。正式人工批准由对象当前说明与Manifest维护，不靠测试推断。

## 检出／合并后的本地导入

工作树通过测试不代表另一个main checkout的Godot缓存已更新。首次检出、合入新增脚本类型／图片资源后，命令行直接启动前应在实际目标工程执行一次编辑器导入；也可在Godot编辑器打开该工程并等待扫描／导入完成，再运行。已有编辑器仍保留旧解析状态时重新打开项目。不要为了绕过未导入而删除类型声明、改名字段或替换合法SVG。

```powershell
$engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
$importLog = Join-Path (Get-Location) '.godot/merged-import.log'
$startupLog = Join-Path (Get-Location) '.godot/merged-startup.log'
& $engine --headless --editor --import --path . --quit --log-file $importLog
& $engine --headless --path . --quit-after 5 --log-file $startupLog res://scenes/expedition/expedition.tscn
if (Select-String -LiteralPath $startupLog -Pattern 'SCRIPT ERROR:|Failed to load script|has no resource loaders') {
    throw "Merged project startup failed: $startupLog"
}
```

Godot可能在脚本编译失败时仍退出0，必须检查启动日志。新增全局类型需要当前checkout的`.godot/global_script_class_cache.cfg`，SVG需要本地导入元数据与`.godot/imported`衍生纹理；这些缓存不提交Git。合并验收应在实际目标checkout完成导入与主入口启动，而不只沿用功能分支的缓存和测试。`--check-only --script`不会完整建立项目autoload，不用它代替原玩家场景的启动检查。

## 按领域验证

- [战役／地图／流程编辑](../campaign/verification.md)
- [战斗／构筑／人物播放](../combat/verification.md)
- [界面／选择页／菜单](../ui/verification.md)
- [资产／工具／闪卡](../art/verification.md)
- [存档与派遣](../progression/README.md)、[内容录入](../content/authoring.md)、[平台发布](../release/README.md)：检查命令在对应功能档案和操作说明，不复制第二份结果表。

## 旧M0检查

M0在7fe7529有短局、部署、随机路径、成长／派遣和桌面Web历史验收；如今入口、规则、奖励与动画均已扩展。旧deployment_check仍有入口夹具限制，旧全量规则检查不能宣称全部通过；按本领域最新主线专项重跑。E01～E59编号曾多次重复，现在使用明确场景与主题链接，逐次验收日志不再维护。Git可追溯旧文本，不恢复旧目录作为当前入口。

## 文档整理验证

2026-10-10、基线d99750b：tools/docs/check_links.py --project 检查41个功能ID和全部文档链接，错误0；检查器5项单测通过。资源台40项单测、地图编辑器12项测试与JS语法检查通过；git diff --check通过。只整理目录、内容与引用，不把目录整理算作真人、真机或发布验收。

最终清理核对基线37183a3之后：文档检查扩展到规则、工具与当前美术源说明；200份文档、41个功能ID、770个本地链接，错误0。资产字段和源包核验、现有动作检查边界见[美术验证](../art/verification.md)。用户既有expanded_campus_layout.json按SHA-256核对不变且不纳入本次提交。
