#requires -Version 7.0
param(
    [ValidateSet('Preview','Check','Layers')][string]$Mode = 'Preview',
    [string]$Godot = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe',
    [string]$Card = 'res://assets/art/holo_cards/class_photo/card.tres'
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw '请用 -Godot 指定引擎。' }
$importArgs = @('--headless', '--editor', '--path', "`"$PSScriptRoot`"", '--import', '--log-file', "`"$PSScriptRoot/.godot/holo-import.log`"")
$importProcess = Start-Process -FilePath $Godot -ArgumentList $importArgs -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru
if (-not $importProcess.WaitForExit(120000)) {
    $importProcess.Kill()
    throw 'Godot 资源导入超过 120 秒，请检查 .godot/holo-import.log。'
}
if ($importProcess.ExitCode -ne 0) { throw 'Godot 资源导入失败，请检查 .godot/holo-import.log。' }
$arguments = @('--path',$PSScriptRoot,'--rendering-method','gl_compatibility','--resolution','1600x1000','--log-file',"$PSScriptRoot/.godot/holo-card.log",'res://scenes/holo_card/holo_card_preview.tscn','--',"--card=$Card")
if ($Mode -eq 'Check') { $arguments += '--card-check' }
if ($Mode -eq 'Layers') { $arguments += '--card-layers' }
# GUI executables do not reliably block when invoked with & in PowerShell.
# Keep the launcher alive for the entire preview, for both GUI and console Godot.
$quotedArguments = $arguments | ForEach-Object { '"{0}"' -f $_ }
$previewProcess = Start-Process -FilePath $Godot -ArgumentList $quotedArguments -WorkingDirectory $PSScriptRoot -Wait -PassThru
$code = $previewProcess.ExitCode
$log = Get-Content -Raw "$PSScriptRoot/.godot/holo-card.log"
if ($code -ne 0 -or $log -match 'SCRIPT ERROR:|SHADER ERROR:') { throw '卡片运行失败，请检查 .godot/holo-card.log。' }
if ($Mode -eq 'Check' -and $log -notmatch 'HOLO_CARD_CHECK failures=0') { throw '检查没有完成。' }
if ($Mode -eq 'Layers' -and $log -notmatch 'HOLO_CARD_LAYERS_COMPLETE') { throw '图层没有完成。' }
