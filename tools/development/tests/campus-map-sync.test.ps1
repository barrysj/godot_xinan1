#requires -Version 7.0
param([Parameter(Mandatory)][string]$EnginePath,[switch]$Capture)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
. (Join-Path $root 'tools/development/project-health.ps1')
$health = Initialize-GodotProject -ProjectPath $root -EnginePath $EnginePath
Write-Output "PROJECT_HEALTH_CHECK checks=$($health.Checks) failures=0"
$fixtures = @(
    @{ Name='map-route-sync'; Scene='scenes/expedition/campus_map_sync_check.tscn'; Args=@(); Marker='MAP_ROUTE_SYNC_CHECK \d+ checks / 0 failures' },
    @{ Name='map-sync-flow'; Scene='scenes/content/campus_flow_preview.tscn'; Args=@('--flow-preview-check'); Marker='CAMPUS_FLOW checks=\d+ failures=0' },
    @{ Name='map-sync-campaign'; Scene='scenes/expedition/expedition.tscn'; Args=@('--campaign-flow-check','--order=012'); Marker='CAMPAIGN_FLOW checks=\d+ failures=0' }
)
if ($Capture) { $fixtures += @{ Name='map-sync-navigation'; Scene='scenes/expedition/campus_navigation_check.tscn'; Args=@('--capture'); Marker='CAMPUS_NAVIGATION_CHECK checks=\d+ failures=0'; Gui=$true } }
foreach ($fixture in $fixtures) {
    $log = Join-Path $root ".godot/$($fixture.Name).log"
    $arguments = @('--path',$root,'--rendering-method','gl_compatibility','--quit-after','3600')
    if (-not $fixture.Gui) { $arguments += '--headless' }
    $arguments += @("res://$($fixture.Scene)")
    if ($fixture.Args.Count) { $arguments += @('--')+$fixture.Args }
    $result = Invoke-GodotHealthStage -EnginePath $EnginePath -ProjectPath $root -Arguments $arguments -LogPath $log -TimeoutSeconds 180
    Assert-GodotRunLog -LogPath $log -ExitCode $result.ExitCode
    $marker = [regex]::Match($result.Text,$fixture.Marker)
    if (-not $marker.Success) { throw "Map synchronization verification did not finish: $log" }
    Write-Output "$($fixture.Name) $($marker.Value)"
}
