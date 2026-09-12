# Developer preview. Does not read or write player saves.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [string]$Animation = '',
    [switch]$Check,
    [switch]$Capture,
    [switch]$Tour
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
$previewArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/motion-preview.log'))
if ($Check) { $previewArgs += '--headless' }
$previewArgs += @('res://scenes/battle_demo/motion_preview.tscn', '--')
if ($Check) { $previewArgs += '--motion-preview-check' }
elseif ($Capture) { $previewArgs += '--motion-preview-capture' }
elseif ($Tour) { $previewArgs += '--motion-preview-tour' }
if ($Animation) { $previewArgs += "--preview-animation=$Animation" }
& $EnginePath @previewArgs
exit $LASTEXITCODE
