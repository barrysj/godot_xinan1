# 图书馆敌人混合动画生产

本轮只处理键帽拳灵、投影独眼灵、归还印章怪、馆藏巨典与图书管理员，方案和批准状态见 [任务](../../../../docs/art/tasks/m1-enemy-animation.md)。源图来自内置 imagegen；本工具只裁取、归一化和按原像素拆分部件，生成既有 Godot 混合动画资源。

当前交付为五对象已批准的 `asset_001`（原 `tmp_002`）；旧 `tmp_001` 已按负责人只留最新的决定删除。源包留在 design/concepts/enemy，92 文件正式子集位于 assets/art/characters/<对象ID>/。下一临时候选从 `tmp_003` 开始；修改已批准资产时另开候选，不覆盖留存版。

运行需 PowerShell 7、Python 3.10+、Pillow、NumPy；动作输入验证读取用户安装的 character-action-design 原版 validate(data)。本机 Python 路径由 Codex 的 workspace dependencies 提供，旧 `py -3` 无 Pillow 时显式选择该运行时，不安装新依赖。

```powershell
$pythonPath = 'C:/Users/SongJun/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$env:PYTHONIOENCODING = 'utf-8'
# 新修订先准备 tmp_003/source 输入；以下两步只用于未批准临时候选。
& $pythonPath tools/art/animation/enemy_cast/build_library_enemies.py --version tmp_003
& $pythonPath tools/art/animation/enemy_cast/register_preview.py --version tmp_003
# 当前留存版的静态评审图可显式重建。
& $pythonPath tools/art/animation/enemy_cast/review_sheets.py --version asset_001
```

`build_library_enemies.py` 默认全部，也接受 `--enemy <slug>`；输入 `source/poses.png` 与有弹体对象的 `source/projectile.png`。各包 build-config.json 记录裁切、对齐轴、部件遮罩与 pivots。输出核心为 presentation.tscn、animations.tres、battle_animation.tres、rig_manifest.json、统一 640×640 帧及部件、动作卡与生产记录。统一缩放不逐姿势挤压，部件还原待机原像素完全一致；所有 runtime_files 必须存在。

2026-10-07 修改候选原为 `tmp_002`，当前留存名称为 `asset_001`。`source/revision.json` 开启每敌人施法光环；没有此标记时保持首版行为。光效为原生 Line2D 亮边、短光线和连续显隐／缩放轨道，施法释放点最亮，其他状态复位。管理员额外使用 imagegen 两姿势 `source/action-poses-clean.png` 覆盖 impact／cast，并播放三本书的发射提示；原图和修订提示词保存在 generation.md。所有包继续使用共享混合控制器。

印章修订稿优先读取 `source/poses-four-wheels.png` 的七个非死亡姿势；失稳从 `source/poses-death-wheel-attempt.png` 裁取，末帧读取 `source/death-four-wheels.png`。完整整表试稿中的未通过姿势不进入运行帧；处理记录按实际源文件追溯。归一化不重绘源像素，补画和轮数修正均通过 imagegen。

`register_preview.py` 仅临时登记未批准候选，不能用作批准或正式提升。GIF 导出会更新清单，登记操作和导出不能并发。无需渲染的只读浏览不会生产资产。

```powershell
$candidate = 'res://design/concepts/enemy/return-stamp/asset_001'
pwsh.exe -NoProfile -File ./run-motion-preview.ps1 -Unit "$candidate/preview_unit.tres" -Animation "$candidate/battle_animation.tres" -Check
pwsh.exe -NoProfile -File ./run-motion-preview.ps1 -Unit "$candidate/preview_unit.tres" -Animation "$candidate/battle_animation.tres" -ExportPreviews -PythonPath $pythonPath
pwsh.exe -NoProfile -File ./run-motion-preview.ps1 -Unit "$candidate/preview_unit.tres" -Animation "$candidate/battle_animation.tres" -Action Melee -Capture
```

远程对象截图用 `-Action Ranged`；施法用 `-Action Cast`。截图工具按单位前摇结束的首个模拟步取图；检查释放时刻，避免截图时短动作已结束。预览单位只是动作评审用，属性和 inventor 技能不属于正式敌人设计。

附加契约检查必须在正常 Godot 主场景运行，避免插件依赖 current_scene 的干扰。Windows GUI 引擎用 Start-Process 等待并检查退出码：

```powershell
$enginePath = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64.exe'
$checkProcess = Start-Process -FilePath $enginePath -ArgumentList @('--headless','--path','.', 'tools/art/animation/enemy_cast/library_contract_check.tscn','--log-file','.godot/enemy-contract.log','--','--candidate-version=asset_001') -WindowStyle Hidden -PassThru -Wait
if ($checkProcess.ExitCode -ne 0) { throw 'Enemy contract failed' }
Get-Content .godot/enemy-contract.log
```

检查七动作、实际求值运动、技能提示、释放帧、稀疏曲线预算、所有骨骼状态切换、左朝向、手动时钟和死亡末帧。留存改名后，生成／检查的 version 改为对应 asset_NNN；不得因此重写批准记录。正式提升继续使用已有 promotion/promote_animation.py，运行子集不包含源图、预览单位、GIF 或动作卡。

正式包验证将上述契约检查参数换为 `--production`，先正常导入 PNG；此模式不安装候选 PNG 加载器，使用稳定正式路径。每套提升可用 `python tools/art/promotion/promote_animation.py <对象ID> --variant asset_001 --check` 核对逐文件一致性。

```powershell
pwsh.exe -NoProfile -File ./run-motion-preview.ps1 -Unit res://tools/art/animation/enemy_cast/preview_units/cyber_librarian.tres -Animation res://assets/art/characters/cyber_librarian/battle_animation.tres -Check
pwsh.exe -NoProfile -File ./run-motion-preview.ps1 -Unit res://tools/art/animation/enemy_cast/preview_units/cyber_librarian.tres -Animation res://assets/art/characters/cyber_librarian/battle_animation.tres -Action Cast -Capture
```

preview_units 中的五定义只用于现有动作预览，引用正式动画；属性和 inventor 技能是测试时钟，不是主线敌人规则，不纳入正式资产包。资产已批准与实际主线接入分开登记；本批暂为 not_integrated。
