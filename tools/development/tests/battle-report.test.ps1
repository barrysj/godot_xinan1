#requires -Version 7.0
param([Parameter(Mandatory)][string]$EnginePath,[switch]$Capture)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
. (Join-Path $root 'tools/development/project-health.ps1')
$health = Initialize-GodotProject -ProjectPath $root -EnginePath $EnginePath
Write-Output "PROJECT_HEALTH_CHECK checks=$($health.Checks) failures=0"
$fixtures = @(
    @{ Name='report-accounting'; Scene='game/combat/battle_report_check.tscn'; Args=@(); Marker='BATTLE_REPORT_ACCOUNTING_CHECK'; Headless=$true },
    @{ Name='report-main'; Scene='scenes/expedition/battle_report_check.tscn'; Args=@('--battle-report-check'); Marker='BATTLE_REPORT_UI_CHECK'; Headless=(-not $Capture) },
    @{ Name='report-preview'; Scene='scenes/expedition/battle_report_check.tscn'; Args=@('--battle-report-check','--campus-debug','--debug-battle'); Marker='BATTLE_REPORT_UI_CHECK'; Headless=(-not $Capture) }
)
foreach ($fixture in $fixtures) {
    $log = Join-Path $root ".godot/$($fixture.Name).log"
    $arguments = @('--path',$root,'--rendering-method','gl_compatibility','--quit-after','3600')
    if ($fixture.Headless) { $arguments += '--headless' }
    $arguments += @("res://$($fixture.Scene)")
    if ($fixture.Args.Count) {
        $arguments += @('--') + $fixture.Args
        if ($Capture) { $arguments += '--capture' }
    }
    $result = Invoke-GodotHealthStage -EnginePath $EnginePath -ProjectPath $root -Arguments $arguments -LogPath $log -TimeoutSeconds 180
    Assert-GodotRunLog -LogPath $log -ExitCode $result.ExitCode
    $marker = [regex]::Match($result.Text,"(?m)$($fixture.Marker) \d+ checks / 0 failures")
    if (-not $marker.Success) { throw "Report verification did not finish: $log" }
    Write-Output "$($fixture.Name) $($marker.Value)"
}
