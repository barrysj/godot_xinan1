# Build and launch the native Windows art-manager controller.
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }

$projectRoot = $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'tools/art/asset_manager/control/ArtManagerControl.cs'
$outputDirectory = Join-Path $projectRoot '.godot/art-manager-control'
$outputPath = Join-Path $outputDirectory 'ArtManagerControl.exe'
$frameworkRoot = Join-Path $env:WINDIR 'Microsoft.NET'
$compilerCandidates = @(
    (Join-Path $frameworkRoot 'Framework64/v4.0.30319/csc.exe'),
    (Join-Path $frameworkRoot 'Framework/v4.0.30319/csc.exe')
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

if (-not $compiler) { throw 'The Windows C# compiler was not found.' }
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Controller source not found: $sourcePath" }

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$needsBuild = -not (Test-Path -LiteralPath $outputPath -PathType Leaf)
if (-not $needsBuild) {
    $needsBuild = (Get-Item -LiteralPath $sourcePath).LastWriteTimeUtc -gt (Get-Item -LiteralPath $outputPath).LastWriteTimeUtc
}

if ($needsBuild) {
    & $compiler /nologo /target:winexe /optimize+ /out:$outputPath /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.Extensions.dll $sourcePath
    if ($LASTEXITCODE -ne 0) { throw "Controller build failed with exit code $LASTEXITCODE." }
}

Start-Process -FilePath $outputPath -WorkingDirectory $projectRoot
