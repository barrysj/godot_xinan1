if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use pwsh.exe.' }
$branch = & git branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') { exit 0 }
$root = & git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) { exit 1 }
$engine = & git config --local --get codex.godotEngine
if (-not $engine) { $engine = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe' }
Write-Host 'main 已更新，自动检查当前工作区的 Godot 导入与启动。'
& pwsh.exe -NoProfile -File (Join-Path $root 'tools/development/check-project.ps1') -EnginePath $engine
$code = $LASTEXITCODE
if ($code -ne 0) { Write-Error 'main 工程预检失败。Git 操作可能已经完成，请查看检查日志；不自动回滚。' -ErrorAction Continue }
exit $code
