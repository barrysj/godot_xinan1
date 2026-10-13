# Shared PowerShell 7 preparation for local source checkouts, not exported games.
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Use pwsh.exe (PowerShell 7).' }

function Get-ProjectSourceKey {
    param([string]$ProjectPath, [string]$EnginePath)
    $engine = Get-Item -LiteralPath $EnginePath
    $parts = [Collections.Generic.List[string]]::new()
    $parts.Add("health-v1|$ProjectPath|$EnginePath|$($engine.Length)|$($engine.LastWriteTimeUtc.Ticks)")
    $head = & git -c "safe.directory=$ProjectPath" -C $ProjectPath rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0) { return $null } # Non-Git projects always prepare.
    $parts.Add(($head -join ''))
    $changed = @(& git -c "safe.directory=$ProjectPath" -c core.quotepath=false -C $ProjectPath diff --name-only HEAD --)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect modified project sources.' }
    $changed += @(& git -c "safe.directory=$ProjectPath" -c core.quotepath=false -C $ProjectPath ls-files --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect new project sources.' }
    foreach ($relative in ($changed | Sort-Object -Unique)) {
        $path = [IO.Path]::GetFullPath((Join-Path $ProjectPath $relative))
        if (-not $path.StartsWith($ProjectPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Source path escaped project: $relative"
        }
        $hash = if (Test-Path -LiteralPath $path -PathType Leaf) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { 'deleted' }
        $parts.Add("$relative|$hash")
    }
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($parts -join "`n"))))
}

function Invoke-GodotHealthStage {
    param([string]$EnginePath, [string]$ProjectPath, [string[]]$Arguments, [string]$LogPath, [int]$TimeoutSeconds)
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $EnginePath
    $info.WorkingDirectory = $ProjectPath
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $info.ArgumentList.Add('--log-file')
    $info.ArgumentList.Add($LogPath)
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    try {
        if (-not $process.Start()) { throw 'Could not start Godot.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill($true)
            $process.WaitForExit()
            throw "Godot preparation timed out. See $LogPath"
        }
        $text = $stdout.GetAwaiter().GetResult() + "`n" + $stderr.GetAwaiter().GetResult()
        if (Test-Path -LiteralPath $LogPath) { $text += "`n" + [IO.File]::ReadAllText($LogPath) }
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Text = $text; LogPath = $LogPath }
    } finally { $process.Dispose() }
}

function Get-GodotHealthErrors {
    param([string]$Text)
    # Existing machine/editor warnings do not invalidate the source import.
    $known = 'Failed to read the root certificate store|EditorSettings not instantiated yet.*export/android/shutdown_adb_on_exit'
    foreach ($line in ($Text -split "`n")) {
        if ($line -match '^SCRIPT ERROR:|^ERROR:' -and $line -notmatch $known) { $line.Trim() }
    }
}

function Assert-GodotRunLog {
    param([string]$LogPath, [int]$ExitCode)
    if ($ExitCode -ne 0) { throw "Godot exited $ExitCode. See $LogPath" }
    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) { throw "Missing Godot log: $LogPath" }
    $errors = @(Get-GodotHealthErrors ([IO.File]::ReadAllText($LogPath)))
    if ($errors.Count) { throw "Godot reported errors despite exit code 0. See $LogPath`n$($errors[0])" }
}

function Initialize-GodotProject {
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][string]$EnginePath,
        [switch]$Repair,
        [switch]$NoRepair,
        [ValidateRange(5, 1800)][int]$TimeoutSeconds = 300,
        [string]$ProbeScene = 'res://tools/development/project_startup_check.tscn'
    )
    if ($Repair -and $NoRepair) { throw 'Choose -Repair or -NoRepair.' }
    $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path.TrimEnd('\', '/')
    $EnginePath = (Resolve-Path -LiteralPath $EnginePath).Path
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath 'project.godot') -PathType Leaf)) { throw 'Not a Godot project.' }
    $cache = Join-Path $ProjectPath '.godot/project-health'
    [IO.Directory]::CreateDirectory($cache) | Out-Null
    $lock = $null
    try {
        try { $lock = [IO.File]::Open((Join-Path $cache 'prepare.lock'), 'OpenOrCreate', 'ReadWrite', 'None') }
        catch { throw 'Another project preparation is running. Wait for it to finish.' }
        $key = Get-ProjectSourceKey $ProjectPath $EnginePath
        $stampPath = Join-Path $cache 'ready.json'
        $stamp = $null
        if (Test-Path -LiteralPath $stampPath) {
            try { $stamp = [IO.File]::ReadAllText($stampPath) | ConvertFrom-Json } catch { $stamp = $null }
        }
        $cachePresent = (Test-Path -LiteralPath (Join-Path $ProjectPath '.godot/global_script_class_cache.cfg')) -and
            (Test-Path -LiteralPath (Join-Path $ProjectPath '.godot/imported') -PathType Container)
        $needsImport = $Repair -or -not $key -or -not $stamp -or $stamp.key -ne $key -or -not $cachePresent
        $id = [Guid]::NewGuid().ToString('N')
        $imported = $false
        $repaired = $false
        $logs = [Collections.Generic.List[string]]::new()
        # One preparation and at most one repair retry; never loop over a real code error.
        for ($attempt = 0; $attempt -lt 2; $attempt++) {
            if (-not $NoRepair -and ($needsImport -or $attempt -gt 0)) {
                $log = Join-Path $cache "$id-import-$attempt.log"
                $logs.Add($log)
                $result = Invoke-GodotHealthStage $EnginePath $ProjectPath @('--headless', '--editor', '--import', '--path', $ProjectPath) $log $TimeoutSeconds
                $errors = @(Get-GodotHealthErrors $result.Text)
                if ($result.ExitCode -ne 0 -or $errors.Count) { throw "Godot import failed. See $log`n$($errors | Select-Object -First 1)" }
                $imported = $true
                if ($attempt -gt 0) { $repaired = $true }
            }
            $log = Join-Path $cache "$id-probe-$attempt.log"
            $logs.Add($log)
            $result = Invoke-GodotHealthStage $EnginePath $ProjectPath @('--headless', '--path', $ProjectPath, '--quit-after', '300', $ProbeScene) $log $TimeoutSeconds
            $errors = @(Get-GodotHealthErrors $result.Text)
            $marker = [regex]::Match($result.Text, '(?m)^PROJECT_HEALTH_CHECK checks=([1-9]\d*) failures=0\s*$')
            if ($result.ExitCode -eq 0 -and -not $errors.Count -and $marker.Success) {
                if (-not $NoRepair) {
                    @{ key = $key; checked_at = [DateTime]::UtcNow.ToString('o'); probe = $ProbeScene } |
                        ConvertTo-Json | Set-Content -LiteralPath $stampPath -Encoding utf8
                }
                return [pscustomobject]@{ Status = 'ready'; Imported = $imported; Repaired = $repaired; Checks = [int]$marker.Groups[1].Value; Logs = $logs.ToArray() }
            }
            if ($NoRepair -or $imported -or $attempt -gt 0) {
                throw "Project startup check failed. See $log`n$($errors | Select-Object -First 1)"
            }
        }
    } finally { if ($lock) { $lock.Dispose() } }
}
