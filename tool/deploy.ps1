# Sunucuda Flutter YOK. Bu PC'de uretilmis publish/ artifact'ini
# C:\Users\yturak\Desktop\teknofest-Kiosk\publish altina koyar / dogrular.
#
#   cd C:\Users\yturak\Desktop\teknofest-Kiosk
#   .\tool\deploy.ps1 -SkipPwaBuild
#   .\tool\deploy.ps1 -SkipPwaBuild -FromZip ".\dist\teknofest-iis-latest.zip"

param(
    [string]$IisPhysicalPath,
    [string]$PublishDir,
    [string]$SourceRoot,
    [string]$FromZip,
    [string]$HealthBaseUrl = "https://testapp.limak.com.tr/teknofest",
    [switch]$SkipPwaBuild,
    [switch]$SkipBuild,
    [switch]$GitPull,
    [switch]$SkipHealthCheck
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

Sunucu (C:\Users\yturak\Desktop\teknofest-Kiosk):
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
        throw "Zip yok: $zip"
    }
    $drop = $layout.DropDir
    if (Test-Path $drop) {
        Remove-Item $drop -Recurse -Force
    }
    New-Item -ItemType Directory -Path $drop | Out-Null
    Write-Host "Zip aciliyor: $zip -> $drop" -ForegroundColor Cyan
    Expand-Archive -Path $zip -DestinationPath $drop -Force
    $PublishDir = $drop
}

if ([string]::IsNullOrWhiteSpace($PublishDir)) {
    if (Test-Path (Join-Path $layout.PublishDir "index.html")) {
        $PublishDir = $layout.PublishDir
    }
    elseif (Test-Path (Join-Path $SourceRoot "index.html")) {
        throw "PWA dosyalari repo kokunde. IIS yalnizca publish\ servis eder; zip'i drop'a acin veya publish\ icine koyun."
    }
    else {
        throw "publish\ bulunamadi: $($layout.PublishDir). Zip icin: .\tool\deploy.ps1 -SkipPwaBuild -FromZip .\dist\teknofest-iis-latest.zip"
    }
}

Write-Host "SkipPwaBuild: Flutter yok. root=$SourceRoot" -ForegroundColor Cyan
Write-Host "  artifact: $PublishDir" -ForegroundColor Cyan
Write-Host "  IIS:      $IisPhysicalPath" -ForegroundColor Cyan

& (Join-Path $PSScriptRoot "copy_publish.ps1") -PublishDir $PublishDir -IisPhysicalPath $IisPhysicalPath

if (-not $SkipHealthCheck) {
    & (Join-Path $PSScriptRoot "health_check.ps1") -BaseUrl $HealthBaseUrl
}

Write-Host "Deploy tamam." -ForegroundColor Green
