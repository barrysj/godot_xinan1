# Explicit debug launch; uses campus_debug_progress.json, never the normal profile.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [switch]$Check,
    [switch]$Capture
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
if ($Check -and $Capture) { throw 'Choose -Check or -Capture.' }
. (Join-Path $PSScriptRoot 'tools/development/project-health.ps1')
$health = Initialize-GodotProject -ProjectPath $PSScriptRoot -EnginePath $EnginePath
Write-Host "启动预检通过：$($health.Checks) 项"
$debugArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/debug-mode.log'))
if ($Check) { $debugArgs += @('--headless', '--quit-after', '3600') }
$debugArgs += @('res://scenes/expedition/expedition.tscn', '--', '--campus-debug')
if ($Check -or $Capture) { $debugArgs += '--debug-check' }
if ($Capture) { $debugArgs += '--debug-capture' }
$quotedArgs = $debugArgs | ForEach-Object { '"{0}"' -f $_ }
$process = Start-Process -FilePath $EnginePath -ArgumentList $quotedArgs -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -PassThru
Assert-GodotRunLog -LogPath (Join-Path $PSScriptRoot '.godot/debug-mode.log') -ExitCode $process.ExitCode
if ($Check -or $Capture) {
    $text = Get-Content -LiteralPath (Join-Path $PSScriptRoot '.godot/debug-mode.log') -Raw
    if ($text -notmatch '(?m)DEBUG_CHECK \d+ checks / 0 failures') { throw 'Debug verification did not finish successfully.' }
}
exit 0
