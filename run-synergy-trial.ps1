param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe',
    [switch]$Check,
    [switch]$Capture
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use pwsh.exe (PowerShell 7).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw "Godot not found: $EnginePath" }
if ($Check) {
    $scenes = @(
        'game/trial/code_check',
        'scenes/trial/code_ui_check',
        'game/trial/trial_content_check',
        'game/trial/trial_proc_check',
        'game/trial/trial_run_check',
        'scenes/trial/trial_check',
        'scenes/trial/trial_presentation_check',
        'game/combat/accuracy_check',
        'game/combat/action_check',
        'game/combat/auto_battle_check'
    )
    foreach ($scene in $scenes) {
        $logName = ($scene -split '/')[-1]
        $logPath = Join-Path $PSScriptRoot ".godot/$logName.log"
        & $EnginePath --headless --path $PSScriptRoot --quit-after 3000 --log-file $logPath "res://$scene.tscn"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $testOutput = Get-Content -LiteralPath $logPath -Raw
        if ($testOutput -match 'SCRIPT ERROR' -or $testOutput -notmatch '(?m)CHECK[^\r\n]*(PASS|failures=0|0 failures)') {
            Write-Error "Check did not report success: $scene"
            exit 1
        }
    }
    exit 0
}
$trialArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/trial.log'), 'res://scenes/trial/trial.tscn')
if ($Capture) { $trialArgs += @('--', '--trial-capture') }
& $EnginePath @trialArgs
exit $LASTEXITCODE
