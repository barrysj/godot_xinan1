# Reproducible hybrid-animation review runner. Does not modify saves or production resources.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [string]$PythonPath = (Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'),
    [switch]$Check,
    [switch]$Capture
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
$previewArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/chalk-spirit-hybrid-preview.log'))
if ($Check) { $previewArgs += '--headless' }
$previewArgs += @('res://scenes/battle_demo/chalk_spirit_hybrid_preview.tscn', '--')
if ($Check) { $previewArgs += '--chalk-spirit-hybrid-check' }
elseif ($Capture) { $previewArgs += '--chalk-spirit-hybrid-capture' }
$engineProcess = Start-Process -FilePath $EnginePath -ArgumentList $previewArgs -Wait -PassThru -NoNewWindow
$engineExitCode = $engineProcess.ExitCode
if ($engineExitCode -ne 0) { exit $engineExitCode }
if ($previewArgs -contains '--chalk-spirit-hybrid-capture') {
    if (-not (Test-Path -LiteralPath $PythonPath)) { throw 'Python with Pillow not found. Set -PythonPath.' }
    & $PythonPath (Join-Path $PSScriptRoot 'design/concepts/chalk-spirit/chalk-spirit/006/build_review.py')
    exit $LASTEXITCODE
}
exit 0
