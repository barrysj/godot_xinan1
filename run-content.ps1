param(
    [ValidateSet('Validate', 'Preview', 'Check')][string]$Mode = 'Preview',
    [string]$Godot = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
)
#requires -Version 7.0
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw "找不到 Godot，请使用 -Godot 指定引擎路径。" }
$arguments = @('--path', $PSScriptRoot, '--log-file', (Join-Path $PSScriptRoot '.godot/content-tool.log'))
switch ($Mode) {
    'Validate' { $arguments += @('--headless', '--script', 'res://game/content/validate_content.gd') }
    'Preview' { $arguments += @('--rendering-method', 'gl_compatibility', 'res://scenes/content/content_preview.tscn') }
    'Check' { $arguments += @('--rendering-method', 'gl_compatibility', '--quit-after', '600', 'res://scenes/expedition/expedition.tscn', '--', '--content-check') }
}
& $Godot @arguments
$engineExitCode = $LASTEXITCODE
if ($Mode -eq 'Check') {
    $testLog = Get-Content -LiteralPath (Join-Path $PSScriptRoot '.godot/content-tool.log') -Raw
    if ($engineExitCode -ne 0 -or $testLog -notmatch 'CONTENT_CHECK_COMPLETE' -or $testLog -match 'SCRIPT ERROR:') {
        throw '内容检查未全部通过，请检查 .godot/content-tool.log。'
    }
}
exit $engineExitCode
