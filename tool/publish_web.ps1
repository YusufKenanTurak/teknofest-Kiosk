# Flutter web cikisini publish/ icine kopyalar. app/ ve web.config korunur.
#
#   .\tool\publish_web.ps1

param(
    [string]$WebBuildDir,
    [string]$Notes
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($WebBuildDir)) {
    $WebBuildDir = Join-Path $root "build\web"
}
if (-not (Test-Path (Join-Path $WebBuildDir "index.html"))) {
    throw "Web build bulunamadi: $WebBuildDir. Once .\tool\build_web.ps1 calistirin."
}

$publish = Join-Path $root "publish"
if (-not (Test-Path $publish)) {
    New-Item -ItemType Directory -Path $publish | Out-Null
}

Get-ChildItem $publish -Force | Where-Object {
    $_.Name -notin @("app", "web.config")
} | Remove-Item -Recurse -Force

Copy-Item -Path (Join-Path $WebBuildDir "*") -Destination $publish -Recurse -Force

# Flutter SW keys are origin-relative. Under /teknofest/ the fetch handler
# would miss main.dart.js and must not treat app/version.json as a resource.
$swPath = Join-Path $publish "flutter_service_worker.js"
if (Test-Path $swPath) {
    $sw = [System.IO.File]::ReadAllText($swPath)
    $needle = "var key = event.request.url.substring(origin.length + 1);"
    if ($sw.Contains($needle) -and -not $sw.Contains("key.startsWith('teknofest/')")) {
        $patched = $sw.Replace(
            $needle,
            @"
  var key = event.request.url.substring(origin.length + 1);
  if (key.startsWith('teknofest/')) {
    key = key.substring('teknofest/'.length);
  }
"@
        )
        [System.IO.File]::WriteAllText($swPath, $patched)
        Write-Host "Service worker /teknofest/ path prefix duzeltildi." -ForegroundColor Green
    }
}

$appDir = Join-Path $publish "app"
$downloads = Join-Path $appDir "downloads"
New-Item -ItemType Directory -Path $downloads -Force | Out-Null

$writeArgs = @{
    OutputDir = $appDir
    ApkUrl    = "downloads/teknofest-yatay-latest.apk"
}
if (-not [string]::IsNullOrWhiteSpace($Notes)) {
    $writeArgs.Notes = $Notes
}
& (Join-Path $PSScriptRoot "write_version_manifest.ps1") @writeArgs

if (-not (Test-Path (Join-Path $publish "web.config"))) {
    throw "publish/web.config kayboldu; IIS MIME/rewrite kurallari yok."
}
if (-not (Test-Path (Join-Path $publish "index.html"))) {
    throw "publish/index.html yok."
}

Write-Host "PWA publish edildi: $publish" -ForegroundColor Green
