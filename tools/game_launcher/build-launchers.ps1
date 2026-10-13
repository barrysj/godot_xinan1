# Internal build entry. The checked-in native EXEs are the daily user entry points.
#requires -Version 7.0
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$compiler = @("$env:WINDIR/Microsoft.NET/Framework64/v4.0.30319/csc.exe", "$env:WINDIR/Microsoft.NET/Framework/v4.0.30319/csc.exe") |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $compiler) { throw '找不到 Windows C# 编译器。' }
$sources = @((Join-Path $PSScriptRoot 'GameLauncher.cs'), (Join-Path $PSScriptRoot 'launcher.manifest'), $PSCommandPath)
$signature = ((Get-FileHash -LiteralPath $sources -Algorithm SHA256).Hash -join ':')
$buildInfo = Join-Path $projectRoot '.godot/game-launcher/BuildInfo.cs'
[IO.Directory]::CreateDirectory((Split-Path $buildInfo)) | Out-Null
[IO.File]::WriteAllText($buildInfo, "namespace CyberPopCampus.GameLauncher { internal static class BuildInfo { internal const string Signature = `"$signature`"; } }")
$outputs = @{}
foreach ($mode in @('Debug', 'Release')) {
    $output = Join-Path $projectRoot "Campus${mode}Launcher.exe"
    & $compiler /nologo /target:winexe /optimize+ /define:$($mode.ToUpperInvariant()) /win32manifest:$($sources[1]) /out:$output /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.Extensions.dll $sources[0] $buildInfo
    if ($LASTEXITCODE -ne 0) { throw "启动器编译失败；请关闭 $mode 启动器再重试。" }
    $outputs[$mode] = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
    Write-Host "已生成 $output"
}
@{source_signature=$signature; outputs=$outputs} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'build-info.json') -Encoding utf8
