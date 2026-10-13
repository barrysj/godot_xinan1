param(
    [string]$EnginePath = 'F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe',
    [string]$ProjectPath = $PSScriptRoot,
    [switch]$Repair,
    [switch]$NoRepair,
    [ValidateRange(5, 1800)][int]$TimeoutSeconds = 300
)
. (Join-Path $PSScriptRoot 'tools/development/project-health.ps1')
try {
    $result = Initialize-GodotProject -ProjectPath $ProjectPath -EnginePath $EnginePath -Repair:$Repair -NoRepair:$NoRepair -TimeoutSeconds $TimeoutSeconds
    Write-Host "工程检查通过：$($result.Checks) 项，已导入=$($result.Imported)，故障修复=$($result.Repaired)"
    Write-Host ($result.Logs -join "`n")
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
