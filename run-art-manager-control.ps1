# Compatibility entry: the former art-only controller is now the tool suite.
param([switch]$PassThru)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
& (Join-Path $PSScriptRoot 'run-tool-suite-control.ps1') -PassThru:$PassThru
