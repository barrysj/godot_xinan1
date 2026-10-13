# Internal verification/compatibility entry. Daily entry is the native launcher.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [ValidateSet('Debug', 'Release')][string]$Mode = '',
    [ValidateSet('Easy', 'Normal', 'Hard', 'Manual')][string]$Difficulty = '',
    [ValidateSet('Current', 'Formal')][string]$Animations = '',
    [ValidateSet('1920x1080', '2560x1440', '1920x1200')][string]$Size = '1920x1080',
    [switch]$Smoke,
    [switch]$Capture,
    [ValidateRange(0.1, 90.0)][double]$CaptureAt = 10.6,
    [switch]$CodeCheck,
    [switch]$CodeCapture
)
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))

if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use pwsh.exe (PowerShell 7).' }
if (-not (Test-Path -LiteralPath $EnginePath -PathType Leaf)) { throw "Godot was not found at $EnginePath. Supply -EnginePath." }
$verificationModes = @($Smoke, $Capture, $CodeCheck, $CodeCapture) | Where-Object { $_ }
if (@($verificationModes).Count -gt 1) { throw 'Choose one verification mode: -Smoke, -Capture, -CodeCheck or -CodeCapture.' }
if ($Mode -and $Difficulty) { throw 'Adjust difficulty in the Debug menu. -Difficulty is an explicit standalone fixture and cannot be combined with -Mode.' }
$cacheRoot = Join-Path $projectRoot '.godot'
New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null
$legacyFixture = $Difficulty -or (($Smoke -or $Capture) -and -not $Mode)
$integrationCheck = $CodeCheck -or $CodeCapture -or ($Mode -eq 'Release' -and $Capture)
if ($CodeCheck -or $CodeCapture) {
    if ($Mode -or $Difficulty -or $PSBoundParameters.ContainsKey('Animations')) { throw '-CodeCheck/-CodeCapture use the original integration fixture; do not combine them with mode, difficulty or animation options.' }
    $Animations = 'Formal'
} elseif ($legacyFixture) {
    if (-not $Difficulty) { $Difficulty = 'Manual' }
    if (-not $Animations) { $Animations = 'Formal' }
} else {
    if (-not $Mode) { $Mode = 'Debug' }
    if (-not $Animations) { $Animations = 'Formal' }
    if ($Mode -eq 'Release' -and $Animations -ne 'Formal') { throw 'Release uses formal assets. Use -Mode Debug for development controls.' }
}
if ($Animations -eq 'Current') {
    foreach ($candidate in @('guard', 'archer', 'striker', 'healer', 'inventor')) {
        $candidatePath = Join-Path $projectRoot "assets/art/characters/$candidate/battle_animation.tres"
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) { throw "Formal animation is missing in this checkout: $candidatePath." }
        foreach ($match in [regex]::Matches([IO.File]::ReadAllText($candidatePath), 'path="res://([^"\r\n]+\.png)"')) {
            $framePath = Join-Path $projectRoot $match.Groups[1].Value
            if (-not (Test-Path -LiteralPath $framePath -PathType Leaf)) { throw "Formal frame is missing: $framePath" }
        }
    }
}
if ($integrationCheck) {
    $logPath = Join-Path $cacheRoot 'main-code-integration.log'
    $arguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', '--log-file', $logPath)
    if ($CodeCheck) { $arguments += @('--headless', '--quit-after', '3000') }
    $arguments += 'res://scenes/battle_demo/code_integration_check.tscn'
    if ($CodeCapture -or $Capture) { $arguments += @('--', '--capture', "--size=$Size") }
} elseif ($legacyFixture) {
    $logPath = Join-Path $cacheRoot 'battle-demo.log'
    $arguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', '--log-file', $logPath, '--resolution', $Size)
    if ($Smoke) { $arguments += '--headless' }
    $arguments += @('res://scenes/battle_demo/battle_demo.tscn', '--', "--demo-difficulty=$($Difficulty.ToLowerInvariant())", "--demo-animations=$($Animations.ToLowerInvariant())", "--demo-size=$Size")
    if ($Smoke) { $arguments += '--demo-smoke' }
    if ($Capture) { $arguments += @('--demo-capture', "--demo-capture-at=$($CaptureAt.ToString([Globalization.CultureInfo]::InvariantCulture))") }
    Write-Host "战斗样本：$Difficulty / $Animations"
} else {
    $logPath = Join-Path $cacheRoot "battle-demo-$($Mode.ToLowerInvariant()).log"
    $arguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', '--log-file', $logPath, '--resolution', $Size)
    if ($Smoke) { $arguments += @('--headless', '--quit-after', '3000') }
    $arguments += @('res://scenes/expedition/expedition.tscn', '--', "--demo-animations=$($Animations.ToLowerInvariant())", "--demo-size=$Size")
    if ($Mode -eq 'Debug') {
        $arguments += @('--campus-debug', '--debug-battle')
        if ($Smoke -or $Capture) { $arguments += '--debug-battle-check' }
        if ($Capture) { $arguments += '--debug-battle-capture' }
    } elseif ($Smoke) { $arguments += '--debug-check' }
}
if ($Mode) { Write-Host "启动模式：$Mode / $Animations" }
. (Join-Path $projectRoot 'tools/development/project-health.ps1')
$health = Initialize-GodotProject -ProjectPath $projectRoot -EnginePath $EnginePath
Write-Host "启动预检通过：$($health.Checks) 项"
$quotedArguments = $arguments | ForEach-Object { '"{0}"' -f $_ }
$windowStyle = if ($Smoke -or $Capture -or $CodeCheck -or $CodeCapture) { 'Hidden' } else { 'Normal' }
$gameProcess = Start-Process -FilePath $EnginePath -ArgumentList $quotedArguments -WorkingDirectory $projectRoot -WindowStyle $windowStyle -Wait -PassThru
Assert-GodotRunLog -LogPath $logPath -ExitCode $gameProcess.ExitCode
$output = Get-Content -LiteralPath $logPath -Raw
if ($output -match 'SCRIPT ERROR|Parse Error|Assertion failed|Cannot load formal animation|Missing formal frame') { throw "Launch failed. See $logPath" }
if ($integrationCheck) {
    if ($output -notmatch '(?m)MAIN_CODE_CHECK checks=\d+ failures=0') { throw 'Original battle integration verification did not pass.' }
} elseif ($Mode -and ($Smoke -or $Capture)) {
    $marker = if ($Mode -eq 'Debug') { 'DEBUG_BATTLE_CHECK' } else { 'DEBUG_CHECK' }
    if ($output -notmatch "(?m)$marker \d+ checks / 0 failures") { throw "Mode verification did not complete. See $logPath" }
} elseif ($Smoke) {
    $marker = if ($Difficulty -eq 'Manual') { 'DEMO_SPEED' } else { 'DEMO_DIFFICULTY_CHECK result=PASS' }
    if (-not $output.Contains($marker)) { throw "Battle verification did not complete. See $logPath" }
}
exit 0
