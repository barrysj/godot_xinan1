# Local art browser. It reads project files and never touches player saves.
param(
    [ValidateRange(1, 65535)]
    [int]$Port = 8765,
    [string]$EnginePath = '',
    [switch]$NoOpen
)

if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }

$projectRoot = $PSScriptRoot
$serverPath = Join-Path $projectRoot 'tools/art/asset_manager/server.py'
$previewScript = Join-Path $projectRoot 'run-motion-preview.ps1'
$python = Get-Command py.exe -ErrorAction SilentlyContinue
if (-not $python) { throw 'Python 3 launcher not found. Install Python 3 or expose py.exe.' }
if (-not (Test-Path -LiteralPath $serverPath -PathType Leaf)) { throw "Art manager server not found: $serverPath" }

if (-not $EnginePath -and (Test-Path -LiteralPath $previewScript -PathType Leaf)) {
    $previewText = Get-Content -Raw -LiteralPath $previewScript
    if ($previewText -match "\[string\]\`$EnginePath\s*=\s*'([^']+)'") { $EnginePath = $Matches[1] }
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot '.godot/imported') -PathType Container)) {
    if (-not $EnginePath -or -not (Test-Path -LiteralPath $EnginePath -PathType Leaf)) {
        throw 'Godot resources are not imported. Set -EnginePath for the first launch.'
    }
    Write-Host 'First launch: importing project resources...'
    & $EnginePath --headless --editor --path $projectRoot --quit
    if ($LASTEXITCODE -ne 0) { throw "Godot resource import failed with exit code $LASTEXITCODE." }
}

$url = "http://127.0.0.1:$Port/"
$healthUrl = "${url}api/health"
$isRunning = $false
try {
    $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 1
    $isRunning = $health.app -eq 'cyber-pop-art-manager-v2'
    if (-not $isRunning) { throw "Port $Port is occupied by another service." }
} catch {
    if ($_.Exception.Message -like "*occupied by another service*") { throw }
}

if (-not $isRunning) {
    $arguments = @(
        '-3',
        ('"{0}"' -f $serverPath),
        '--port',
        $Port,
        '--project-root',
        ('"{0}"' -f $projectRoot)
    )
    $service = Start-Process -FilePath $python.Source -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru
    $ready = $false
    foreach ($attempt in 1..50) {
        Start-Sleep -Milliseconds 100
        if ($service.HasExited) { throw "Art manager stopped during startup (exit code $($service.ExitCode))." }
        try {
            $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 1
            if ($health.app -eq 'cyber-pop-art-manager-v2') { $ready = $true; break }
        } catch { }
    }
    if (-not $ready) {
        Stop-Process -Id $service.Id -ErrorAction SilentlyContinue
        throw 'Art manager did not become ready.'
    }
}

Write-Host "Art manager: $url"
if (-not $NoOpen) { Start-Process $url }
