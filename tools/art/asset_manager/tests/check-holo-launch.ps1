#requires -Version 7.0
# Integration regression: GUI Godot must finish import and complete card checks.
param([Parameter(Mandatory)][string]$Godot)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path "$PSScriptRoot/../../../..").Path
$process = Start-Process -FilePath (Get-Command pwsh.exe).Source -ArgumentList @('-NoProfile', '-File', "`"$project/run-holo-card.ps1`"", '-Mode', 'Check', '-Godot', "`"$Godot`"") -WindowStyle Hidden -PassThru
if (-not $process.WaitForExit(180000)) {
    $process.Kill($true)
    throw 'Card launch did not complete within 180 seconds.'
}
if ($process.ExitCode -ne 0) { throw "Card launch failed: exit $($process.ExitCode)" }
Write-Output 'HOLO_LAUNCH_CHECK PASS'
