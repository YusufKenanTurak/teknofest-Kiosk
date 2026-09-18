# Mevcut testapp.limak.com.tr sitesine /teknofest application ekler.
# Site-level rewrite kurallarina (EnduransStaff, LTStaff, ...) DOKUNMAZ.
# Flutter yok. Physical path: C:\Users\yturak\Desktop\teknofest-Kiosk\publish
#
#   Import-Module WebAdministration
#   .\tool\iis_register_application.ps1 -SiteName "testapp.limak.com.tr"

param(
    [Parameter(Mandatory = $true)]
    [string]$SiteName,
    [string]$PhysicalPath,
    [string]$ApplicationName = "teknofest"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")
Import-Module WebAdministration

$layout = Get-TeknofestDeployLayout
if ([string]::IsNullOrWhiteSpace($PhysicalPath)) {
    $PhysicalPath = $layout.IisPhysicalPath
}

$full = Assert-TeknofestIisPhysicalPath $PhysicalPath
if (-not (Test-Path (Join-Path $full "web.config"))) {
    throw "PhysicalPath icinde web.config yok: $full"
}
if (-not (Test-Path (Join-Path $full "index.html"))) {
    throw "PhysicalPath icinde index.html yok (Flutter kaynak agaci servis edilmez): $full"
}

$site = Get-Website -Name $SiteName -ErrorAction Stop
Write-Host "Site: $($site.Name)  state=$($site.State)  pool=$($site.applicationPool)" -ForegroundColor Cyan

$appPath = "/$ApplicationName"
$existing = Get-WebApplication -Site $SiteName -Name $ApplicationName -ErrorAction SilentlyContinue
if ($null -eq $existing) {
    New-WebApplication -Site $SiteName -Name $ApplicationName -PhysicalPath $full -ApplicationPool $site.applicationPool
    Write-Host "Application olusturuldu: $appPath -> $full" -ForegroundColor Green
}
else {
    $current = [System.IO.Path]::GetFullPath([string]$existing.PhysicalPath)
    if (-not [string]::Equals($current.TrimEnd("\"), $full.TrimEnd("\"), [System.StringComparison]::OrdinalIgnoreCase)) {
        Set-ItemProperty "IIS:\Sites\$SiteName\$ApplicationName" -Name physicalPath -Value $full
        Write-Host "Physical path guncellendi: $current -> $full" -ForegroundColor Yellow
    }
    else {
        Write-Host "Application zaten kayitli: $appPath -> $full" -ForegroundColor Yellow
    }
}

Grant-TeknofestIisReadAccess -Path $full -AppPoolName $site.applicationPool
Write-Host "Site-level rewrite kurallarina dokunulmadi." -ForegroundColor Green
