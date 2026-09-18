# Sunucuda Flutter YOK. PWA ve APK ayri artifact'tir.
#
#   cd C:\Users\yturak\Desktop\teknofest-Kiosk
#   .\tool\deploy.ps1 -SkipPwaBuild
#   .\tool\deploy.ps1 -SkipPwaBuild -RegisterIis

param(
    [string]$IisPhysicalPath,
    [string]$PublishDir,
    [string]$SourceRoot,
    [string]$FromZip,
    [string]$FromApk,
    [string]$SiteName,
    [switch]$SkipPwaBuild,
    [switch]$SkipBuild,
    [switch]$SkipApk,
    [switch]$GitPull,
    [switch]$RegisterIis,
    [switch]$HealthCheck
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")

$skipCompile = $SkipPwaBuild -or $SkipBuild
if (-not $skipCompile) {
    throw @"
Sunucuda Flutter derlemesi yok.

Bu PC:
  .\tool\build_web.ps1
  .\tool\publish_web.ps1
  .\tool\package_release.ps1
  .\tool\build_apk.ps1
  .\tool\publish_apk.ps1 -Notes "Stand release"

Sunucu:
  .\tool\deploy.ps1 -SkipPwaBuild
"@
}

$layout = Get-TeknofestDeployLayout -SourceRoot $SourceRoot
$SourceRoot = $layout.ServerRoot

if ($GitPull) {
    if (-not (Test-Path (Join-Path $SourceRoot ".git"))) {
        throw "GitPull istendi ama SourceRoot bir git repo degil: $SourceRoot"
    }
    Write-Host "git fetch / ff-only pull (artifact senkronu; derleme yok)" -ForegroundColor Cyan
    Set-Location $SourceRoot
    git fetch origin
    git checkout main
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        throw "git pull --ff-only basarisiz. Sunucuda local commit olmamali."
    }
}

if ([string]::IsNullOrWhiteSpace($IisPhysicalPath)) {
    $IisPhysicalPath = $layout.IisPhysicalPath
}

if (-not [string]::IsNullOrWhiteSpace($FromZip)) {
    $zip = [System.IO.Path]::GetFullPath($FromZip)
    if (-not (Test-Path $zip)) {
        throw "PWA zip yok: $zip"
    }
    $drop = $layout.DropDir
    if (Test-Path $drop) {
        Remove-Item $drop -Recurse -Force
    }
    New-Item -ItemType Directory -Path $drop | Out-Null
    Write-Host "PWA zip aciliyor: $zip -> $drop" -ForegroundColor Cyan
    Expand-Archive -Path $zip -DestinationPath $drop -Force
    $leaked = Get-ChildItem $drop -Filter *.apk -Recurse -ErrorAction SilentlyContinue
    if ($leaked) {
        throw "PWA zip APK iceriyor; paketler karismis: $($leaked.FullName -join ', ')"
    }
    $PublishDir = $drop
}

if ([string]::IsNullOrWhiteSpace($PublishDir)) {
    if (Test-Path (Join-Path $layout.PublishDir "index.html")) {
        $PublishDir = $layout.PublishDir
    }
    elseif (Test-Path (Join-Path $SourceRoot "index.html")) {
        throw "PWA dosyalari repo kokunde. IIS yalnizca publish\ servis eder."
    }
    else {
        throw "publish\ bulunamadi: $($layout.PublishDir)"
    }
}

Write-Host "SkipPwaBuild: Flutter yok. root=$SourceRoot" -ForegroundColor Cyan
Write-Host "  PWA artifact: $PublishDir" -ForegroundColor Cyan
Write-Host "  IIS:          $IisPhysicalPath" -ForegroundColor Cyan

& (Join-Path $PSScriptRoot "copy_publish.ps1") -PublishDir $PublishDir -IisPhysicalPath $IisPhysicalPath

if ($SkipApk) {
    Write-Host "SkipApk: APK bu deploy'da yok." -ForegroundColor Yellow
}
else {
    $apkArgs = @{ SourceRoot = $SourceRoot }
    if (-not [string]::IsNullOrWhiteSpace($FromApk)) {
        $apkArgs.FromApk = $FromApk
    }
    & (Join-Path $PSScriptRoot "copy_apk.ps1") @apkArgs
}

if ($RegisterIis) {
    $regArgs = @{}
    if (-not [string]::IsNullOrWhiteSpace($SiteName)) {
        $regArgs.SiteName = $SiteName
    }
    & (Join-Path $PSScriptRoot "iis_register_application.ps1") @regArgs
}
elseif ($HealthCheck) {
    & (Join-Path $PSScriptRoot "health_check.ps1") -LocalOnly
}

Write-Host "Deploy tamam." -ForegroundColor Green
