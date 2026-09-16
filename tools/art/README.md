# 美术工具目录

这些是开发工具，不是角色运行资产。日常入口仍在项目根：`run-art-manager-control.ps1` 打开资源台控制器，`run-motion-preview.ps1` 打开动作预览；只有加 `-ExportPreviews` 才生产 GIF。

| 目录 | 工具 | 用途 |
| --- | --- | --- |
| `animation/` | `motion_capture.gd` | Godot 隔离视口捕获动作，输出捕获清单和临时帧 |
| `animation/` | `motion_previews.py` | 准备捕获任务、按清单编码 GIF、登记 Manifest |
| `animation/` | `build_battle_frames.py`、`build_skill_frames.py` | 既有角色图集／护盾样本的构建工具；布局假设固定，不是任意图集自动识别器 |
| `verification/` | `compare_presentation.gd`＋`.tscn`、`presentation_math.gd` | 同一 context 下比较任意两个兼容场景；不依赖迁移器，配置见下文 |
| `archive/legacy-animation/` | `bake_presentation`、`compact_cycles` | 一次性旧代码动画迁移，保留复现用途；不是新角色制作入口，见目录内说明 |
| `promotion/` | `promote_animation.py` | 校验批准候选、复制允许运行文件、改写正式引用；`--check` 只校验 |
| `asset_manager/` | `catalog.py`、`server.py`、`static/` | Manifest 校验、HTTP 服务、资源台网页 |
| `asset_manager/control/` | C# 源码、构建与启动测试 | Windows 桌面控制器；根目录入口自动补建缺失／过期缓存 |
| `asset_manager/tests/` | Python 测试 | 资源台及与导出、提升之间的生产边界回归 |

`.gd.uid` 是 Godot 脚本的稳定身份文件，随脚本一起移动并保留；`.tscn` 是 Godot 工具的可运行入口。缓存、临时帧和 EXE 位于 `.godot/`，不提交入库。

## 验证与生产入口

```powershell
py -3 -m unittest discover -s tools/art/asset_manager/tests -v
pwsh.exe -File tools/art/asset_manager/control/test-launcher.ps1
pwsh.exe -File run-motion-preview.ps1 -EnsureImport -Check
py -3 tools/art/promotion/promote_animation.py chalk_spirit --check
```

完整导出命令和运行包契约见 [战斗动画](../../docs/battle-animation.md#hybrid-animation-package)，验证结果见 [ART-03](../../docs/implementation/art-03.md)。

### 姿态对比

用 Godot `--headless --path . res://tools/art/verification/compare_presentation.tscn -- res://路径/compare.json` 运行。Windows GUI 引擎需由 PowerShell 7 的 `Start-Process -WindowStyle Hidden -Wait -PassThru` 等待完成，并检查退出码和 `PRESENTATION_COMPARISON PASS`。

JSON 必填：`source`、`target`（两个场景路径）、`canvas`、非空 `actions`。两个场景须实现 `apply_presentation(context)`，对比节点使用相同相对路径，缺失节点会失败。

```json
{
  "source": "res://路径/before.tscn",
  "target": "res://路径/after.tscn",
  "canvas": [288, 288],
  "fps": 144,
  "actions": {
    "ranged": {"source_action": "attack", "length": 2},
    "idle": {"length": 1.5, "times": [30, 60, 120]}
  }
}
```

`length` 是传给两版的动作持续时间；默认采样完整动作，`sample_end` 可单独指定采样终点，`times` 补充循环接缝和长时采样点。`source_action` 只处理旧动作名映射。可选 `facing_right`、`global_pose`、`ignore_nodes` 及 `tolerance`（position、rotation、scale、modulate）。忽略项必须有结构调整依据；目标额外节点不比较，新增视觉需单独查看。跳变动作可显式设置 `boundary_seconds`，报告接受的单侧时间容差次数；默认不启用。它验证姿态，不代替战斗事件测试或视觉评审。
