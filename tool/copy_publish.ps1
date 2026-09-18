# Hazir publish/ artifact'ini IIS physical path'e kopyalar.
# Flutter cagirmaz. Ayni klasorse kopya atlar. Production APK korunur.
#
#   .\tool\copy_publish.ps1 -PublishDir ".\publish" -IisPhysicalPath "C:\Users\yturak\Desktop\teknofest-Kiosk\publish"

param(
    [Parameter(Mandatory = $true)]
    [string]$PublishDir,
    [Parameter(Mandatory = $true)]
    [string]$IisPhysicalPath
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")

function Assert-PublishDir([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    foreach ($required in @("index.html", "web.config", "app\version.json")) {
        if (-not (Test-Path (Join-Path $full $required))) {
            throw "PublishDir icinde $required yok: $full"
        }
    }
    $raw = Get-Content (Join-Path $full "app\version.json") -Raw
    if ($raw -match "<html" -or $raw -match "<!DOCTYPE") {
        throw "version.json HTML gorunuyor; yanlis artifact."
    }
    $null = $raw | ConvertFrom-Json
    return $full
}

$publish = Assert-PublishDir $PublishDir
$iisPath = Assert-TeknofestIisPhysicalPath $IisPhysicalPath

$samePath = [string]::Equals($publish.TrimEnd("\"), $iisPath.TrimEnd("\"), [System.StringComparison]::OrdinalIgnoreCase)
if ($samePath) {
    Write-Host "IIS physical path zaten publish (in-place): $iisPath" -ForegroundColor Cyan
    Grant-TeknofestIisReadAccess -Path $iisPath
    if (-not (Test-Path (Join-Path $iisPath "app\downloads\teknofest-yatay-latest.apk"))) {
        Write-Host "APK bu klasorde yok; indirme URL'si 404 olabilir." -ForegroundColor Yellow
    }
    Write-Host "Kopyalama atlandi." -ForegroundColor Green
    return
}

if (-not (Test-Path $iisPath)) {
    New-Item -ItemType Directory -Path $iisPath | Out-Null
}

$preservedApk = Join-Path $env:TEMP "teknofest-yatay-latest.apk.bak"
$liveApk = Join-Path $iisPath "app\downloads\teknofest-yatay-latest.apk"
$newApk = Join-Path $publish "app\downloads\teknofest-yatay-latest.apk"
$hadLiveApk = Test-Path $liveApk
if ($hadLiveApk -and -not (Test-Path $newApk)) {
    Copy-Item $liveApk $preservedApk -Force
}

$srcDownloads = Join-Path $publish "app\downloads"
$dstDownloads = Join-Path $iisPath "app\downloads"

Write-Host "IIS klasore kopyalaniyor: $publish -> $iisPath" -ForegroundColor Cyan
robocopy $publish $iisPath /MIR /XD $srcDownloads $dstDownloads /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
$code = $LASTEXITCODE
if ($code -ge 8) {
    throw "robocopy basarisiz (exit $code)"
}

New-Item -ItemType Directory -Path $dstDownloads -Force | Out-Null
if (Test-Path $newApk) {
    Copy-Item $newApk (Join-Path $dstDownloads "teknofest-yatay-latest.apk") -Force
    Write-Host "APK guncellendi." -ForegroundColor Green
}
elseif ($hadLiveApk -and (Test-Path $preservedApk)) {
    Copy-Item $preservedApk (Join-Path $dstDownloads "teknofest-yatay-latest.apk") -Force
    Write-Host "Yeni APK yok; onceki production APK korundu." -ForegroundColor Yellow
}
else {
    Write-Host "APK bu pakette yok; indirme URL'si 404 olabilir." -ForegroundColor Yellow
}

Grant-TeknofestIisReadAccess -Path $iisPath
Write-Host "Kopyalama tamam." -ForegroundColor Green
