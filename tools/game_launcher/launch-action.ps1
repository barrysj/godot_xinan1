# Internal backend for the native launchers. Never opens an interactive shell menu.
#requires -Version 7.0
param(
    [ValidateSet('Debug', 'Release')][string]$Mode,
    [ValidateSet('Play', 'Campus', 'Battle', 'Health', 'Repair', 'SelfCheck', 'ContentPreview', 'ContentCheck', 'HooksOn', 'HooksOff')][string]$Action,
    [Parameter(Mandatory)][string]$EnginePath,
    [ValidateSet('1920x1080', '2560x1440', '1920x1200')][string]$Resolution = '1920x1080',
    [switch]$Fullscreen,
    [switch]$Verify,
    [switch]$Capture
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $projectRoot 'tools/development/project-health.ps1')
function Send-LauncherEvent([string]$Kind, [string]$Message, [string]$Path = '') {
    Write-Output ('LAUNCHER_EVENT ' + (@{kind=$Kind; message=$Message; path=$Path} | ConvertTo-Json -Compress))
}
$lock = $null
try {
    if (-not $Mode -or -not $Action) { throw '请选择启动模式与操作。' }
    if ($Mode -eq 'Release' -and $Action -ne 'Play') { throw 'Release 仅提供正常游戏入口。' }
    if ($Verify -and $Action -notin @('Play', 'Campus', 'Battle')) { throw '验证参数只用于游戏入口。' }
    if ($Capture -and (-not $Verify -or $Action -ne 'Battle')) { throw '图形验证仅用于隔离的战斗启动检查。' }
    $EnginePath = (Resolve-Path -LiteralPath $EnginePath).Path
    $cache = Join-Path $projectRoot '.godot/game-launcher'
    [IO.Directory]::CreateDirectory($cache) | Out-Null
    try { $lock = [IO.File]::Open((Join-Path $cache 'active.lock'), 'OpenOrCreate', 'ReadWrite', 'None') }
    catch { throw '此工作区已有启动或检查正在运行，请等待它结束。' }
    if ($Action -in @('HooksOn', 'HooksOff')) {
        $hookArgs = @('-NoProfile', '-File', (Join-Path $projectRoot 'tools/development/install-project-hooks.ps1'), '-ProjectPath', $projectRoot, '-EnginePath', $EnginePath)
        if ($Action -eq 'HooksOff') { $hookArgs += '-Remove' }
        & pwsh.exe @hookArgs
        if ($LASTEXITCODE -ne 0) { throw '自动检查设置失败；已有 hooks 会保留，请查看日志。' }
        Send-LauncherEvent 'complete' $(if ($Action -eq 'HooksOn') { '已启用 main 更新后的自动检查。' } else { '已关闭 main 自动检查。' })
        exit 0
    }
    Send-LauncherEvent 'preparing' $(if ($Action -eq 'Repair') { '正在重新导入并验证工程…' } else { '正在检查资源与脚本…' })
    $health = Initialize-GodotProject -ProjectPath $projectRoot -EnginePath $EnginePath -Repair:($Action -eq 'Repair')
    foreach ($healthLog in $health.Logs) { Send-LauncherEvent 'log' '工程预检日志' $healthLog }
    if ($Action -in @('Health', 'Repair')) {
        Send-LauncherEvent 'complete' "工程检查通过：$($health.Checks) 项；已导入=$($health.Imported)。" $health.Logs[-1]
        exit 0
    }
    $logPath = Join-Path $cache ("$($Action.ToLowerInvariant())-$([Guid]::NewGuid().ToString('N')).log")
    Send-LauncherEvent 'log' '运行日志' $logPath
    $arguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility')
    $marker = ''
    if ($Action -eq 'ContentCheck') {
        $arguments += @('--headless', '--script', 'res://game/content/validate_content.gd')
        $marker = 'CONTENT_VALIDATION errors=0 '
    } elseif ($Action -eq 'ContentPreview') {
        $arguments += 'res://scenes/content/content_preview.tscn'
    } else {
        $checking = $Verify -or $Action -eq 'SelfCheck'
        $arguments += @('--resolution', $Resolution)
        if ($checking) {
            if (-not $Capture) { $arguments += '--headless' }
            $arguments += @('--quit-after', '3600')
        }
        elseif ($Fullscreen) { $arguments += '--fullscreen' }
        $arguments += @('res://scenes/expedition/expedition.tscn', '--', '--demo-animations=formal', "--demo-size=$Resolution")
        if ($Action -ne 'Play') { $arguments += '--campus-debug' }
        if ($Action -eq 'Battle') {
            $arguments += '--debug-battle'
            if ($checking) { $arguments += '--debug-battle-check'; $marker = '(?m)DEBUG_BATTLE_CHECK \d+ checks / 0 failures' }
            if ($Capture) { $arguments += '--debug-battle-capture' }
        } elseif ($checking) {
            $arguments += '--debug-check'
            $marker = '(?m)DEBUG_CHECK \d+ checks / 0 failures'
        }
    }
    Send-LauncherEvent $(if ($marker) { 'checking' } else { 'starting' }) $(if ($marker) { '正在运行功能自检…' } else { '正在打开游戏窗口…' })
    if ($marker) {
        $result = Invoke-GodotHealthStage -EnginePath $EnginePath -ProjectPath $projectRoot -Arguments $arguments -LogPath $logPath -TimeoutSeconds 180
        Assert-GodotRunLog -LogPath $logPath -ExitCode $result.ExitCode
        if ($result.Text -notmatch $marker) { throw "自检没有成功完成，请查看 $logPath" }
        Write-Output $result.Text
        Send-LauncherEvent 'complete' '功能检查通过。' $logPath
    } else {
        $info = [Diagnostics.ProcessStartInfo]::new()
        $info.FileName = $EnginePath
        $info.WorkingDirectory = $projectRoot
        $info.UseShellExecute = $false
        $info.CreateNoWindow = $true
        $separator = [Array]::IndexOf($arguments, '--')
        for ($index = 0; $index -lt $arguments.Count; $index++) {
            if ($index -eq $separator) { $info.ArgumentList.Add('--log-file'); $info.ArgumentList.Add($logPath) }
            $info.ArgumentList.Add($arguments[$index])
        }
        if ($separator -lt 0) { $info.ArgumentList.Add('--log-file'); $info.ArgumentList.Add($logPath) }
        $process = [Diagnostics.Process]::Start($info)
        Send-LauncherEvent 'running' '游戏窗口已启动；退出游戏后可再次启动。' $logPath
        try { $process.WaitForExit(); Assert-GodotRunLog -LogPath $logPath -ExitCode $process.ExitCode }
        finally { $process.Dispose() }
        Send-LauncherEvent 'complete' '游戏已结束。' $logPath
    }
    exit 0
} catch {
    Send-LauncherEvent 'error' $_.Exception.Message
    exit 1
} finally { if ($lock) { $lock.Dispose() } }
