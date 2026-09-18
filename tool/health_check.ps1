# PWA / version.json / APK dogrular.
# IIS /teknofest -> /teknofest/ 301'ini public hostname'e takip etmez; yerelde slash ile 200 arar.
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

function Get-IisErrorSnippet([string]$Html) {
    if ([string]::IsNullOrWhiteSpace($Html)) {
        return ""
    }
    $bits = @()
    if ($Html -match '<title>([^<]+)</title>') {
        $bits += $Matches[1].Trim()
    }
    if ($Html -match 'HTTP Error (\d+\.\d+)') {
        $bits += "HTTP Error $($Matches[1])"
    }
    if ($Html -match 'Config Error</(?:dt|h3)>\s*<dd>([^<]+)') {
        $bits += $Matches[1].Trim()
    }
    elseif ($Html -match 'Config Error[^<]*</[^>]+>\s*<[^>]+>([^<]+)') {
        $bits += $Matches[1].Trim()
    }
    if ($Html -match '(HRESULT|0x8[0-9a-fA-F]+)') {
        $bits += $Matches[0]
    }
    if ($Html -match 'duplicate collection entry[^<]*') {
        $bits += $Matches[0]
    }
    if ($bits.Count -eq 0) {
        $plain = [regex]::Replace($Html, '<[^>]+>', ' ')
        $plain = ($plain -replace '\s+', ' ').Trim()
        if ($plain.Length -gt 400) {
            $plain = $plain.Substring(0, 400)
        }
        return $plain
    }
    return ($bits -join ' | ')
}

function Invoke-CurlHead {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [string]$RequestHost,
        [bool]$SkipCertCheck
    )

    $headerFile = Join-Path $env:TEMP ("teknofest-h-" + [guid]::NewGuid().ToString("N") + ".txt")
    $bodyFile = Join-Path $env:TEMP ("teknofest-b-" + [guid]::NewGuid().ToString("N") + ".bin")
    $curlArgs = @(
        "-sS", "-D", $headerFile, "-o", $bodyFile,
        "--max-redirs", "0",
        "--connect-timeout", "5", "--max-time", "20"
    )
    if ($SkipCertCheck) {
        $curlArgs += "-k"
    }
    if (-not [string]::IsNullOrWhiteSpace($RequestHost)) {
        $curlArgs += @("-H", "Host: $RequestHost")
    }
    $curlArgs += $Url
    & curl.exe @curlArgs 2>&1 | Out-Null
    $exit = $LASTEXITCODE
    $text = ""
    $body = ""
    if (Test-Path $headerFile) {
        $text = [System.IO.File]::ReadAllText($headerFile)
        Remove-Item $headerFile -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $bodyFile) {
        try {
            $body = [System.IO.File]::ReadAllText($bodyFile)
        }
        catch {
            $body = ""
        }
        Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue
    }
    $status = Get-Status $text
    if ($status -ge 500 -and -not [string]::IsNullOrWhiteSpace($body)) {
        $snip = Get-IisErrorSnippet $body
        if ($snip) {
            $text = "$text`nIIS: $snip"
        }
    }
    return [pscustomobject]@{
        Url      = $Url
        ExitCode = $exit
        Text     = $text
        Body     = $body
        Status   = $status
    }
}

function ConvertTo-LocalFollowUrl {
    param(
        [string]$Location,
        [string]$OriginalUrl
    )
    if ([string]::IsNullOrWhiteSpace($Location)) {
        return $null
    }
    try {
        $orig = [Uri]$OriginalUrl
        if ($Location -match '^https?://') {
            $path = ([Uri]$Location).AbsolutePath
        }
        else {
            $path = $Location.Split('?')[0]
        }
        if ($path -notmatch '^/teknofest') {
            return $null
        }
        if (-not $path.EndsWith("/")) {
            $path = "$path/"
        }
        $portPart = ""
        if (-not (($orig.Scheme -eq "http" -and $orig.Port -eq 80) -or ($orig.Scheme -eq "https" -and $orig.Port -eq 443))) {
            $portPart = ":$($orig.Port)"
        }
        return "$($orig.Scheme)://127.0.0.1${portPart}$path"
    }
    catch {
        return $null
    }
}

function Invoke-LocalPwaHead {
    param($Probe)

    $url = $Probe.Url
    $hit = $null
    for ($i = 0; $i -lt 4; $i++) {
        Write-Host "Denenecek: $($Probe.Label)  $url" -ForegroundColor DarkGray
        $hit = Invoke-CurlHead -Url $url -RequestHost $Probe.RequestHost -SkipCertCheck ([bool]$Probe.SkipCert)
        if ($hit.ExitCode -ne 0 -or $hit.Status -eq 0) {
            return $hit
        }
        if ($hit.Status -eq 200) {
            $hit | Add-Member -NotePropertyName FollowedUrl -NotePropertyValue $url -Force
            return $hit
        }
        if ($hit.Status -eq 301 -or $hit.Status -eq 302) {
            $location = Get-Header $hit.Text "Location"
            $next = ConvertTo-LocalFollowUrl -Location $location -OriginalUrl $url
            if ([string]::IsNullOrWhiteSpace($next) -or $next -eq $url) {
                $hit | Add-Member -NotePropertyName FollowedUrl -NotePropertyValue $url -Force
                return $hit
            }
            Write-Host "  301 yerel: $location -> $next" -ForegroundColor DarkGray
            $url = $next
            continue
        }
        $hit | Add-Member -NotePropertyName FollowedUrl -NotePropertyValue $url -Force
        return $hit
    }
    $hit | Add-Member -NotePropertyName FollowedUrl -NotePropertyValue $url -Force
    return $hit
}

$probes = @()

if (-not $LocalOnly -and -not [string]::IsNullOrWhiteSpace($BaseUrl)) {
    $probes += [pscustomobject]@{
        Url         = $BaseUrl.TrimEnd("/") + "/"
        RequestHost = $null
        SkipCert    = $false
        Label       = "public"
    }
}

try {
    . (Join-Path $PSScriptRoot "iis_site.ps1")
    Import-Module WebAdministration -ErrorAction Stop
    $site = Resolve-TeknofestIisSite -SiteName $SiteName
    foreach ($target in @(Get-TeknofestLocalHealthTargets -Site $site -HostName $HostHeader)) {
        $probes += [pscustomobject]@{
            Url         = $target.Url
            RequestHost = $target.HostHeader
            SkipCert    = [bool]$target.Insecure
            Label       = "local $($target.Url) Host:$($target.HostHeader)"
        }
    }
}
catch {
    if ($LocalOnly) {
        Write-Host "Binding listesi alinamadi, 127.0.0.1 deneniyor: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if ($probes.Count -eq 0) {
    $probes += [pscustomobject]@{
        Url         = "http://127.0.0.1/teknofest/"
        RequestHost = $HostHeader
        SkipCert    = $false
        Label       = "local http 80"
    }
    $probes += [pscustomobject]@{
        Url         = "https://127.0.0.1/teknofest/"
        RequestHost = $HostHeader
        SkipCert    = $true
        Label       = "local https 443"
    }
}

$chosen = $null
$failures = @()
foreach ($probe in $probes) {
    $hit = Invoke-LocalPwaHead $probe
    if ($hit.ExitCode -ne 0 -or $hit.Status -eq 0) {
        $failures += "$($probe.Label): baglanilamadi (curl $($hit.ExitCode))"
        continue
    }
    $followed = $hit.FollowedUrl
    if ([string]::IsNullOrWhiteSpace($followed)) {
        $followed = $probe.Url
    }
    $chosen = [pscustomobject]@{
        Probe   = $probe
        Head    = $hit
        BaseUrl = $followed.TrimEnd("/")
    }
    if ($hit.Status -eq 200) {
        break
    }
}

if ($null -eq $chosen) {
    $hint = "IIS application kayitli mi? Bu sunucu public hostname'e cikamayabilir; yerel health kullanin."
    throw "Health baglantisi yok.`n$($failures -join "`n")`n$hint"
}

$base = $chosen.BaseUrl
$requestHost = $chosen.Probe.RequestHost
$skipCert = [bool]$chosen.Probe.SkipCert
$pwaStatus = $chosen.Head.Status
if ($pwaStatus -ne 200) {
    $detail = $chosen.Head.Text
    if ($detail -match '0x80070005|insufficient permissions') {
        throw @"
PWA HTTP 500.19  $base
IIS AppPool Desktop'taki web.config'i okuyamiyor (0x80070005).

Tek satir, Administrator PowerShell (sirayi degistirmeyin):
  cd C:\Users\yturak\Desktop\teknofest-Kiosk; git pull --ff-only origin main; .\tool\server_up.ps1 -SkipGitPull

$detail
"@
    }
    throw "PWA HTTP $pwaStatus  $base`n$detail"
}

$versionUrl = "$base/app/version.json"
$versionHead = Invoke-CurlHead -Url $versionUrl -RequestHost $requestHost -SkipCertCheck $skipCert
if ($versionHead.Status -ne 200) {
    throw "version.json HTTP $($versionHead.Status)`n$($versionHead.Text)"
}
$versionType = Get-Header $versionHead.Text "Content-Type"
if ($versionType -notmatch "json") {
    throw "version.json Content-Type JSON degil: $versionType"
}

$tmp = Join-Path $env:TEMP "teknofest-version-check.json"
$getArgs = @("-sS", "--connect-timeout", "5", "--max-time", "20", "-o", $tmp)
if ($skipCert) { $getArgs += "-k" }
if (-not [string]::IsNullOrWhiteSpace($requestHost)) { $getArgs += @("-H", "Host: $requestHost") }
$getArgs += $versionUrl
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
$apkHead = Invoke-CurlHead -Url $apkUrl -RequestHost $requestHost -SkipCertCheck $skipCert
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
