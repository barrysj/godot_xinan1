# Build when missing or stale, then open the native controller.
param([switch]$PassThru)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }

$projectRoot = $PSScriptRoot
$outputPath = Join-Path $projectRoot '.godot/art-manager-control/ArtManagerControl.exe'
$buildScript = Join-Path $projectRoot 'tools/art/asset_manager/control/build-control.ps1'
$sourcePath = Join-Path $projectRoot 'tools/art/asset_manager/control/ArtManagerControl.cs'
$stampPath = "$outputPath.sources"
$signature = ((Get-FileHash -LiteralPath $sourcePath,$buildScript -Algorithm SHA256).Hash -join ':')
if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $stampPath -PathType Leaf) -or
    (Get-Content -LiteralPath $stampPath -Raw).Trim() -ne $signature) {
    & $buildScript
}
Start-Process -FilePath $outputPath -WorkingDirectory $projectRoot -PassThru:$PassThru
