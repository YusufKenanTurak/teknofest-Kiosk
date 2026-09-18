# pubspec surumunu dart-define olarak gomerek release APK uretir.
#
#   .\tool\build_apk.ps1
#   .\tool\build_apk.ps1 -UpdateBaseUrl "https://testapp.limak.com.tr/teknofest"

param(
    [string]$UpdateBaseUrl = "https://testapp.limak.com.tr/teknofest",
    [string]$AppEnv = "test"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "app_version.ps1")

$v = Get-AppVersion -MobileRoot $root
Set-Location $root

Write-Host "Building $($v.Label)  UPDATE_BASE_URL=$UpdateBaseUrl" -ForegroundColor Cyan

flutter build apk --release `
    --dart-define=APP_VERSION=$($v.Name) `
    --dart-define=APP_BUILD=$($v.Build) `
    --dart-define=UPDATE_BASE_URL=$UpdateBaseUrl `
    --dart-define=APP_ENV=$AppEnv

if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk basarisiz"
}

Write-Host "APK: $(Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk')" -ForegroundColor Green
