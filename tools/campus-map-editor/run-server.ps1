# Launch one verified local map editor service for this worktree.
param(
    [ValidateRange(1, 65535)]
    [int]$Port = 8767,
    [switch]$NoOpen
)
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$serverPath = Join-Path $PSScriptRoot 'server.mjs'
$node = Get-Command node.exe -ErrorAction SilentlyContinue
if (-not $node) { throw 'Node.js was not found on PATH.' }
if (-not (Test-Path -LiteralPath $serverPath -PathType Leaf)) { throw "Map editor server not found: $serverPath" }
$url = "http://127.0.0.1:$Port/"
$healthUrl = "${url}api/health"
$expectedApp = 'cyber-pop-campus-map-editor-v1'

function Test-OwnHealth($health) {
    if (-not $health -or $health.app -ne $expectedApp) { return $false }
    try { $serviceRoot = [IO.Path]::GetFullPath([string]$health.project_root) }
    catch { return $false }
    return [string]::Equals($projectRoot, $serviceRoot, [StringComparison]::OrdinalIgnoreCase)
}
function Test-PortOpen {
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $pending = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        return $pending.AsyncWaitHandle.WaitOne(180) -and $client.Connected
    } catch { return $false }
    finally { $client.Dispose() }
}

$health = $null
try { $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 1 } catch { }
if ($health) {
    if (-not (Test-OwnHealth $health)) { throw "Port $Port belongs to a different service or worktree." }
} elseif (Test-PortOpen) {
    throw "Port $Port is occupied; its service identity could not be verified."
} else {
    $service = Start-Process -FilePath $node.Source -ArgumentList @(('"{0}"' -f $serverPath), '--port', $Port) -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru
    $ready = $false
    foreach ($attempt in 1..50) {
        Start-Sleep -Milliseconds 100
        if ($service.HasExited) { throw "Map editor stopped during startup (exit code $($service.ExitCode))." }
        try {
            $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 1
            if (Test-OwnHealth $health) { $ready = $true; break }
        } catch { }
    }
    if (-not $ready) {
        Stop-Process -Id $service.Id -ErrorAction SilentlyContinue
        throw 'Map editor did not become ready.'
    }
}
Write-Host "Map editor: $url"
if (-not $NoOpen) { Start-Process $url }
