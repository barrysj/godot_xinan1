# Integration regression: missing cache, unchanged cache, and stale source signature.
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$exe = Join-Path $root '.godot/art-manager-control/ArtManagerControl.exe'
$stamp = "$exe.sources"
if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe }
foreach ($mode in @('missing', 'cached', 'stale')) {
    if ($mode -eq 'stale') { Set-Content -LiteralPath $stamp -Value 'outdated-build' }
    $before = if (Test-Path -LiteralPath $exe) { (Get-Item -LiteralPath $exe).LastWriteTimeUtc } else { $null }
    $process = & (Join-Path $root 'run-art-manager-control.ps1') -PassThru
    try {
        if (-not $process.WaitForInputIdle(10000)) { throw 'Controller did not become ready' }
        $deadline = [DateTime]::UtcNow.AddSeconds(10)
        do {
            Start-Sleep -Milliseconds 100
            $process.Refresh()
        } while (-not $process.HasExited -and $process.MainWindowHandle -eq 0 -and [DateTime]::UtcNow -lt $deadline)
        if ($process.HasExited -or $process.MainWindowHandle -eq 0) { throw 'Controller window did not open' }
        $after = (Get-Item -LiteralPath $exe).LastWriteTimeUtc
        if ($mode -eq 'cached' -and $before -ne $after) { throw 'Unchanged build was rebuilt' }
        if ($mode -eq 'stale' -and $before -eq $after) { throw 'Stale build was reused' }
        Write-Host "LAUNCHER_CHECK $mode PASS"
    } finally {
        if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
    }
}
