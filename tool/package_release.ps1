# PWA-only zip. APK bu pakete girmez; ayri artifact (apk\ / package_apk.ps1).
#
#   .\tool\package_release.ps1
#   -> dist\teknofest-pwa-latest.zip

param(
    [string]$PublishDir,
    [string]$OutputZip
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")
$layout = Get-TeknofestDeployLayout

if ([string]::IsNullOrWhiteSpace($PublishDir)) {
    $PublishDir = $layout.PublishDir
}
$PublishDir = [System.IO.Path]::GetFullPath($PublishDir)

foreach ($required in @("index.html", "web.config", "app\version.json")) {
    if (-not (Test-Path (Join-Path $PublishDir $required))) {
        throw "PublishDir icinde $required yok. Once bu PC'de .\tool\build_web.ps1 ve .\tool\publish_web.ps1 calistirin."
    }
}

New-Item -ItemType Directory -Path $layout.DistDir -Force | Out-Null

$stamp = Get-Date -Format "yyyyMMdd-HHmm"
if ([string]::IsNullOrWhiteSpace($OutputZip)) {
    $OutputZip = Join-Path $layout.DistDir "teknofest-pwa-$stamp.zip"
}
$OutputZip = [System.IO.Path]::GetFullPath($OutputZip)
$latestZip = $layout.IncomingZip
$legacyZip = Join-Path $layout.DistDir "teknofest-iis-latest.zip"

if (Test-Path $OutputZip) {
    Remove-Item $OutputZip -Force
}

$staging = Join-Path $layout.DistDir ("_stage-pwa-" + [guid]::NewGuid().ToString("N"))
$excludeDownloads = Join-Path $PublishDir "app\downloads"
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    robocopy $PublishDir $staging /E /XD $excludeDownloads /XF *.apk /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    $code = $LASTEXITCODE
    if ($code -ge 8) {
        throw "PWA staging kopyasi basarisiz (robocopy exit $code)"
    }
    $leaked = Get-ChildItem $staging -Filter *.apk -Recurse -ErrorAction SilentlyContinue
    if ($leaked) {
        throw "PWA zip'ine APK sizmamali: $($leaked.FullName -join ', ')"
    }
    Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $OutputZip -CompressionLevel Optimal
}
finally {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

Copy-Item $OutputZip $latestZip -Force
Copy-Item $OutputZip $legacyZip -Force

Write-Host "PWA paketi: $OutputZip" -ForegroundColor Green
Write-Host "Latest:     $latestZip" -ForegroundColor Green
Write-Host "APK bu zip'te yok; .\tool\package_apk.ps1 kullanin." -ForegroundColor Cyan
