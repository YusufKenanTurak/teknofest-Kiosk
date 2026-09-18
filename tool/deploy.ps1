# Sunucuda git pull + (varsa) build + IIS fiziksel klasore kopyalama + health check.
# Mevcut site rewrite kurallarina dokunmaz. Destructive path'leri reddeder.
#
#   .\tool\deploy.ps1 -IisPhysicalPath "C:\inetpub\wwwroot\teknofest"
#   .\tool\deploy.ps1 -IisPhysicalPath "C:\inetpub\wwwroot\teknofest" -SkipBuild

param(
    [Parameter(Mandatory = $true)]
    [string]$IisPhysicalPath,
    [string]$SourceRoot,
    [string]$HealthBaseUrl = "https://testapp.limak.com.tr/teknofest",
    [switch]$SkipBuild,
    [switch]$SkipHealthCheck,
    [string]$Notes
)

$ErrorActionPreference = "Stop"

function Assert-SafeIisPath([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    $name = Split-Path $full -Leaf
    if ($name -ne "teknofest") {
        throw "IisPhysicalPath son klasor adi 'teknofest' olmali. Gelen: $full"
    }
    $forbidden = @(
        "C:\inetpub\wwwroot",
        "C:\inetpub",
        "C:\Windows",
        "C:\"
    )
    foreach ($item in $forbidden) {
        if ($full.TrimEnd("\") -eq $item.TrimEnd("\")) {
            throw "IisPhysicalPath yasak bir kok: $full"
        }
    }
    return $full
}

$iisPath = Assert-SafeIisPath $IisPhysicalPath
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = Split-Path -Parent $PSScriptRoot
}
$SourceRoot = [System.IO.Path]::GetFullPath($SourceRoot)

if (-not (Test-Path (Join-Path $SourceRoot "pubspec.yaml"))) {
    throw "SourceRoot bir Flutter kiosk repo gibi gorunmuyor: $SourceRoot"
}

Set-Location $SourceRoot

if (Test-Path (Join-Path $SourceRoot ".git")) {
    Write-Host "git fetch / ff-only pull" -ForegroundColor Cyan
    git fetch origin
    git checkout main
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        throw "git pull --ff-only basarisiz. Sunucuda local commit olmamali."
    }
}

if (-not $SkipBuild) {
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $flutter) {
        Write-Host "flutter yok; mevcut publish/ kullanilacak." -ForegroundColor Yellow
    }
    else {
        & (Join-Path $SourceRoot "tool\build_web.ps1")
        & (Join-Path $SourceRoot "tool\publish_web.ps1") -Notes $Notes
        $apk = Join-Path $SourceRoot "build\app\outputs\flutter-apk\app-release.apk"
        if (Test-Path $apk) {
            & (Join-Path $SourceRoot "tool\publish_apk.ps1")
        }
    }
}

$publish = Join-Path $SourceRoot "publish"
if (-not (Test-Path (Join-Path $publish "index.html"))) {
    throw "publish/index.html yok. Once web build/publish calistirin."
}
if (-not (Test-Path (Join-Path $publish "web.config"))) {
    throw "publish/web.config yok."
}

$versionJson = Join-Path $publish "app\version.json"
if (-not (Test-Path $versionJson)) {
    throw "publish/app/version.json yok."
}
$null = Get-Content $versionJson -Raw | ConvertFrom-Json

if (-not (Test-Path $iisPath)) {
    New-Item -ItemType Directory -Path $iisPath | Out-Null
}

$preservedApk = Join-Path $env:TEMP "teknofest-yatay-latest.apk.bak"
$liveApk = Join-Path $iisPath "app\downloads\teknofest-yatay-latest.apk"
$newApk = Join-Path $publish "app\downloads\teknofest-yatay-latest.apk"
$hadLiveApk = Test-Path $liveApk
if ($hadLiveApk -and -not (Test-Path $newApk)) {
    Copy-Item $liveApk $preservedApk -Force
}

Write-Host "IIS klasore kopyalaniyor: $iisPath" -ForegroundColor Cyan
robocopy $publish $iisPath /MIR /XD "app\downloads" /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
$code = $LASTEXITCODE
if ($code -ge 8) {
    throw "robocopy basarisiz (exit $code)"
}

$downloadDir = Join-Path $iisPath "app\downloads"
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
if (Test-Path $newApk) {
    Copy-Item $newApk (Join-Path $downloadDir "teknofest-yatay-latest.apk") -Force
}
elseif ($hadLiveApk -and (Test-Path $preservedApk)) {
    Copy-Item $preservedApk (Join-Path $downloadDir "teknofest-yatay-latest.apk") -Force
    Write-Host "Yeni APK yok; onceki production APK korundu." -ForegroundColor Yellow
}

if (-not $SkipHealthCheck) {
    & (Join-Path $SourceRoot "tool\health_check.ps1") -BaseUrl $HealthBaseUrl
}

Write-Host "Deploy tamam." -ForegroundColor Green
