# Throwaway comparison prototype. Does not modify saves or production resources.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [string]$PythonPath = (Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'),
    [switch]$Check,
    [switch]$Capture
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
$prototypeArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/chalk-rig-prototype.log'))
if ($Check) { $prototypeArgs += '--headless' }
$prototypeArgs += @('res://scenes/battle_demo/chalk_rig_prototype.tscn', '--')
if ($Check) { $prototypeArgs += '--chalk-rig-check' }
elseif ($Capture) { $prototypeArgs += '--chalk-rig-capture' }
$engineProcess = Start-Process -FilePath $EnginePath -ArgumentList $prototypeArgs -Wait -PassThru -NoNewWindow
$engineExitCode = $engineProcess.ExitCode
if ($engineExitCode -ne 0) { exit $engineExitCode }
if ($prototypeArgs -contains '--chalk-rig-capture') {
    if (-not (Test-Path -LiteralPath $PythonPath)) { throw 'Python with Pillow not found. Set -PythonPath.' }
    & $PythonPath (Join-Path $PSScriptRoot 'design/concepts/chalk-spirit/chalk-rig/002/build_review.py')
    exit $LASTEXITCODE
}
exit 0
