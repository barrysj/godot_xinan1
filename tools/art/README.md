# 美术工具目录

这些是开发工具，不是角色运行资产。日常入口仍在项目根：`run-art-manager-control.ps1` 打开资源台控制器，`run-motion-preview.ps1` 打开动作预览；只有加 `-ExportPreviews` 才生产 GIF。

| 目录 | 工具 | 用途 |
| --- | --- | --- |
| `animation/` | `motion_capture.gd` | Godot 隔离视口捕获动作，输出捕获清单和临时帧 |
| `animation/` | `motion_previews.py` | 准备捕获任务、按清单编码 GIF、登记 Manifest |
| `animation/` | `build_battle_frames.py`、`build_skill_frames.py` | 既有角色图集／护盾样本的构建工具；布局假设固定，不是任意图集自动识别器 |
| `migration/` | `bake_presentation.gd`＋`.tscn` | 将旧代码动画采样为场景与 AnimationLibrary；迁移时使用 |
| `migration/` | `compare_presentation.gd`＋`.tscn` | 用同一 context 比较迁移前后姿态；迁移验证时使用 |
| `promotion/` | `promote_animation.py` | 校验批准候选、复制允许运行文件、改写正式引用；`--check` 只校验 |
| `asset_manager/` | `catalog.py`、`server.py`、`static/` | Manifest 校验、HTTP 服务、资源台网页 |
| `asset_manager/control/` | C# 源码、构建与启动测试 | Windows 桌面控制器；根目录入口自动补建缺失／过期缓存 |
| `asset_manager/tests/` | Python 测试 | 资源台及与导出、提升之间的生产边界回归 |

`.gd.uid` 是 Godot 脚本的稳定身份文件，随脚本一起移动并保留；`.tscn` 是迁移工具的可运行入口。缓存、临时帧和 EXE 位于 `.godot/`，不提交入库。

## 验证与生产入口

```powershell
py -3 -m unittest discover -s tools/art/asset_manager/tests -v
pwsh.exe -File tools/art/asset_manager/control/test-launcher.ps1
pwsh.exe -File run-motion-preview.ps1 -EnsureImport -Check
py -3 tools/art/promotion/promote_animation.py chalk_spirit --check
```

完整导出命令和运行包契约见 [ART-03](../../docs/implementation/art-03.md)。迁移工具读取 JSON 设置，不包含角色专用公式；对照旧版本时需从 Git 提取原始实现，当前角色运行不依赖旧实现。
