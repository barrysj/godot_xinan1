# Compatibility entry: the former art-only controller is now the tool suite.
param([switch]$PassThru)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))

if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
& (Join-Path $projectRoot 'tools/art/asset_manager/control/run-tool-suite-control.ps1') -PassThru:$PassThru
