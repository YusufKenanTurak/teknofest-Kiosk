# Mevcut testapp.limak.com.tr sitesine /teknofest application ekler.
# Site-level rewrite kurallarina (EnduransStaff, LTStaff, ...) DOKUNMAZ.
# Flutter gerektirmez; physical path onceden kopyalanmis publish/ olmalidir.
#
#   Import-Module WebAdministration
#   .\tool\iis_register_application.ps1 -SiteName "testapp.limak.com.tr" -PhysicalPath "C:\inetpub\wwwroot\teknofest"

param(
    [Parameter(Mandatory = $true)]
    [string]$SiteName,
    [Parameter(Mandatory = $true)]
    [string]$PhysicalPath,
    [string]$ApplicationName = "teknofest"
)

$ErrorActionPreference = "Stop"
Import-Module WebAdministration

$full = [System.IO.Path]::GetFullPath($PhysicalPath)
if ((Split-Path $full -Leaf) -ne "teknofest") {
    throw "PhysicalPath son klasor adi teknofest olmali: $full"
}
if (-not (Test-Path (Join-Path $full "web.config"))) {
    throw "PhysicalPath icinde web.config yok: $full"
}

$site = Get-Website -Name $SiteName -ErrorAction Stop
Write-Host "Site: $($site.Name)  state=$($site.State)" -ForegroundColor Cyan

$appPath = "/$ApplicationName"
$existing = Get-WebApplication -Site $SiteName -Name $ApplicationName -ErrorAction SilentlyContinue
if ($null -ne $existing) {
    Write-Host "Application zaten var: $appPath -> $($existing.PhysicalPath)" -ForegroundColor Yellow
    return
}

New-WebApplication -Site $SiteName -Name $ApplicationName -PhysicalPath $full -ApplicationPool $site.applicationPool
Write-Host "Application olusturuldu: $appPath -> $full" -ForegroundColor Green
Write-Host "Site-level rewrite kurallarina dokunulmadi." -ForegroundColor Green
