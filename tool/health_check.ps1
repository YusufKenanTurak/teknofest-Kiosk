# Production URL'lerini curl.exe ile dogrular.
#
#   .\tool\health_check.ps1
#   .\tool\health_check.ps1 -BaseUrl "https://testapp.limak.com.tr/teknofest"

param(
    [string]$BaseUrl = "https://testapp.limak.com.tr/teknofest"
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")

function Invoke-CurlHead([string]$Url) {
    $raw = & curl.exe -sS -I --max-redirs 0 $Url 2>&1 | Out-String
    return $raw
}

function Get-Status([string]$Headers) {
    if ($Headers -match 'HTTP/\S+\s+(\d+)') {
        return [int]$Matches[1]
    }
    return 0
}

function Get-Header([string]$Headers, [string]$Name) {
    foreach ($line in ($Headers -split "`r?`n")) {
        if ($line -match "^${Name}\s*:\s*(.+)$") {
            return $Matches[1].Trim()
        }
    }
    return ""
}

$pwaHeaders = Invoke-CurlHead $BaseUrl
$pwaStatus = Get-Status $pwaHeaders
if ($pwaStatus -ne 200) {
    throw "PWA HTTP $pwaStatus`n$pwaHeaders"
}

$versionUrl = "$BaseUrl/app/version.json"
$versionHeaders = Invoke-CurlHead $versionUrl
$versionStatus = Get-Status $versionHeaders
$versionType = Get-Header $versionHeaders "Content-Type"
if ($versionStatus -ne 200) {
    throw "version.json HTTP $versionStatus`n$versionHeaders"
}
if ($versionType -notmatch "json") {
    throw "version.json Content-Type JSON degil: $versionType"
}

$tmp = Join-Path $env:TEMP "teknofest-version-check.json"
& curl.exe -sS -o $tmp $versionUrl
if ($LASTEXITCODE -ne 0) {
    throw "version.json indirilemedi"
}
$raw = [System.IO.File]::ReadAllText($tmp)
if ($raw -match "<html" -or $raw -match "<!DOCTYPE") {
    throw "version.json HTML dondu; SPA fallback yanlis calisiyor."
}
$parsed = $raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$parsed.version)) {
    throw "version.json icinde version yok."
}

$apkUrl = "$BaseUrl/app/downloads/teknofest-yatay-latest.apk"
$apkHeaders = Invoke-CurlHead $apkUrl
$apkStatus = Get-Status $apkHeaders
$apkType = Get-Header $apkHeaders "Content-Type"
if ($apkStatus -eq 404) {
    Write-Host "APK henuz yok (404). PWA ve version.json OK." -ForegroundColor Yellow
    Write-Host "  PWA          $BaseUrl  $pwaStatus"
    Write-Host "  version.json $versionUrl  $versionStatus  $($parsed.version)"
    return
}
if ($apkStatus -ne 200) {
    throw "APK HTTP $apkStatus`n$apkHeaders"
}
if ($apkType -match "html") {
    throw "APK HTML dondu; SPA fallback APK'yi yakaladi."
}

Write-Host "Health OK" -ForegroundColor Green
Write-Host "  PWA          $BaseUrl  $pwaStatus"
Write-Host "  version.json $versionUrl  $versionStatus  $versionType  $($parsed.version)"
Write-Host "  APK          $apkUrl  $apkStatus  $apkType"
