param(
    [string]$EnginePath = 'F:\Applications\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe',
    [switch]$Smoke,
    [switch]$MetaSmoke
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run this script using pwsh.exe.' }
if (-not (Test-Path -LiteralPath $EnginePath)) { throw "Godot not found: $EnginePath" }
. (Join-Path $PSScriptRoot 'tools/development/project-health.ps1')
$health = Initialize-GodotProject -ProjectPath $PSScriptRoot -EnginePath $EnginePath
Write-Host "启动预检通过：$($health.Checks) 项"
$campusArguments = @('--path', $PSScriptRoot, '--rendering-method', 'gl_compatibility',
    '--log-file', (Join-Path $PSScriptRoot '.godot/campus-demo.log'))
if ($Smoke -or $MetaSmoke) { $campusArguments += '--headless' }
$campusArguments += 'res://scenes/expedition/expedition.tscn'
if ($MetaSmoke) { $campusArguments += @('--', '--meta-smoke') }
elseif ($Smoke) { $campusArguments += @('--', '--run-smoke') }
$quotedArguments = $campusArguments | ForEach-Object { '"{0}"' -f $_ }
$windowStyle = if ($Smoke -or $MetaSmoke) { 'Hidden' } else { 'Normal' }
$process = Start-Process -FilePath $EnginePath -ArgumentList $quotedArguments -WorkingDirectory $PSScriptRoot -WindowStyle $windowStyle -Wait -PassThru
Assert-GodotRunLog -LogPath (Join-Path $PSScriptRoot '.godot/campus-demo.log') -ExitCode $process.ExitCode
exit 0
