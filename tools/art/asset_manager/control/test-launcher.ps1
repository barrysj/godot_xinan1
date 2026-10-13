# Integration regression for the shared tool-suite launcher.
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use PowerShell 7 (pwsh.exe).' }
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$exe = Join-Path $root 'tools/art/asset_manager/control/ArtManagerControl.exe'
$stamp = "$exe.sources"
if (-not [IO.Path]::GetFullPath($exe).StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'Controller path escaped project root.' }
if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe }
foreach ($mode in @('missing', 'cached', 'stale')) {
    if ($mode -eq 'stale') { Set-Content -LiteralPath $stamp -Value 'outdated-build' }
    $before = if (Test-Path -LiteralPath $exe) { (Get-Item -LiteralPath $exe).LastWriteTimeUtc } else { $null }
    $process = & (Join-Path $root 'tools/art/asset_manager/control/run-tool-suite-control.ps1') -PassThru
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
        Write-Host "TOOL_SUITE_LAUNCHER_CHECK $mode PASS"
    } finally {
        if (-not $process.HasExited) {
            $process.CloseMainWindow() | Out-Null
            if (-not $process.WaitForExit(3000)) { $process.Kill(); $process.WaitForExit() }
        }
    }
}
