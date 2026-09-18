# IIS host dizinleri. inetpub kullanilmaz.
# Canonical checkout: C:\Users\yturak\Desktop\teknofest-Kiosk
#
# IIS /teknofest physical path = <root>\publish
# Kaynak kod (lib/, tool/) servis edilmez.

$script:TeknofestServerRootCanonical = "C:\Users\yturak\Desktop\teknofest-Kiosk"

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
    [pscustomobject]@{
        ServerRoot      = $root
        CanonicalRoot   = $script:TeknofestServerRootCanonical
        PublishDir      = Join-Path $root "publish"
        DropDir         = Join-Path $root "drop"
        DistDir         = Join-Path $root "dist"
        IncomingZip     = Join-Path $root "dist\teknofest-iis-latest.zip"
        IisPhysicalPath = Join-Path $root "publish"
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

function Grant-TeknofestIisReadAccess {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$AppPoolName
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path $full)) {
        throw "ACL icin path yok: $full"
    }

    $grants = [System.Collections.Generic.List[string]]::new()
    $grants.Add("IIS_IUSRS:(OI)(CI)RX")
    $grants.Add("IUSR:(OI)(CI)RX")
    if (-not [string]::IsNullOrWhiteSpace($AppPoolName)) {
        $grants.Add("IIS AppPool\${AppPoolName}:(OI)(CI)RX")
    }

    foreach ($grant in $grants) {
        & icacls.exe $full /grant $grant /C /Q | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ACL uyarisi ($grant): icacls exit $LASTEXITCODE" -ForegroundColor Yellow
        }
    }
    Write-Host "IIS okuma ACL uygulandi: $full" -ForegroundColor Green
}
