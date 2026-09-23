# Run from PowerShell 7. Override -EnginePath if Godot is moved.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [switch]$Smoke,
    [switch]$CodeCheck,
    [switch]$CodeCapture
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Please run this script with pwsh.exe (PowerShell 7).'
}
if (-not (Test-Path -LiteralPath $EnginePath)) {
    throw "Godot was not found at $EnginePath. Supply -EnginePath with your executable path."
}
if ($CodeCheck -or $CodeCapture) {
	if ($CodeCheck -and $CodeCapture) { throw 'Choose either -CodeCheck or -CodeCapture.' }
	$scene = 'res://scenes/battle_demo/code_integration_check.tscn'
    $arguments = @('--path', $PSScriptRoot, '--log-file', (Join-Path $PSScriptRoot '.godot/main-code-integration.log'))
    if ($CodeCheck) { $arguments += @('--headless', '--quit-after', '3000') }
    $arguments += $scene
    if ($CodeCapture) { $arguments += @('--', '--capture', '--size=1920x1080') }
    & $EnginePath @arguments
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $output = Get-Content -LiteralPath (Join-Path $PSScriptRoot '.godot/main-code-integration.log') -Raw
    if ($output -match 'SCRIPT ERROR' -or $output -notmatch '(?m)MAIN_CODE_CHECK checks=\d+ failures=0') { throw 'Original battle integration verification did not pass.' }
    exit 0
}
$demoArguments = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility',
    '--log-file', (Join-Path $PSScriptRoot '.godot/battle-demo.log'))
if ($Smoke) { $demoArguments += '--headless' }
$demoArguments += 'res://scenes/battle_demo/battle_demo.tscn'
if ($Smoke) { $demoArguments += @('--', '--demo-smoke') }
& $EnginePath @demoArguments
