# Derlenmis APK'yi PWA'dan ayri apk\ artifact'ine koyar ve version.json gunceller.
#
#   .\tool\publish_apk.ps1
#   .\tool\publish_apk.ps1 -Notes "Stand release"

param(
    [string]$ApkPath,
    [string]$Notes
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "app_version.ps1")
. (Join-Path $PSScriptRoot "server_paths.ps1")

$layout = Get-TeknofestDeployLayout -SourceRoot $root

if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $ApkPath = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
}
if (-not (Test-Path $ApkPath)) {
    throw "APK bulunamadi: $ApkPath. Once .\tool\build_apk.ps1 calistirin."
}

New-Item -ItemType Directory -Path $layout.ApkDir -Force | Out-Null
Copy-Item $ApkPath $layout.ApkPath -Force
Write-Host "APK artifact: $($layout.ApkPath)" -ForegroundColor Green

New-Item -ItemType Directory -Path $layout.DistDir -Force | Out-Null
Copy-Item $layout.ApkPath $layout.IncomingApk -Force

$writeArgs = @{
    OutputDir = (Join-Path $layout.PublishDir "app")
    ApkUrl    = "downloads/$($layout.ApkFileName)"
}
if (-not [string]::IsNullOrWhiteSpace($Notes)) {
    $writeArgs.Notes = $Notes
}
& (Join-Path $PSScriptRoot "write_version_manifest.ps1") @writeArgs

& (Join-Path $PSScriptRoot "copy_apk.ps1") -FromApk $layout.ApkPath -SourceRoot $root
