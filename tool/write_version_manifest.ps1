# Istemcilerin guncelleme kontrolu icin okudugu version.json dosyasini yazar.
# Android: <base>/app/version.json  (croms_omega_auth / VardiyaTakip sozlesmesi)
#
#   .\tool\write_version_manifest.ps1
#   .\tool\write_version_manifest.ps1 -ApkUrl "downloads/teknofest-yatay-latest.apk"

param(
    [string]$OutputDir,
    [string]$Version,
    [int]$Build = -1,
    [string]$ApkUrl = "downloads/teknofest-yatay-latest.apk",
    [string]$MinSupportedVersion,
    [string]$Notes
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "app_version.ps1")

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $root "publish\app"
}

$pubspecVersion = Get-AppVersion -MobileRoot $root
if ([string]::IsNullOrWhiteSpace($Version)) { $Version = $pubspecVersion.Name }
if ($Build -lt 0) { $Build = $pubspecVersion.Build }

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$manifestPath = Join-Path $OutputDir "version.json"

    $manifest = [ordered]@{
        version      = $Version
        versionCode  = $Build
        build        = $Build
        released_at  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        force_logout = $false
    }

if (-not [string]::IsNullOrWhiteSpace($MinSupportedVersion)) {
    $manifest.min_supported_version = $MinSupportedVersion
}
if (-not [string]::IsNullOrWhiteSpace($Notes)) {
    $manifest.notes = $Notes
}
if (-not [string]::IsNullOrWhiteSpace($ApkUrl)) {
        $manifest.android = [ordered]@{
            version     = $Version
            versionCode = $Build
            build       = $Build
            apk_url     = $ApkUrl
        }
}

$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

$writtenBytes = [System.IO.File]::ReadAllBytes($manifestPath)
if ($writtenBytes.Length -ge 3 -and $writtenBytes[0] -eq 0xEF -and $writtenBytes[1] -eq 0xBB -and $writtenBytes[2] -eq 0xBF) {
    throw "version.json BOM ile yazildi; istemci bunu ayristiramaz: $manifestPath"
}
$null = [System.Text.Encoding]::UTF8.GetString($writtenBytes) | ConvertFrom-Json

Write-Host "version.json yazildi: $manifestPath (surum $Version+$Build)" -ForegroundColor Green
if ($manifest.android) {
    Write-Host "  android.apk_url = $($manifest.android.apk_url)" -ForegroundColor DarkGreen
}
