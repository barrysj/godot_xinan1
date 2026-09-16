#requires -Version 7.0
param(
    [ValidateSet('Preview','Check','Layers')][string]$Mode = 'Preview',
    [string]$Godot = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe',
    [string]$Card = 'res://design/concepts/class-photo-holo-card/card/002/card.tres'
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw '请用 -Godot 指定引擎。' }
& $Godot --headless --editor --path $PSScriptRoot --import --log-file "$PSScriptRoot/.godot/holo-import.log"
if ($LASTEXITCODE -ne 0) { throw 'Godot 资源导入失败。' }
$arguments = @('--path',$PSScriptRoot,'--rendering-method','gl_compatibility','--resolution','1600x1000','--log-file',"$PSScriptRoot/.godot/holo-card.log",'res://scenes/holo_card/holo_card_preview.tscn','--',"--card=$Card")
if ($Mode -eq 'Check') { $arguments += '--card-check' }
if ($Mode -eq 'Layers') { $arguments += '--card-layers' }
& $Godot @arguments
$code = $LASTEXITCODE
$log = Get-Content -Raw "$PSScriptRoot/.godot/holo-card.log"
if ($code -ne 0 -or $log -match 'SCRIPT ERROR:|SHADER ERROR:') { throw '卡片运行失败，请检查 .godot/holo-card.log。' }
if ($Mode -eq 'Check' -and $log -notmatch 'HOLO_CARD_CHECK failures=0') { throw '检查没有完成。' }
if ($Mode -eq 'Layers' -and $log -notmatch 'HOLO_CARD_LAYERS_COMPLETE') { throw '图层没有完成。' }
