# IIS /teknofest 500/404 teshisi. Flutter yok.
#
#   .\tool\iis_diagnose.ps1

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "server_paths.ps1")
. (Join-Path $PSScriptRoot "iis_site.ps1")

Assert-TeknofestAdministrator
Import-Module WebAdministration

$layout = Get-TeknofestDeployLayout
Write-TeknofestIisInventory

$site = Resolve-TeknofestIisSite
$app = Get-WebApplication -Site $site.Name -Name $layout.ApplicationName -ErrorAction SilentlyContinue
if ($null -eq $app) {
    Write-Host "Application /teknofest YOK. .\tool\iis_register_application.ps1" -ForegroundColor Red
}
else {
    Write-Host "Application physical path: $($app.PhysicalPath)" -ForegroundColor Cyan
}

$publish = $layout.IisPhysicalPath
Write-Host "Beklenen publish: $publish"
foreach ($rel in @("web.config", "index.html", "app\version.json")) {
    $p = Join-Path $publish $rel
    if (Test-Path $p) {
        Write-Host "  OK $rel" -ForegroundColor Green
    }
    else {
        Write-Host "  EKSIK $rel" -ForegroundColor Red
    }
}

$rewrite = Get-WebGlobalModule -Name "RewriteModule" -ErrorAction SilentlyContinue
if ($null -eq $rewrite) {
    Write-Host "URL Rewrite modulu yok. web.config <rewrite> 500.19 verir." -ForegroundColor Red
}
else {
    Write-Host "URL Rewrite: $($rewrite.Image)" -ForegroundColor Green
}

Write-Host "ACL (IIS_IUSRS / AppPool Desktop'a giremezse 500.19 0x80070005):" -ForegroundColor Cyan
foreach ($aclPath in @(
        "C:\Users\yturak",
        "C:\Users\yturak\Desktop",
        (Split-Path $publish -Parent),
        $publish,
        (Join-Path $publish "web.config")
    )) {
    if (Test-Path $aclPath) {
        Write-Host "--- icacls $aclPath"
        & icacls.exe $aclPath
    }
}

$url = "http://127.0.0.1/teknofest/"
$hostHeader = "testapp.limak.com.tr"
$out = Join-Path $env:TEMP "teknofest-iis-diagnose.html"
$hdr = Join-Path $env:TEMP "teknofest-iis-diagnose.hdr"
& curl.exe -sS -D $hdr -o $out --max-redirs 0 --connect-timeout 5 --max-time 20 -H "Host: $hostHeader" $url
Write-Host "GET $url Host:$hostHeader"
if (Test-Path $hdr) {
    Write-Host ([System.IO.File]::ReadAllText($hdr))
}
if (Test-Path $out) {
    $html = [System.IO.File]::ReadAllText($out)
    if ($html -match '<title>([^<]+)</title>') {
        Write-Host "HTML title: $($Matches[1])" -ForegroundColor Yellow
    }
    if ($html -match '0x80070005|insufficient permissions') {
        Write-Host "500.19 ACL: .\tool\server_up.ps1  (parent traverse + publish RX)" -ForegroundColor Red
    }
    Write-Host "Govde kaydi: $out"
}

Write-Host "Site-level web.config'e Teknofest kurali YAPISTIRMAYIN. Isolation: publish\web.config <clear />"
