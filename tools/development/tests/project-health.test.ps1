param([Parameter(Mandatory)][string]$EnginePath)
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
. (Join-Path $project 'tools/development/project-health.ps1')
$fixtureRoot = Join-Path $project '.godot/art-workflow/project-health-tests'
$fixture = Join-Path $fixtureRoot ([Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture) | Out-Null
$checks = 0
function Expect([bool]$Condition, [string]$Message) {
    $script:checks++
    if (-not $Condition) { throw "PROJECT_HEALTH_TEST: $Message" }
}
function Prepare([switch]$NoRepair) {
    Initialize-GodotProject -ProjectPath $fixture -EnginePath $EnginePath -ProbeScene 'res://probe.tscn' -NoRepair:$NoRepair -TimeoutSeconds 60
}
function WriteSource([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText((Join-Path $fixture $Path), $Text, [Text.UTF8Encoding]::new($false))
}
try {
    WriteSource 'project.godot' @'
config_version=5
[application]
config/name="Project health regression"
run/main_scene="res://probe.tscn"
[rendering]
renderer/rendering_method="gl_compatibility"
'@
    WriteSource '.gitignore' ".godot/`n*.import`n*.uid`n"
    WriteSource 'icon.svg' '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><circle cx="8" cy="8" r="6" fill="cyan"/></svg>'
    WriteSource 'scene.gd' "class_name HealthScene`nextends Resource`n"
    WriteSource 'place.gd' "class_name HealthPlace`nextends Resource`n@export var scenes: Array[HealthScene] = []`n"
    $goodProbe = @'
extends Node
const Place = preload("res://place.gd")
const Icon = preload("res://icon.svg")
func _ready():
	assert(Place.new().scenes.is_empty())
	assert(Icon is Texture2D)
	print("PROJECT_HEALTH_CHECK checks=2 failures=0")
	get_tree().quit()
'@
    WriteSource 'probe.gd' $goodProbe
    WriteSource 'probe.tscn' "[gd_scene load_steps=2 format=3]`n[ext_resource type=`"Script`" path=`"res://probe.gd`" id=`"1`"]`n[node name=`"Probe`" type=`"Node`"]`nscript = ExtResource(`"1`")`n"
    & git -C $fixture init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize fixture repository.' }
    & git -C $fixture add -- .
    & git -C $fixture -c user.name=Codex -c user.email=codex@local.invalid commit --quiet -m 'test fixture'
    if ($LASTEXITCODE -ne 0) { throw 'Could not commit fixture sources.' }

    # This reproduces missing class registration and an unimported SVG, at the actual engine seam.
    $failed = $false
    try { Prepare -NoRepair | Out-Null } catch { $failed = $true }
    Expect $failed 'cold checkout is detected before any repair'
    $coldLog = (Get-ChildItem -LiteralPath (Join-Path $fixture '.godot/project-health') -Filter '*probe-0.log' | Select-Object -First 1).FullName
    $coldText = [IO.File]::ReadAllText($coldLog)
    Expect ($coldText -match 'scenes|HealthScene') 'actual class/type chain fails cold'
    Expect ($coldText -match 'icon.svg.*no resource loaders') 'actual unimported SVG fails cold'
    $ready = Prepare
    Expect ($ready.Imported -and $ready.Checks -eq 2) 'automatic cold import and real startup pass'
    $ready = Prepare
    Expect (-not $ready.Imported -and $ready.Checks -eq 2) 'unchanged checkout still probes but skips import'

    # Corrupt only an ignored local import descriptor: no Git/source-key change.
    Remove-Item -LiteralPath (Join-Path $fixture 'icon.svg.import')
    $failed = $false
    try { Prepare -NoRepair | Out-Null } catch { $failed = $true }
    Expect $failed 'missing local descriptor is detected even with an existing readiness stamp'
    $ready = Prepare
    Expect ($ready.Repaired -and $ready.Imported) 'cached failure gets one automatic import repair'

    WriteSource 'probe.gd' ($goodProbe + "`n# source edit`n")
    $ready = Prepare
    Expect $ready.Imported 'unstaged source edit causes import'
    & git -C $fixture add -- probe.gd
    $ready = Prepare
    Expect (-not $ready.Imported) 'staging alone does not change source readiness'
    WriteSource 'probe.gd' ($goodProbe + "`n# another edit with same Git status`n")
    $ready = Prepare
    Expect $ready.Imported 'source content changes are detected independently of Git status'

    WriteSource 'probe.gd' 'this is invalid GDScript'
    $failed = $false
    try { Prepare | Out-Null } catch { $failed = $true }
    Expect $failed 'real source errors are blocked instead of declared repaired'

    $failed = $false
    try { Assert-GodotRunLog -LogPath $coldLog -ExitCode 0 } catch { $failed = $true }
    Expect $failed 'exit code zero cannot mask compilation failures'

    # A quiet exit with no positive completion marker is also not successful.
    WriteSource 'probe.gd' "extends Node`nfunc _ready(): get_tree().quit()`n"
    $failed = $false
    try { Prepare | Out-Null } catch { $failed = $true }
    Expect $failed 'absent startup success marker is blocked'

    $held = [IO.File]::Open((Join-Path $fixture '.godot/project-health/prepare.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    try {
        $failed = $false
        try { Prepare | Out-Null } catch { $failed = $_.ToString() -match 'Another project preparation' }
        Expect $failed 'concurrent import for the same checkout is rejected'
    } finally { $held.Dispose() }
    Write-Output "PROJECT_HEALTH_TEST checks=$checks failures=0"
} finally {
    # Only remove the disposable nested Git metadata; keep diagnostic evidence ignored.
    $gitPath = [IO.Path]::GetFullPath((Join-Path $fixture '.git'))
    if (-not $gitPath.StartsWith([IO.Path]::GetFullPath($fixtureRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Fixture cleanup escaped its dedicated workspace.'
    }
    if (Test-Path -LiteralPath $gitPath) { Remove-Item -LiteralPath $gitPath -Recurse -Force }
}
