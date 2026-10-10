# 验证入口与证据规则

本页维护共用执行方式，各领域的结果和覆盖保存在同目录验证页。本次整理基线d99750b；旧M0检查是历史验收，不能用旧PASS证明现行战役和双流派通过。

## 运行方式

在仓库根目录用PowerShell7执行，引擎路径可按本机修改：

```powershell
$engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
& $engine --headless --path . --quit-after 3000 --log-file .godot/check.log res://game/combat/action_check.tscn
```

图形检查移除--headless并加--rendering-method gl_compatibility，用户参数放在--之后。检查明确完成标记、失败数与脚本错误，不能只看退出码。每个测试用独立.godot档案；缓存和可重建截图不入Git。正式人工批准由对象当前说明与Manifest维护，不靠测试推断。

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
