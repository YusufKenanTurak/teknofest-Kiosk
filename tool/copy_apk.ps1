# APK artifact'ini PWA'dan bagimsiz olarak IIS indirme yoluna koyar.
# Kaynak: apk\teknofest-yatay-latest.apk
# Hedef:  publish\app\downloads\teknofest-yatay-latest.apk  (HTTPS URL)
#
#   .\tool\copy_apk.ps1
#   .\tool\copy_apk.ps1 -FromApk ".\dist\teknofest-yatay-latest.apk"

param(
    [string]$FromApk,
    [string]$SourceRoot
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "server_paths.ps1")

$layout = Get-TeknofestDeployLayout -SourceRoot $SourceRoot

$source = $FromApk
if ([string]::IsNullOrWhiteSpace($source)) {
    if (Test-Path $layout.ApkPath) {
        $source = $layout.ApkPath
    }
    elseif (Test-Path $layout.IncomingApk) {
        $source = $layout.IncomingApk
    }
    else {
        throw @"
APK artifact yok. PWA ile karistirmayin.

Bu PC:
  .\tool\build_apk.ps1
  .\tool\publish_apk.ps1 -Notes "Stand release"

Sonra sunucuya kopyalayin:
  $($layout.CanonicalRoot)\apk\$($layout.ApkFileName)
"@
    }
}

$source = Assert-TeknofestApkFile $source
$dest = $layout.ApkIisPath
$destDir = Split-Path $dest -Parent
New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Copy-Item $source $dest -Force
Grant-TeknofestIisReadAccess -Path $destDir

$item = Get-Item $dest
Write-Host ("APK hazir: {0} ({1:N1} MB)" -f $dest, ($item.Length / 1MB)) -ForegroundColor Green
