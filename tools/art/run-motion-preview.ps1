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
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))

if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
if ($ExportPreviews -and ($Check -or $Capture -or $Tour)) { throw '-ExportPreviews cannot be combined with -Check, -Capture or -Tour.' }
$pythonArgs = @()
if ($ExportPreviews) {
    if (-not $PythonPath) { $PythonPath = (Get-Command py.exe -ErrorAction Stop).Source; $pythonArgs = @('-3') }
    & $PythonPath @pythonArgs -c 'import PIL'
    if ($LASTEXITCODE -ne 0) { throw 'Preview export needs Python with Pillow. Set -PythonPath.' }
    $producer = Join-Path $projectRoot 'tools/art/animation/motion_previews.py'
    $captureManifest = & $PythonPath @pythonArgs $producer prepare --unit $Unit --animation $Animation --action $Action
    if ($LASTEXITCODE -ne 0) { throw 'Unable to resolve export candidate.' }
    $job = Get-Content -LiteralPath $captureManifest -Raw | ConvertFrom-Json
    $Unit = $job.unit
    $Animation = $job.animation
    $Projectile = $job.projectile
    $EnsureImport = $true
}
if ($Animation) {
    $relativeAnimation = if ($Animation.StartsWith('res://')) { $Animation.Substring(6) } else { $Animation }
    if ([System.IO.Path]::IsPathRooted($relativeAnimation)) { throw "Animation must be a res:// or project-relative path: $Animation" }
    $projectRoot = [System.IO.Path]::GetFullPath($projectRoot)
    $animationFile = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $relativeAnimation))
    if (-not $animationFile.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Animation path escapes the preview project: $Animation"
    }
    if (-not (Test-Path -LiteralPath $animationFile -PathType Leaf)) {
        throw "Animation resource is missing from this checkout: $animationFile. Run the preview script from the worktree containing this candidate."
    }
}
function Test-AnimationImportNeeded([string]$AnimationResource) {
    if (-not $AnimationResource) { return $false }
    $relative = if ($AnimationResource.StartsWith('res://')) { $AnimationResource.Substring(6) } else { $AnimationResource }
    if ([System.IO.Path]::IsPathRooted($relative)) { return $true }
    $resource = Join-Path $projectRoot $relative
    if (-not (Test-Path -LiteralPath $resource -PathType Leaf)) { return $true }
    $references = [regex]::Matches([System.IO.File]::ReadAllText($resource), 'path="res://([^"\r\n]+\.(?:png|webp|jpe?g|svg))"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($references.Count -eq 0) { return $false }
    foreach ($reference in $references) {
        $source = Join-Path $projectRoot $reference.Groups[1].Value
        $descriptor = $source + '.import'
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or -not (Test-Path -LiteralPath $descriptor -PathType Leaf)) { return $true }
        $remap = [regex]::Match([System.IO.File]::ReadAllText($descriptor), '(?m)^path="res://([^"\r\n]+)"')
        if (-not $remap.Success) { return $true }
        $cache = Join-Path $projectRoot $remap.Groups[1].Value
        if (-not (Test-Path -LiteralPath $cache -PathType Leaf)) { return $true }
        if ((Get-Item -LiteralPath $source).LastWriteTimeUtc -gt (Get-Item -LiteralPath $cache).LastWriteTimeUtc) { return $true }
    }
    return $false
}
function Test-ProjectImportNeeded {
    $assetsRoot = Join-Path $projectRoot 'assets'
    $testingRoot = (Join-Path $assetsRoot 'testing') + [System.IO.Path]::DirectorySeparatorChar
    foreach ($source in Get-ChildItem -LiteralPath $assetsRoot -Recurse -File) {
        if ($source.Extension.ToLowerInvariant() -notin @('.png', '.webp', '.jpg', '.jpeg', '.svg', '.ttf', '.otf')) { continue }
        if ($source.FullName.StartsWith($testingRoot, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        $descriptor = $source.FullName + '.import'
        if (-not (Test-Path -LiteralPath $descriptor -PathType Leaf)) { return $true }
        $remap = [regex]::Match([System.IO.File]::ReadAllText($descriptor), '(?m)^path="res://([^"\r\n]+)"')
        if (-not $remap.Success) { return $true }
        $cache = Join-Path $projectRoot $remap.Groups[1].Value
        if (-not (Test-Path -LiteralPath $cache -PathType Leaf)) { return $true }
        if ($source.LastWriteTimeUtc -gt (Get-Item -LiteralPath $cache).LastWriteTimeUtc) { return $true }
    }
    return $false
}
$rawConceptAnimation = $Animation -and $relativeAnimation.Replace('\', '/').StartsWith('design/concepts/', [System.StringComparison]::OrdinalIgnoreCase)
# The preview scene decodes concept PNGs directly because design/.gdignore excludes them from Godot import.
if ($EnsureImport -and ((Test-ProjectImportNeeded) -or (-not $rawConceptAnimation -and (Test-AnimationImportNeeded $Animation)))) {
    $importLog = Join-Path $projectRoot '.godot/art-manager-import.log'
    $importArgs = @('--headless', '--editor', '--path', ('"{0}"' -f $projectRoot), '--quit', '--log-file', ('"{0}"' -f $importLog))
    $importProcess = Start-Process -FilePath $EnginePath -ArgumentList $importArgs -WorkingDirectory $projectRoot -WindowStyle Hidden -Wait -PassThru
    if ($importProcess.ExitCode -ne 0) { throw "Godot resource import failed with exit code $($importProcess.ExitCode)." }
}
$previewArgs = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $projectRoot '.godot/motion-preview.log'))
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
$windowStyle = if ($Check -or $Capture -or $ExportPreviews) { 'Hidden' } else { 'Normal' }
$previewStartedAt = [DateTime]::UtcNow
$process = Start-Process -FilePath $EnginePath -ArgumentList $quotedArgs -WorkingDirectory $projectRoot -WindowStyle $windowStyle -Wait -PassThru
if ($process.ExitCode -ne 0) { exit $process.ExitCode }
if ($Check -or $Capture) {
    $previewLog = Join-Path $projectRoot '.godot/motion-preview.log'
    if (-not (Test-Path -LiteralPath $previewLog) -or (Get-Item -LiteralPath $previewLog).LastWriteTimeUtc -lt $previewStartedAt) {
        throw 'Preview did not produce a fresh log; its exit code alone is not verification.'
    }
    $previewOutput = Get-Content -LiteralPath $previewLog -Raw
    if ($previewOutput -match 'SCRIPT ERROR') { throw 'Preview reported a script error.' }
    if ($Check -and $previewOutput -notmatch 'MOTION_PREVIEW_CHECK failures=0') { throw 'Preview check did not complete successfully.' }
    if ($Capture -and (($previewOutput -notmatch 'MOTION_CAPTURE_POSE') -or ([regex]::Matches($previewOutput, '(?m)^MOTION_PREVIEW_CAPTURE ').Count -ne 3))) {
        throw 'Preview capture did not complete all three resolutions with active poses.'
    }
}
if ($ExportPreviews) {
    & $PythonPath @pythonArgs $producer encode --manifest $captureManifest
    exit $LASTEXITCODE
}
exit 0
