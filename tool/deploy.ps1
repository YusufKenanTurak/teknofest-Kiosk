# Sunucuda Flutter YOK. Bu script yalnizca bu PC'de uretilmis publish/ artifact'ini
# IIS physical path'e kopyalar. Derleme yapmaz.
#
# Build PC:
#   .\tool\build_web.ps1
#   .\tool\publish_web.ps1
#   .\tool\package_release.ps1
#
# Sunucu veya UNC ile IIS path:
#   .\tool\deploy.ps1 -SkipPwaBuild -IisPhysicalPath "C:\inetpub\wwwroot\teknofest"
#   .\tool\deploy.ps1 -SkipPwaBuild -PublishDir "C:\inetpub\staging\teknofest-drop" -IisPhysicalPath "C:\inetpub\wwwroot\teknofest"

param(
    [Parameter(Mandatory = $true)]
    [string]$IisPhysicalPath,
    [string]$PublishDir,
    [string]$SourceRoot,
    [string]$HealthBaseUrl = "https://testapp.limak.com.tr/teknofest",
    [switch]$SkipPwaBuild,
    [switch]$SkipBuild,
    [switch]$GitPull,
    [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Stop"

$skipCompile = $SkipPwaBuild -or $SkipBuild
if (-not $skipCompile) {
    throw @"
Sunucuda Flutter derlemesi yok.

Once bu PC'de build alin, sonra artifact'i kopyalayin:

  .\tool\build_web.ps1
  .\tool\publish_web.ps1
  .\tool\package_release.ps1

Ardindan sunucuda:

  .\tool\deploy.ps1 -SkipPwaBuild -IisPhysicalPath `"C:\inetpub\wwwroot\teknofest`"
"@
}

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = Split-Path -Parent $PSScriptRoot
}
$SourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)

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

if ([string]::IsNullOrWhiteSpace($PublishDir)) {
    $fromRepo = Join-Path $SourceRoot "publish"
    if (Test-Path (Join-Path $fromRepo "index.html")) {
        $PublishDir = $fromRepo
    }
    elseif (Test-Path (Join-Path $SourceRoot "index.html")) {
        $PublishDir = $SourceRoot
    }
    else {
        throw "PublishDir bulunamadi. Zip'i acip -PublishDir verin veya bu PC'deki publish/ klasorunu kopyalayin."
    }
}

Write-Host "SkipPwaBuild: Flutter calistirilmiyor." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "copy_publish.ps1") -PublishDir $PublishDir -IisPhysicalPath $IisPhysicalPath

if (-not $SkipHealthCheck) {
    & (Join-Path $PSScriptRoot "health_check.ps1") -BaseUrl $HealthBaseUrl
}

Write-Host "Deploy tamam." -ForegroundColor Green
