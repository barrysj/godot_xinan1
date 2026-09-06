param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [switch]$Smoke
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run this script using pwsh.exe.' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw "Godot not found: $EnginePath" }
$campusArguments = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility',
    '--log-file', (Join-Path $PSScriptRoot '.godot/campus-demo.log'))
if ($Smoke) { $campusArguments += '--headless' }
$campusArguments += 'res://scenes/expedition/expedition.tscn'
if ($Smoke) { $campusArguments += @('--', '--run-smoke') }
& $EnginePath @campusArguments
