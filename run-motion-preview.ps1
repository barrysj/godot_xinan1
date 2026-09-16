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
    [switch]$ExportPreviews,
    [string]$PythonPath = '',
    [switch]$Tour
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
if ($ExportPreviews -and ($Check -or $Capture -or $Tour)) { throw '-ExportPreviews cannot be combined with -Check, -Capture or -Tour.' }
$pythonArgs = @()
if ($ExportPreviews) {
    if (-not $PythonPath) { $PythonPath = (Get-Command py.exe -ErrorAction Stop).Source; $pythonArgs = @('-3') }
    & $PythonPath @pythonArgs -c 'import PIL'
    if ($LASTEXITCODE -ne 0) { throw 'Preview export needs Python with Pillow. Set -PythonPath.' }
    $producer = Join-Path $PSScriptRoot 'tools/art/animation/motion_previews.py'
    $captureManifest = & $PythonPath @pythonArgs $producer prepare --unit $Unit --animation $Animation --action $Action
    if ($LASTEXITCODE -ne 0) { throw 'Unable to resolve export candidate.' }
    $job = Get-Content -LiteralPath $captureManifest -Raw | ConvertFrom-Json
    $Unit = $job.unit
    $Animation = $job.animation
    $Projectile = $job.projectile
    $EnsureImport = $true
}
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
if ($ExportPreviews) { $previewArgs += "--capture-manifest=$captureManifest" }
$previewArgs += "--preview-speed=$($Speed.ToString([System.Globalization.CultureInfo]::InvariantCulture))"
# The Windows GUI executable otherwise returns before capture/check completion.
$quotedArgs = $previewArgs | ForEach-Object { '"{0}"' -f $_ }
$process = Start-Process -FilePath $EnginePath -ArgumentList $quotedArgs -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -PassThru
if ($process.ExitCode -ne 0) { exit $process.ExitCode }
if ($ExportPreviews) {
    & $PythonPath @pythonArgs $producer encode --manifest $captureManifest
    exit $LASTEXITCODE
}
exit 0
