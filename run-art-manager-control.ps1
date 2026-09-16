# Build when missing or stale, then launch the native Windows controller.
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }

$projectRoot = $PSScriptRoot
$ErrorActionPreference = 'Stop'
$outputPath = Join-Path $projectRoot '.godot/art-manager-control/ArtManagerControl.exe'
$buildScript = Join-Path $projectRoot 'tools/art/asset_manager/control/build-control.ps1'
$sourcePath = Join-Path $projectRoot 'tools/art/asset_manager/control/ArtManagerControl.cs'
$needsBuild = -not (Test-Path -LiteralPath $outputPath -PathType Leaf)
if (-not $needsBuild) {
    $builtAt = (Get-Item -LiteralPath $outputPath).LastWriteTimeUtc
    $needsBuild = (Get-Item -LiteralPath $sourcePath).LastWriteTimeUtc -gt $builtAt -or (Get-Item -LiteralPath $buildScript).LastWriteTimeUtc -gt $builtAt
}
if ($needsBuild) {
    Write-Host 'Building art-manager controller...'
    & $buildScript
}
Start-Process -FilePath $outputPath -WorkingDirectory $projectRoot
