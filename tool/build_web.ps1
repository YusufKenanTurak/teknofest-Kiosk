# Flutter web PWA'yi /teknofest base-href ile derler.
#
#   .\tool\build_web.ps1

param(
    [string]$BaseHref = "/teknofest/",
    [string]$AppEnv = "test",
    [string]$UpdateBaseUrl = "https://testapp.limak.com.tr/teknofest"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "app_version.ps1")

if (-not $BaseHref.StartsWith("/")) {
    throw "BaseHref site-kokune gore olmalidir, ornek: /teknofest/"
}
if (-not $BaseHref.EndsWith("/")) {
    $BaseHref = "$BaseHref/"
}

$v = Get-AppVersion -MobileRoot $root
Set-Location $root

Write-Host "Building web $($v.Label)  base-href=$BaseHref" -ForegroundColor Cyan

flutter build web --release `
    --base-href $BaseHref `
    --pwa-strategy=offline-first `
    --dart-define=APP_VERSION=$($v.Name) `
    --dart-define=APP_BUILD=$($v.Build) `
    --dart-define=UPDATE_BASE_URL=$UpdateBaseUrl `
    --dart-define=APP_ENV=$AppEnv

if ($LASTEXITCODE -ne 0) {
    throw "flutter build web basarisiz"
}

Write-Host "Web: $(Join-Path $root 'build\web')" -ForegroundColor Green
