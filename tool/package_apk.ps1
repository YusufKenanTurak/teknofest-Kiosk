# APK artifact'ini dist\ altina kopyalar. PWA zip'ine girmez.
#
#   .\tool\package_apk.ps1
#   -> dist\teknofest-yatay-latest.apk

param(
    [string]$FromApk,
    [string]$SourceRoot
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")

$layout = Get-TeknofestDeployLayout -SourceRoot $SourceRoot
$source = $FromApk
if ([string]::IsNullOrWhiteSpace($source)) {
    $source = $layout.ApkPath
}
$source = Assert-TeknofestApkFile $source

New-Item -ItemType Directory -Path $layout.DistDir -Force | Out-Null
Copy-Item $source $layout.IncomingApk -Force
Write-Host "APK paketi: $($layout.IncomingApk)" -ForegroundColor Green
