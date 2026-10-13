param(
    [string]$ProjectPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')),
    [string]$EnginePath = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe',
    [switch]$Remove
)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))

if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use pwsh.exe.' }
$ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
$current = & git -C $ProjectPath config --get core.hooksPath
if ($LASTEXITCODE -gt 1) { throw 'Not a Git checkout.' }
if ($current -and $current -ne '.githooks') { throw "已有 hooksPath=$current，请手动整合现有 hooks；本工具不会覆盖。" }
if ($Remove) {
    if ($current -eq '.githooks') {
        & git -C $ProjectPath config --local --unset core.hooksPath
        if ($LASTEXITCODE -ne 0) { throw 'Could not remove project hook configuration.' }
        & git -C $ProjectPath config --local --unset codex.godotEngine
    }
    Write-Host '已关闭工程自动检查 hooks。'
    exit 0
}
$EnginePath = (Resolve-Path -LiteralPath $EnginePath).Path
foreach ($name in @('post-merge', 'post-checkout', 'post-commit')) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath ".githooks/$name") -PathType Leaf)) { throw "Missing project hook: $name" }
}
if (-not $current) {
    $defaultHooks = & git -C $ProjectPath rev-parse --git-path hooks
    if ($LASTEXITCODE -ne 0) { throw 'Not a Git checkout.' }
    if (-not [IO.Path]::IsPathRooted($defaultHooks)) { $defaultHooks = Join-Path $ProjectPath $defaultHooks }
    $custom = @(Get-ChildItem -LiteralPath $defaultHooks -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*.sample' })
    if ($custom.Count) { throw '默认 hooks 目录已有文件，请先手动整合，避免禁用现有检查。' }
}
& git -C $ProjectPath config --local codex.godotEngine $EnginePath
if ($LASTEXITCODE -ne 0) { throw 'Could not configure project engine.' }
& git -C $ProjectPath config --local core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) { throw 'Could not configure project hooks.' }
Write-Host '已启用：main 合并、提交及切换后的导入与启动检查。'
