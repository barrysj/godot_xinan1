param(
    [string]$Godot = "$PSScriptRoot/.godot/web-tools/engine/Godot_v4.7.2-stable_win64_console.exe"
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) {
    throw '请通过 -Godot 指定 Godot 4.7.2 标准版（非 Mono）可执行文件；并在编辑器中安装同版本导出模板。'
}
$version = & $Godot --version
if ($version -notmatch '^4\.7\.2\.stable' -or $version -match 'mono') {
    throw "需要 Godot 4.7.2 标准版，当前为 $version"
}
Push-Location $PSScriptRoot
try {
    & $Godot --headless --editor --path . --import
    if ($LASTEXITCODE -ne 0) { throw '资源导入失败' }
    New-Item -ItemType Directory -Force builds/web | Out-Null
    & $Godot --headless --path . --export-release Web builds/web/index.html
    if ($LASTEXITCODE -ne 0) { throw 'Web 导出失败' }
    foreach ($name in @('index.html', 'index.wasm', 'index.pck')) {
        if (-not (Test-Path "builds/web/$name") -or (Get-Item "builds/web/$name").Length -eq 0) {
            throw "缺少构建产物：$name"
        }
    }
    New-Item -ItemType File -Force builds/web/.nojekyll | Out-Null
    Write-Host 'Web 构建完成：builds/web/index.html（需通过 HTTP 服务打开）'
} finally {
    Pop-Location
}
