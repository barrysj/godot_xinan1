# Developer preview. Does not read or write player saves.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [string]$Unit = '',
    [string]$Animation = '',
    [string]$Projectile = '',
    [string]$Presentation = '',
    [ValidateSet('Idle', 'Move', 'Melee', 'Ranged', 'Cast', 'Hurt', 'Critical', 'Death')]
    [string]$Action = '',
    [ValidateRange(0.05, 4.0)]
    [double]$Speed = 1.0,
    [switch]$EnsureImport,
    [switch]$Check,
    [switch]$Capture,
    [switch]$Tour
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
if ($EnsureImport) {
    $importLog = Join-Path $PSScriptRoot '.godot/art-manager-import.log'
    $importArgs = @('--headless', '--editor', '--path', ('"{0}"' -f $PSScriptRoot), '--quit', '--log-file', ('"{0}"' -f $importLog))
    $importProcess = Start-Process -FilePath $EnginePath -ArgumentList $importArgs -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -PassThru
    if ($importProcess.ExitCode -ne 0) { throw "Godot resource import failed with exit code $($importProcess.ExitCode)." }
}
$previewArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/motion-preview.log'))
if ($Check) { $previewArgs += '--headless' }
$previewArgs += @('res://scenes/battle_demo/motion_preview.tscn', '--')
if ($Check) { $previewArgs += '--motion-preview-check' }
elseif ($Capture) { $previewArgs += '--motion-preview-capture' }
elseif ($Tour) { $previewArgs += '--motion-preview-tour' }
if ($Animation) { $previewArgs += "--preview-animation=$Animation" }
if ($Unit) { $previewArgs += "--preview-unit=$Unit" }
if ($Projectile) { $previewArgs += "--preview-projectile=$Projectile" }
if ($Presentation) { $previewArgs += "--preview-presentation=$Presentation" }
if ($Action) { $previewArgs += "--preview-action=$($Action.ToLowerInvariant())" }
$previewArgs += "--preview-speed=$($Speed.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
& $EnginePath @previewArgs
exit $LASTEXITCODE
