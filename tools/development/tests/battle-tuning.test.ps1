#requires -Version 7.0
param([Parameter(Mandatory)][string]$EnginePath,[switch]$Capture)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
. (Join-Path $root 'tools/development/project-health.ps1')
$health = Initialize-GodotProject -ProjectPath $root -EnginePath $EnginePath
Write-Output "PROJECT_HEALTH_CHECK checks=$($health.Checks) failures=0"
foreach ($mode in @('debug','disabled')) {
    $log = Join-Path $root ".godot/battle-tuning-$mode.log"
    $arguments = @('--path',$root,'--rendering-method','gl_compatibility','--quit-after','3600')
    if (-not $Capture -or $mode -eq 'disabled') { $arguments += '--headless' }
    $arguments += @('res://scenes/expedition/expedition.tscn','--','--battle-tuning-check')
    if ($mode -eq 'debug') {
        $arguments += @('--campus-debug','--debug-battle')
        if ($Capture) { $arguments += '--battle-tuning-capture' }
    }
    $result = Invoke-GodotHealthStage -EnginePath $EnginePath -ProjectPath $root -Arguments $arguments -LogPath $log -TimeoutSeconds 180
    Assert-GodotRunLog -LogPath $log -ExitCode $result.ExitCode
    $marker = [regex]::Match($result.Text,'(?m)BATTLE_TUNING_CHECK \d+ checks / 0 failures')
    if (-not $marker.Success) { throw "Battle tuning verification did not finish: $log" }
    Write-Output "$mode $($marker.Value)"
}
