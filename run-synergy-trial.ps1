param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe',
    [switch]$Check,
    [switch]$Capture
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use pwsh.exe (PowerShell 7).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw "Godot not found: $EnginePath" }
$trialArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/trial.log'))
if ($Check) { $trialArgs += '--headless' }
$trialArgs += 'res://scenes/trial/trial.tscn'
if ($Check) { $trialArgs += @('--', '--trial-check') }
elseif ($Capture) { $trialArgs += @('--', '--trial-capture') }
& $EnginePath @trialArgs
exit $LASTEXITCODE
