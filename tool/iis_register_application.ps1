# Mevcut IIS sitesine /teknofest application ekler.
# Site-level rewrite (EnduransStaff, LTStaff, ...) DOKUNULMAZ.
#
#   .\tool\iis_register_application.ps1
#   .\tool\iis_register_application.ps1 -SiteName "Default Web Site"

param(
    [string]$SiteName,
    [string]$PhysicalPath,
    [string]$ApplicationName = "teknofest",
    [switch]$SkipHealthCheck
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")
. (Join-Path $PSScriptRoot "iis_site.ps1")

Assert-TeknofestAdministrator
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

Write-TeknofestIisInventory
$site = Resolve-TeknofestIisSite -SiteName $SiteName
$resolvedName = [string]$site.Name
$pool = [string]$site.applicationPool
if ([string]::IsNullOrWhiteSpace($resolvedName)) {
    throw "IIS site adi bos. Placeholder (-SiteName '<mevcut site adi>') kullanmayin."
}
if ([string]::IsNullOrWhiteSpace($pool)) {
    throw "Site '$resolvedName' application pool'u bos."
}

Write-Host "Kayit: site='$resolvedName'  state=$($site.State)  pool=$pool" -ForegroundColor Cyan
Write-Host "  physical path: $full" -ForegroundColor Cyan

$existing = Get-WebApplication -Site $resolvedName -Name $ApplicationName -ErrorAction SilentlyContinue
if ($null -eq $existing) {
    New-WebApplication -Site $resolvedName -Name $ApplicationName -PhysicalPath $full -ApplicationPool $pool
    Write-Host "Application olusturuldu: /$ApplicationName -> $full" -ForegroundColor Green
}
else {
    $current = [System.IO.Path]::GetFullPath([string]$existing.PhysicalPath)
    if (-not [string]::Equals($current.TrimEnd("\"), $full.TrimEnd("\"), [System.StringComparison]::OrdinalIgnoreCase)) {
        Set-ItemProperty "IIS:\Sites\$resolvedName\$ApplicationName" -Name physicalPath -Value $full
        Write-Host "Physical path guncellendi: $current -> $full" -ForegroundColor Yellow
    }
    else {
        Write-Host "Application zaten kayitli: /$ApplicationName -> $full" -ForegroundColor Yellow
    }
}

Grant-TeknofestIisReadAccess -Path $full -AppPoolName $pool
Write-Host "Site-level rewrite kurallarina dokunulmadi." -ForegroundColor Green

if (-not $SkipHealthCheck) {
    try {
        & (Join-Path $PSScriptRoot "health_check.ps1") -LocalOnly -SiteName $resolvedName
    }
    catch {
        Write-Host "Application kayitli. Yerel health su an basarisiz: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Tekrar: .\tool\health_check.ps1 -LocalOnly" -ForegroundColor Yellow
    }
}
