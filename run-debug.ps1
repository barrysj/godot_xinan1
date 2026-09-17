# Explicit debug launch; uses campus_debug_progress.json, never the normal profile.
param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [switch]$Check,
    [switch]$Capture
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw 'Godot not found. Set -EnginePath.' }
if ($Check -and $Capture) { throw 'Choose -Check or -Capture.' }
$debugArgs = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility', '--log-file', (Join-Path $PSScriptRoot '.godot/debug-mode.log'))
if ($Check) { $debugArgs += '--headless' }
$debugArgs += @('res://scenes/expedition/expedition.tscn', '--', '--campus-debug')
if ($Check -or $Capture) { $debugArgs += '--debug-check' }
if ($Capture) { $debugArgs += '--debug-capture' }
$quotedArgs = $debugArgs | ForEach-Object { '"{0}"' -f $_ }
$process = Start-Process -FilePath $EnginePath -ArgumentList $quotedArgs -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -Wait -PassThru
exit $process.ExitCode
