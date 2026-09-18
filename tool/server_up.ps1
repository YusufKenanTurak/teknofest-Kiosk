# IIS kutusunda /teknofest'i ayağa kaldırır. Flutter yok.
# Tek satir (Administrator). Sirayi karistirmayin; baska komut yapistirmayin.
#
#   cd C:\Users\yturak\Desktop\teknofest-Kiosk; git pull --ff-only origin main; .\tool\server_up.ps1 -SkipGitPull

param(
    [switch]$SkipGitPull,
    [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")
. (Join-Path $PSScriptRoot "iis_site.ps1")

Assert-TeknofestAdministrator

$layout = Get-TeknofestDeployLayout
Set-Location $layout.ServerRoot

if (-not $SkipGitPull) {
    Write-Host "git pull --ff-only origin main" -ForegroundColor Cyan
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        throw "git pull --ff-only basarisiz."
    }
}

$full = Assert-TeknofestIisPhysicalPath $layout.IisPhysicalPath
if (-not (Test-Path (Join-Path $full "web.config"))) {
    throw "publish\web.config yok: $full"
}

Import-Module WebAdministration
$site = Resolve-TeknofestIisSite
$pool = [string]$site.applicationPool
Grant-TeknofestIisReadAccess -Path $full -AppPoolName $pool

& (Join-Path $PSScriptRoot "iis_register_application.ps1") -SkipHealthCheck

if (-not $SkipHealthCheck) {
    & (Join-Path $PSScriptRoot "health_check.ps1") -LocalOnly
}

Write-Host "server_up tamam." -ForegroundColor Green
