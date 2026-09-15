# Launch the prebuilt native Windows art-manager controller.
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }

$projectRoot = $PSScriptRoot
$outputPath = Join-Path $projectRoot '.godot/art-manager-control/ArtManagerControl.exe'
if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw 'Controller is not built. Run: pwsh.exe -NoProfile -File .\tools\art\asset_manager\control\build-control.ps1'
}
Start-Process -FilePath $outputPath -WorkingDirectory $projectRoot
