# PWA / version.json / APK dogrular.
# IIS sunucusu public hostname'e (hairpin) cikamayabilir; once yerel binding denenir.
#
#   .\tool\health_check.ps1 -LocalOnly
#   .\tool\health_check.ps1 -BaseUrl "https://testapp.limak.com.tr/teknofest"

param(
    [string]$BaseUrl,
    [string]$SiteName,
    [string]$HostHeader = "testapp.limak.com.tr",
    [switch]$LocalOnly,
    [switch]$SkipApk
)

$ErrorActionPreference = "Continue"

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

function Invoke-CurlHead {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [string]$HostHeader,
        [switch]$Insecure
    )

    $args = @(
        "-sS", "-I", "--max-redirs", "0",
        "--connect-timeout", "5", "--max-time", "20"
    )
    if ($Insecure) {
        $args += "-k"
    }
    if (-not [string]::IsNullOrWhiteSpace($HostHeader)) {
        $args += @("-H", "Host: $HostHeader")
    }
    $args += $Url
    $output = & curl.exe @args 2>&1
    $text = ($output | ForEach-Object { "$_" }) -join "`n"
    return [pscustomobject]@{
        Url      = $Url
        ExitCode = $LASTEXITCODE
        Text     = $text
        Status   = Get-Status $text
    }
}

function Test-ReachableHealthBase {
    param($Probe)

    $head = Invoke-CurlHead -Url $Probe.Url -HostHeader $Probe.HostHeader -Insecure:$Probe.Insecure
    if ($head.ExitCode -ne 0 -or $head.Status -eq 0) {
        return $null
    }
    return $head
}

$probes = New-Object System.Collections.Generic.List[object]

if (-not $LocalOnly -and -not [string]::IsNullOrWhiteSpace($BaseUrl)) {
    $probes.Add([pscustomobject]@{
            Url        = $BaseUrl.TrimEnd("/")
            HostHeader = $null
            Insecure   = $false
            Label      = "public"
        }) | Out-Null
}

$localTried = $false
try {
    . (Join-Path $PSScriptRoot "iis_site.ps1")
    Import-Module WebAdministration -ErrorAction Stop
    $site = Resolve-TeknofestIisSite -SiteName $SiteName
    foreach ($target in @(Get-TeknofestLocalHealthTargets -Site $site)) {
        $probes.Add([pscustomobject]@{
                Url        = $target.Url
                HostHeader = $target.HostHeader
                Insecure   = [bool]$target.Insecure
                Label      = "local $($target.Url) Host:$($target.HostHeader)"
            }) | Out-Null
    }
    $localTried = $true
}
catch {
    if ($LocalOnly) {
        throw "Yerel IIS health icin site cozulemedi: $($_.Exception.Message)"
    }
}

if ($probes.Count -eq 0) {
    $probes.Add([pscustomobject]@{
            Url        = "http://127.0.0.1/teknofest"
            HostHeader = $HostHeader
            Insecure   = $false
            Label      = "local http 80"
        }) | Out-Null
    $probes.Add([pscustomobject]@{
            Url        = "https://127.0.0.1/teknofest"
            HostHeader = $HostHeader
            Insecure   = $true
            Label      = "local https 443"
        }) | Out-Null
}

$chosen = $null
$failures = New-Object System.Collections.Generic.List[string]
foreach ($probe in $probes) {
    Write-Host "Denenecek: $($probe.Label)  $($probe.Url)" -ForegroundColor DarkGray
    $hit = Test-ReachableHealthBase $probe
    if ($null -eq $hit) {
        $failures.Add("$($probe.Label): baglanilamadi") | Out-Null
        continue
    }
    $chosen = [pscustomobject]@{
        Probe  = $probe
        Head   = $hit
        BaseUrl = $probe.Url.TrimEnd("/")
    }
    if ($hit.Status -eq 200) {
        break
    }
}

if ($null -eq $chosen) {
    $hint = "IIS application kayitli mi? Bu sunucu public hostname'e (testapp.limak.com.tr) cikamayabilir; yerel health kullanin."
    throw "Health baglantisi yok.`n$($failures -join "`n")`n$hint"
}

$base = $chosen.BaseUrl
$hostHdr = $chosen.Probe.HostHeader
$insecure = [bool]$chosen.Probe.Insecure
$pwaStatus = $chosen.Head.Status
if ($pwaStatus -ne 200) {
    throw "PWA HTTP $pwaStatus  $base`n$($chosen.Head.Text)"
}

$versionUrl = "$base/app/version.json"
$versionHead = Invoke-CurlHead -Url $versionUrl -HostHeader $hostHdr -Insecure:$insecure
if ($versionHead.Status -ne 200) {
    throw "version.json HTTP $($versionHead.Status)`n$($versionHead.Text)"
}
$versionType = Get-Header $versionHead.Text "Content-Type"
if ($versionType -notmatch "json") {
    throw "version.json Content-Type JSON degil: $versionType"
}

$tmp = Join-Path $env:TEMP "teknofest-version-check.json"
$getArgs = @("-sS", "--connect-timeout", "5", "--max-time", "20", "-o", $tmp)
if ($insecure) { $getArgs += "-k" }
if (-not [string]::IsNullOrWhiteSpace($hostHdr)) { $getArgs += @("-H", "Host: $hostHdr") }
$getArgs += $versionUrl
$ErrorActionPreference = "Continue"
& curl.exe @getArgs | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "version.json indirilemedi (curl $LASTEXITCODE)"
}
$raw = [System.IO.File]::ReadAllText($tmp)
if ($raw -match "<html" -or $raw -match "<!DOCTYPE") {
    throw "version.json HTML dondu; SPA fallback yanlis calisiyor."
}
$parsed = $raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$parsed.version)) {
    throw "version.json icinde version yok."
}

$apkUrl = "$base/app/downloads/teknofest-yatay-latest.apk"
$apkHead = Invoke-CurlHead -Url $apkUrl -HostHeader $hostHdr -Insecure:$insecure
$apkStatus = $apkHead.Status
$apkType = Get-Header $apkHead.Text "Content-Type"

Write-Host "Health OK ($($chosen.Probe.Label))" -ForegroundColor Green
Write-Host "  PWA          $base  $pwaStatus"
Write-Host "  version.json $versionUrl  $($versionHead.Status)  $versionType  $($parsed.version)"

if ($apkStatus -eq 404 -or $SkipApk) {
    Write-Host "  APK          henuz yok (404). copy_apk.ps1 ile ayri kopyalanir." -ForegroundColor Yellow
    if ($chosen.Probe.Label -like "local*") {
        Write-Host "  Not: testapp.limak.com.tr bu makineden timeout olabilir (nginx/hairpin). Yerel IIS OK." -ForegroundColor DarkYellow
    }
    return
}
if ($apkStatus -ne 200) {
    throw "APK HTTP $apkStatus`n$($apkHead.Text)"
}
if ($apkType -match "html") {
    throw "APK HTML dondu; SPA fallback APK'yi yakaladi."
}
Write-Host "  APK          $apkUrl  $apkStatus  $apkType"
if ($chosen.Probe.Label -like "local*") {
    Write-Host "  Not: public URL bu sunucudan acilmayabilir; edge/nginx /teknofest'i IIS'e iletmeli." -ForegroundColor DarkYellow
}
