# Run from PowerShell 7. Override -EnginePath if Godot is moved.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [switch]$Smoke
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Please run this script with pwsh.exe (PowerShell 7).'
}
if (-not (Test-Path -LiteralPath $EnginePath)) {
    throw "Godot was not found at $EnginePath. Supply -EnginePath with your executable path."
}
$demoArguments = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility',
    '--log-file', (Join-Path $PSScriptRoot '.godot/battle-demo.log'))
if ($Smoke) { $demoArguments += '--headless' }
$demoArguments += 'res://scenes/battle_demo/battle_demo.tscn'
if ($Smoke) { $demoArguments += @('--', '--demo-smoke') }
& $EnginePath @demoArguments
