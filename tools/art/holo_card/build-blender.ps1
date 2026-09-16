#requires -Version 7.0
param(
    [string]$Blender = 'E:/Games/SteamLibrary/steamapps/common/Blender/blender.exe',
    [string]$Python = 'python',
    [string]$CardDirectory = 'design/concepts/class-photo-holo-card/card/001/ruic'
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$outputRoot = Join-Path $projectRoot $CardDirectory
if (-not (Test-Path -LiteralPath $Blender)) { throw '请指定 Blender 4.5 LTS 路径。' }
$version = & $Blender --version
if ($version[0] -notmatch '^Blender 4\.5\.') { throw '本入口已验证 Blender 4.5.x，请先单独验证其他版本。' }
& $Python (Join-Path $PSScriptRoot 'upstream/validate_assets.py') $outputRoot
if ($LASTEXITCODE -ne 0) { throw 'RuiC 图层校验失败；Python 需要 Pillow。' }
$oldConfig = $env:BLENDER_USER_CONFIG
try {
    $env:BLENDER_USER_CONFIG = Join-Path $projectRoot '.godot/holo-blender-config'
    New-Item -ItemType Directory -Force $env:BLENDER_USER_CONFIG | Out-Null
    & $Blender --background --factory-startup --python (Join-Path $PSScriptRoot 'build_blender.py') -- $outputRoot
    if ($LASTEXITCODE -ne 0) { throw 'Blender 构建失败。' }
} finally {
    if ($null -eq $oldConfig) { Remove-Item Env:BLENDER_USER_CONFIG -ErrorAction SilentlyContinue }
    else { $env:BLENDER_USER_CONFIG = $oldConfig }
}
