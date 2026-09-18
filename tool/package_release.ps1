# Bu PC'de uretilmis publish/ klasorunu sunucuya tasınacak zip haline getirir.
# Flutter cagirmaz; once build_web + publish_web (ve istenirse APK) calismis olmali.
#
#   .\tool\package_release.ps1
#   -> dist\teknofest-iis-latest.zip

param(
    [string]$PublishDir,
    [string]$OutputZip
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($PublishDir)) {
    $PublishDir = Join-Path $root "publish"
}
$PublishDir = [System.IO.Path]::GetFullPath($PublishDir)

foreach ($required in @("index.html", "web.config", "app\version.json")) {
    if (-not (Test-Path (Join-Path $PublishDir $required))) {
        throw "PublishDir icinde $required yok. Once bu PC'de .\tool\build_web.ps1 ve .\tool\publish_web.ps1 calistirin."
    }
}

$dist = Join-Path $root "dist"
if (-not (Test-Path $dist)) {
    New-Item -ItemType Directory -Path $dist | Out-Null
}

$stamp = Get-Date -Format "yyyyMMdd-HHmm"
if ([string]::IsNullOrWhiteSpace($OutputZip)) {
    $OutputZip = Join-Path $dist "teknofest-iis-$stamp.zip"
}
$OutputZip = [System.IO.Path]::GetFullPath($OutputZip)
$latestZip = Join-Path $dist "teknofest-iis-latest.zip"

if (Test-Path $OutputZip) {
    Remove-Item $OutputZip -Force
}

$staging = Join-Path $dist ("_stage-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    robocopy $PublishDir $staging /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    $code = $LASTEXITCODE
    if ($code -ge 8) {
        throw "publish staging kopyasi basarisiz (robocopy exit $code)"
    }
    Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $OutputZip -CompressionLevel Optimal
}
finally {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

Copy-Item $OutputZip $latestZip -Force

$apk = Join-Path $PublishDir "app\downloads\teknofest-yatay-latest.apk"
if (Test-Path $apk) {
    Write-Host "Paket APK iceriyor." -ForegroundColor Green
}
else {
    Write-Host "Paket APK icermiyor; sunucudaki mevcut APK korunabilir." -ForegroundColor Yellow
}

Write-Host "Release paketi: $OutputZip" -ForegroundColor Green
Write-Host "Latest kopya:   $latestZip" -ForegroundColor Green
