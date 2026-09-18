# Derlenmis APK'yi publish/app/downloads/teknofest-yatay-latest.apk olarak kopyalar
# ve version.json yazar. Referans: VardiyaTakip tool/publish_apk.ps1
#
#   .\tool\publish_apk.ps1

param(
    [string]$ApkPath,
    [string]$Notes
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "app_version.ps1")

if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $ApkPath = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
}
if (-not (Test-Path $ApkPath)) {
    throw "APK bulunamadi: $ApkPath. Once flutter build apk --release calistirin."
}

$destDir = Join-Path $root "publish\app\downloads"
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

$dest = Join-Path $destDir "teknofest-yatay-latest.apk"
Copy-Item $ApkPath $dest -Force
Write-Host "APK kopyalandi: $dest" -ForegroundColor Green

$writeArgs = @{
    OutputDir = (Join-Path $root "publish\app")
    ApkUrl    = "downloads/teknofest-yatay-latest.apk"
}
if (-not [string]::IsNullOrWhiteSpace($Notes)) {
    $writeArgs.Notes = $Notes
}
& (Join-Path $PSScriptRoot "write_version_manifest.ps1") @writeArgs
