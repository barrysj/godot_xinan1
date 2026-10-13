# Native GUI + actual Godot integration. QA switches never use player save paths.
#requires -Version 7.0
param([Parameter(Mandatory)][string]$EnginePath)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$evidence = Join-Path $root '.godot/art-workflow/game-launcher'
[IO.Directory]::CreateDirectory($evidence) | Out-Null
$checks = 0
function Expect([bool]$Condition, [string]$Message) { $script:checks++; if (-not $Condition) { throw "GAME_LAUNCHER_CHECK: $Message" } }
function Invoke-Native([string]$Mode, [string[]]$Arguments, [int]$ExpectedCode = 0) {
    $exe = Join-Path $root "Campus${Mode}Launcher.exe"
    $quoted = $Arguments | ForEach-Object { '"{0}"' -f $_ }
    $process = Start-Process -FilePath $exe -ArgumentList $quoted -WorkingDirectory $root -PassThru
    try {
        if (-not $process.WaitForExit(480000)) { $process.Kill(); throw 'Native launcher timed out.' }
        Expect ($process.ExitCode -eq $ExpectedCode) "$Mode GUI exit $($process.ExitCode), expected $ExpectedCode; arguments=$Arguments"
    } finally { $process.Dispose() }
}
function PlayerProfiles {
    $directory = Join-Path $env:APPDATA 'Godot/app_userdata/godot-game-template'
    $result = @{}
    foreach ($name in @('campus_progress.json', 'campus_debug_progress.json')) {
        $path = Join-Path $directory $name
        $result[$name] = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { 'missing' }
    }
    return $result
}
$before = PlayerProfiles
$build = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'build-info.json') -Raw | ConvertFrom-Json
foreach ($mode in @('Debug','Release')) {
    $exe = Join-Path $root "Campus${mode}Launcher.exe"
    Expect ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -eq $build.outputs.$mode) "$mode binary matches its build record"
    $bytes = [IO.File]::ReadAllBytes($exe)
    $pe = [BitConverter]::ToInt32($bytes, 0x3c)
    Expect ([BitConverter]::ToUInt16($bytes, $pe + 4 + 20 + 68) -eq 2) "$mode is a Windows GUI executable, not a console"
    Invoke-Native $mode @('--self-test', "$evidence/$mode.json", '--capture', "$evidence/$mode.png")
    $report = Get-Content -LiteralPath "$evidence/$mode.json" -Raw | ConvertFrom-Json
    Expect ($report.failures -eq 0 -and $report.checks -gt 0) "$mode native window/focus/resize checks pass"
    Write-Output "NATIVE_WINDOW_CHECK $mode checks=$($report.checks) failures=$($report.failures)"
}
Invoke-Native 'Debug' @('--checks-page', '--capture', "$evidence/Debug-checks.png")
foreach ($entry in @(@('Debug','Battle'), @('Debug','Campus'), @('Release','Play'), @('Debug','Health'), @('Debug','Repair'))) {
    $mode, $action = $entry
    Invoke-Native $mode @('--engine', $EnginePath, '--verify-launch', $action, '--capture', "$evidence/$mode-$action.png")
    $file = Join-Path $root ".godot/game-launcher/gui-$($mode.ToLowerInvariant())-$($action.ToLowerInvariant()).json"
    $report = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
    Expect ($report.exit_code -eq 0) "$mode $action actual button/backend/engine path passes"
    Write-Output "NATIVE_ACTION_CHECK $mode $action PASS"
}
Invoke-Native 'Debug' @('--engine', $EnginePath, '--verify-launch', 'Battle', '--game-capture', '--capture', "$evidence/Debug-Battle-graphical.png")
Expect (Test-Path -LiteralPath (Join-Path $root '.godot/debug-battle-launch-1920x1080.png')) 'native battle button reaches the actual rendered battle and its graphical checks'
Write-Output 'NATIVE_ACTION_CHECK Debug Battle GRAPHICAL PASS'
Invoke-Native 'Release' @('--engine', "$evidence/missing-godot.exe", '--verify-launch', 'Play', '--capture', "$evidence/Release-error.png") 1
$report = Get-Content -LiteralPath (Join-Path $root '.godot/game-launcher/gui-release-play.json') -Raw | ConvertFrom-Json
Expect ($report.message -match '找不到 Godot') 'missing engine is reported in the native window'
# Backend rejects a Debug route even when someone invokes its CLI under Release.
$output = & pwsh.exe -NoProfile -File (Join-Path $PSScriptRoot 'launch-action.ps1') -Mode Release -Action Battle -EnginePath $EnginePath
Expect ($LASTEXITCODE -eq 1 -and ($output -join "`n") -match 'Release 仅提供正常游戏入口') 'Release backend also rejects Debug actions'
# A second launcher cannot race the first launcher or game in the same checkout.
$held = [IO.File]::Open((Join-Path $root '.godot/game-launcher/active.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
try {
    Invoke-Native 'Debug' @('--engine', $EnginePath, '--verify-launch', 'Health', '--capture', "$evidence/Debug-occupied.png") 1
    $report = Get-Content -LiteralPath (Join-Path $root '.godot/game-launcher/gui-debug-health.json') -Raw | ConvertFrom-Json
    Expect ($report.message -match '已有启动或检查') 'concurrent native entry reports a readable failure'
} finally { $held.Dispose() }
$after = PlayerProfiles
foreach ($name in $before.Keys) { Expect ($before[$name] -eq $after[$name]) "GUI verification does not change $name" }
Write-Output "GAME_LAUNCHER_CHECK checks=$checks failures=0"
