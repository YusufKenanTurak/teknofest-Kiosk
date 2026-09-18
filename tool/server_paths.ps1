# IIS host dizinleri. inetpub kullanilmaz.
# Canonical checkout: C:\Users\yturak\Desktop\teknofest-Kiosk
#
# PWA:  <root>\publish                  IIS /teknofest
# APK:  <root>\apk\teknofest-yatay-latest.apk
#       kopyalaninca: <root>\publish\app\downloads\  (HTTPS URL; PWA agacinin parcasi degil)

$script:TeknofestServerRootCanonical = "C:\Users\yturak\Desktop\teknofest-Kiosk"
$script:TeknofestApkFileName = "teknofest-yatay-latest.apk"

function Get-TeknofestDeployLayout {
    param([string]$SourceRoot)

    if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
        $fromTool = Split-Path -Parent $PSScriptRoot
        if (Test-Path (Join-Path $fromTool "tool\deploy.ps1")) {
            $SourceRoot = $fromTool
        }
        else {
            $SourceRoot = $script:TeknofestServerRootCanonical
        }
    }

    $root = [System.IO.Path]::GetFullPath($SourceRoot)
    $publish = Join-Path $root "publish"
    $apkDir = Join-Path $root "apk"
    [pscustomobject]@{
        ServerRoot      = $root
        CanonicalRoot   = $script:TeknofestServerRootCanonical
        PublishDir      = $publish
        ApkDir          = $apkDir
        ApkFileName     = $script:TeknofestApkFileName
        ApkPath         = Join-Path $apkDir $script:TeknofestApkFileName
        ApkIisPath      = Join-Path $publish "app\downloads\$($script:TeknofestApkFileName)"
        DropDir         = Join-Path $root "drop"
        DistDir         = Join-Path $root "dist"
        IncomingZip     = Join-Path $root "dist\teknofest-pwa-latest.zip"
        IncomingApk     = Join-Path $root "dist\$($script:TeknofestApkFileName)"
        IisPhysicalPath = $publish
        ApplicationName = "teknofest"
    }
}

function Assert-TeknofestIisPhysicalPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    $normalized = $full.TrimEnd("\")
    $forbidden = @(
        "C:\inetpub\wwwroot",
        "C:\inetpub",
        "C:\Windows",
        "C:\",
        "C:\Users",
        "C:\Users\yturak",
        "C:\Users\yturak\Desktop"
    )
    foreach ($item in $forbidden) {
        if ($normalized -eq $item.TrimEnd("\")) {
            throw "IisPhysicalPath yasak bir kok: $full"
        }
    }

    $leaf = Split-Path $full -Leaf
    $parentLeaf = Split-Path (Split-Path $full -Parent) -Leaf
    if ($leaf -ne "publish" -or $parentLeaf -ne "teknofest-Kiosk") {
        throw "IIS physical path kabul edilmez: $full. Beklenen: C:\Users\yturak\Desktop\teknofest-Kiosk\publish"
    }
    if ($normalized.StartsWith("C:\inetpub", [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "IIS physical path inetpub olamaz: $full"
    }
    return $full
}

function Assert-TeknofestApkFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path $full)) {
        throw "APK yok: $full. Bu PC'de .\tool\build_apk.ps1 ; .\tool\publish_apk.ps1 sonra sunucuya apk\ klasorunu kopyalayin."
    }
    if ([System.IO.Path]::GetExtension($full) -ne ".apk") {
        throw "APK uzantisi .apk olmali: $full"
    }
    $item = Get-Item $full
    if ($item.Length -lt 1MB) {
        throw "APK cok kucuk ($($item.Length) byte); gercek release degil: $full"
    }
    $fs = [System.IO.File]::OpenRead($full)
    try {
        $b0 = $fs.ReadByte()
        $b1 = $fs.ReadByte()
    }
    finally {
        $fs.Dispose()
    }
    if ($b0 -ne 0x50 -or $b1 -ne 0x4B) {
        throw "APK zip imzasi yok (PK): $full"
    }
    return $full
}

function Get-TeknofestIisIdentities {
    param([string]$AppPoolName)

    if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
        try {
            Import-Module WebAdministration -ErrorAction Stop
            $app = @(Get-WebApplication -ErrorAction Stop | Where-Object { $_.Path -eq "/teknofest" }) | Select-Object -First 1
            if ($null -ne $app -and -not [string]::IsNullOrWhiteSpace([string]$app.applicationPool)) {
                $AppPoolName = [string]$app.applicationPool
            }
        }
        catch {
        }
    }

    $ids = @("IIS_IUSRS", "IUSR")
    if (-not [string]::IsNullOrWhiteSpace($AppPoolName)) {
        $ids += "IIS AppPool\$AppPoolName"
    }
    return @($ids | Select-Object -Unique)
}

function Get-TeknofestIisTraverseParents {
    param([Parameter(Mandatory = $true)][string]$LeafPath)

    $stop = [System.IO.Path]::GetFullPath("C:\Users").TrimEnd("\")
    $parents = @()
    $cursor = Split-Path -Parent ([System.IO.Path]::GetFullPath($LeafPath))
    while (-not [string]::IsNullOrWhiteSpace($cursor)) {
        $norm = [System.IO.Path]::GetFullPath($cursor).TrimEnd("\")
        if ($norm.Length -le 3) {
            break
        }
        if ($norm.Equals($stop, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parents += $norm
        $cursor = Split-Path -Parent $norm
    }
    if ($parents.Count -gt 1) {
        [Array]::Reverse($parents)
    }
    return @($parents)
}

function Invoke-TeknofestIcaclsGrant {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$Identity,
        [Parameter(Mandatory = $true)][string]$Rights,
        [switch]$Recurse
    )

    $spec = "${Identity}:${Rights}"
    $icaclsArgs = @($Target, "/grant", $spec, "/C")
    if ($Recurse) {
        $icaclsArgs += "/T"
    }
    $output = & icacls.exe @icaclsArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ACL uyarisi ($spec -> $Target): exit $LASTEXITCODE $output" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Grant-TeknofestIisReadAccess {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$AppPoolName
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path $full)) {
        throw "ACL icin path yok: $full"
    }

    $identities = @(Get-TeknofestIisIdentities -AppPoolName $AppPoolName)
    $parents = @(Get-TeknofestIisTraverseParents -LeafPath $full)

    Write-Host "IIS ACL: parent traverse (Desktop profili) + $full" -ForegroundColor Cyan
    foreach ($parent in $parents) {
        foreach ($id in $identities) {
            $null = Invoke-TeknofestIcaclsGrant -Target $parent -Identity $id -Rights "(RX)"
        }
        Write-Host "  traverse RX  $parent" -ForegroundColor DarkGray
    }

    foreach ($id in $identities) {
        $null = Invoke-TeknofestIcaclsGrant -Target $full -Identity $id -Rights "(OI)(CI)RX"
    }

    $webConfig = Join-Path $full "web.config"
    if (Test-Path $webConfig) {
        foreach ($id in $identities) {
            $null = Invoke-TeknofestIcaclsGrant -Target $webConfig -Identity $id -Rights "(R)"
        }
    }

    Write-Host "IIS okuma ACL uygulandi: $full  ($($identities -join ', '))" -ForegroundColor Green
}
