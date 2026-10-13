param([Parameter(Mandatory)][string]$EnginePath)
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$testRoot = Join-Path $project '.godot/art-workflow/project-hook-tests'
$fixture = Join-Path $testRoot ("hooks with spaces-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path "$fixture/.githooks", "$fixture/tools/development", "$fixture/.godot" -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $project 'tools/development/check-main-hook.ps1') -Destination "$fixture/tools/development/check-main-hook.ps1"
foreach ($hook in @('post-merge', 'post-checkout', 'post-commit')) {
    Copy-Item -LiteralPath (Join-Path $project ".githooks/$hook") -Destination "$fixture/.githooks/$hook"
}
[IO.File]::WriteAllText("$fixture/.gitignore", ".godot/`n")
[IO.File]::WriteAllText("$fixture/check-project.ps1", @'
param([string]$EnginePath)
Add-Content -LiteralPath (Join-Path $PSScriptRoot '.godot/hook-calls.txt') -Value 'checked'
if (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.godot/fail-check')) { exit 1 }
exit 0
'@)
$checks = 0
function Expect([bool]$Condition, [string]$Message) {
    $script:checks++
    if (-not $Condition) { throw "PROJECT_HOOK_TEST: $Message" }
}
function Invoke-FixtureGit([string[]]$Arguments) {
    & git -C $fixture -c user.name=Codex -c user.email=codex@local.invalid @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Fixture Git failed: $Arguments" }
}
function CountCalls {
    $file = "$fixture/.godot/hook-calls.txt"
    if (-not (Test-Path -LiteralPath $file)) { return 0 }
    return @(Get-Content -LiteralPath $file).Count
}
try {
    Invoke-FixtureGit @('init', '-b', 'main', '--quiet')
    Invoke-FixtureGit @('add', '--', '.')
    Invoke-FixtureGit @('commit', '--quiet', '-m', 'fixture')
    Invoke-FixtureGit @('config', '--local', 'core.hooksPath', 'custom-hooks')
    & pwsh.exe -NoProfile -File (Join-Path $project 'install-project-hooks.ps1') -ProjectPath $fixture -EnginePath $EnginePath 2>$null
    Expect ($LASTEXITCODE -ne 0) 'custom hook configuration is preserved'
    Expect ((& git -C $fixture config --get core.hooksPath) -eq 'custom-hooks') 'existing path remains unchanged'
    Invoke-FixtureGit @('config', '--local', '--unset', 'core.hooksPath')
    & pwsh.exe -NoProfile -File (Join-Path $project 'install-project-hooks.ps1') -ProjectPath $fixture -EnginePath $EnginePath
    Expect ($LASTEXITCODE -eq 0) 'hook installer succeeds'
    Expect ((& git -C $fixture config --get core.hooksPath) -eq '.githooks') 'local hook dispatch is configured'

    [IO.File]::WriteAllText("$fixture/source.txt", 'main')
    Invoke-FixtureGit @('add', '--', 'source.txt')
    Invoke-FixtureGit @('commit', '--quiet', '-m', 'main change')
    Expect ((CountCalls) -eq 1) 'native post-commit dispatch runs on main, including a path with spaces'
    Invoke-FixtureGit @('switch', '-c', 'feature', '--quiet')
    [IO.File]::WriteAllText("$fixture/source.txt", 'feature')
    Invoke-FixtureGit @('add', '--', 'source.txt')
    Invoke-FixtureGit @('commit', '--quiet', '-m', 'feature change')
    Expect ((CountCalls) -eq 1) 'feature branches do not trigger main checks'
    Invoke-FixtureGit @('switch', 'main', '--quiet')
    Expect ((CountCalls) -eq 2) 'returning to main checks its own checkout'
    Invoke-FixtureGit @('merge', '--ff-only', 'feature', '--quiet')
    Expect ((CountCalls) -eq 3) 'native post-merge dispatch runs'

    Invoke-FixtureGit @('switch', '-c', 'squash-feature', '--quiet')
    [IO.File]::WriteAllText("$fixture/squashed.txt", 'squash')
    Invoke-FixtureGit @('add', '--', 'squashed.txt')
    Invoke-FixtureGit @('commit', '--quiet', '-m', 'squash feature')
    Invoke-FixtureGit @('switch', 'main', '--quiet')
    $before = CountCalls
    Invoke-FixtureGit @('merge', '--squash', 'squash-feature', '--quiet')
    Expect ((CountCalls) -gt $before) 'squash merge checks the staged working tree'
    $before = CountCalls
    Invoke-FixtureGit @('commit', '--quiet', '-m', 'squashed main')
    Expect ((CountCalls) -eq $before+1) 'squash commit is checked again at its committed HEAD'

    # Post hooks report failure but Git's commit is already complete.
    [IO.File]::WriteAllText("$fixture/.godot/fail-check", 'fail')
    [IO.File]::WriteAllText("$fixture/source.txt", 'failed validation')
    Invoke-FixtureGit @('add', '--', 'source.txt')
    $output = & git -C $fixture -c user.name=Codex -c user.email=codex@local.invalid commit --quiet -m 'failed validation' 2>&1
    Expect ($LASTEXITCODE -eq 0) 'post-commit failure cannot be mistaken for an aborted commit'
    Expect (($output -join "`n") -match 'main 工程预检失败') 'post hook failure is explicitly reported'
    Remove-Item -LiteralPath "$fixture/.godot/fail-check"

    & pwsh.exe -NoProfile -File (Join-Path $project 'install-project-hooks.ps1') -ProjectPath $fixture -Remove
    Expect ($LASTEXITCODE -eq 0) 'uninstall succeeds'
    $before = CountCalls
    [IO.File]::WriteAllText("$fixture/source.txt", 'uninstalled')
    Invoke-FixtureGit @('add', '--', 'source.txt')
    Invoke-FixtureGit @('commit', '--quiet', '-m', 'after uninstall')
    Expect ((CountCalls) -eq $before) 'uninstall restores Git behavior'
    Write-Output "PROJECT_HOOK_TEST checks=$checks failures=0"
} finally {
    $gitPath = [IO.Path]::GetFullPath((Join-Path $fixture '.git'))
    if (-not $gitPath.StartsWith([IO.Path]::GetFullPath($testRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup path.' }
    if (Test-Path -LiteralPath $gitPath) { Remove-Item -LiteralPath $gitPath -Recurse -Force }
}
