#requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$Card,
    [string]$Godot = $env:GODOT_PATH,
    [switch]$SkipImport
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
if (-not $Godot) {
    $found = Get-Command godot, godot.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $Godot = $found.Source }
}
if (-not $Godot -or -not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw '请用 -Godot 或 GODOT_PATH 指定 Godot 可执行文件。' }
$relative = if ($Card.StartsWith('res://')) { $Card.Substring(6) } else { $Card }
$cardFile = (Resolve-Path -LiteralPath (Join-Path $projectRoot $relative)).Path
$cardRoot = (Resolve-Path -LiteralPath (Join-Path $projectRoot 'assets/art/holo_cards')).Path
if (-not $cardFile.StartsWith($cardRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($cardFile) -ne 'card.tres') { throw '只接受 assets/art/holo_cards/<id>/card.tres。' }
$uri = 'res://' + [IO.Path]::GetRelativePath($projectRoot,$cardFile).Replace('\','/')
$logDirectory = Join-Path $projectRoot '.godot/holo-card'
New-Item -ItemType Directory -Force $logDirectory | Out-Null
if (-not $SkipImport) {
    & $Godot --headless --editor --path $projectRoot --import --log-file (Join-Path $logDirectory 'review-import.log')
    if ($LASTEXITCODE -ne 0) { throw '资源导入失败。' }
}
# Rendering requires a real renderer; --headless uses a dummy renderer.
$output = & $Godot --path $projectRoot --rendering-method gl_compatibility --resolution 1600x1400 --quit-after 600 res://scenes/holo_card/render_review.tscn -- "--card=$uri" 2>&1
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
$text = $output -join "`n"
if ($code -ne 0 -or $text -match 'SCRIPT ERROR:|SHADER ERROR:|ERROR:' -or $text -notmatch 'HOLO_REVIEW_COMPLETE') { throw '截图流程出现异常，请检查上方输出及 review.png，勿将其作为已验证结果。' }
Write-Host "生成完成：$(Join-Path (Split-Path $cardFile) 'review.png')"
