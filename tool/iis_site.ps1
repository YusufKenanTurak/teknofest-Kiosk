# IIS site cozumleme. Site-level rewrite'e dokunmaz.

$script:TeknofestPublicHost = "testapp.limak.com.tr"
$script:TeknofestSiblingApps = @("EnduransStaff", "LTStaff", "ANKStaff", "testcontainer")

function Test-TeknofestPlaceholderSiteName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return $true }
    if ($Name -match '[<>]') { return $true }
    if ($Name -match 'mevcut site') { return $true }
    if ($Name -eq 'GERCEK_SITE_ADI') { return $true }
    return $false
}

function Assert-TeknofestAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "IIS islemi icin PowerShell'i Administrator olarak acin."
    }
}

function Get-TeknofestIisInventory {
    $rows = @()
    foreach ($site in @(Get-Website)) {
        $binds = @($site.bindings.Collection | ForEach-Object { "$($_.protocol) $($_.bindingInformation)" })
        $apps = @(Get-WebApplication -Site $site.Name -ErrorAction SilentlyContinue | ForEach-Object { $_.Path })
        $rows += [pscustomobject]@{
            Name     = [string]$site.Name
            State    = [string]$site.State
            Pool     = [string]$site.applicationPool
            Bindings = ($binds -join " | ")
            Apps     = ($apps -join ", ")
        }
    }
    return $rows
}

function Write-TeknofestIisInventory {
    $rows = @(Get-TeknofestIisInventory)
    if ($rows.Count -eq 0) {
        Write-Host "IIS'te website yok." -ForegroundColor Yellow
        return
    }
    Write-Host "IIS siteleri:" -ForegroundColor Cyan
    foreach ($row in $rows) {
        Write-Host "  $($row.Name)  [$($row.State)]  pool=$($row.Pool)"
        Write-Host "    bind: $($row.Bindings)"
        Write-Host "    apps: $($row.Apps)"
    }
}

function Resolve-TeknofestIisSite {
    param(
        [string]$SiteName,
        [string]$HostName = $script:TeknofestPublicHost
    )

    $sites = @(Get-Website)
    if ($sites.Count -eq 0) {
        throw "IIS'te website yok. WebAdministration yuklu mu? Administrator musunuz?"
    }

    if (-not (Test-TeknofestPlaceholderSiteName $SiteName)) {
        $exact = @($sites | Where-Object { $_.Name -eq $SiteName })
        if ($exact.Count -eq 1) {
            return $exact[0]
        }
        Write-TeknofestIisInventory
        throw "Site bulunamadi: '$SiteName'. Yukaridaki Name degerini -SiteName olarak verin."
    }

    $byHost = @($sites | Where-Object {
            $info = (@($_.bindings.Collection) | ForEach-Object { [string]$_.bindingInformation }) -join ";"
            $info -match [regex]::Escape($HostName)
        })
    if ($byHost.Count -eq 1) {
        Write-Host "Site binding'den secildi: $($byHost[0].Name) ($HostName)" -ForegroundColor Green
        return $byHost[0]
    }

    $byApp = @($sites | Where-Object {
            $paths = @(Get-WebApplication -Site $_.Name -ErrorAction SilentlyContinue | ForEach-Object { $_.Path.Trim("/") })
            ($paths | Where-Object { $script:TeknofestSiblingApps -contains $_ }).Count -gt 0
        })
    if ($byApp.Count -eq 1) {
        Write-Host "Site mevcut uygulamalardan secildi: $($byApp[0].Name)" -ForegroundColor Green
        return $byApp[0]
    }

    if ($sites.Count -eq 1) {
        Write-Host "Tek IIS sitesi: $($sites[0].Name)" -ForegroundColor Green
        return $sites[0]
    }

    Write-TeknofestIisInventory
    throw "Site otomatik secilemedi. Ornek: .\tool\iis_register_application.ps1 -SiteName 'Default Web Site'"
}

function Get-TeknofestLocalHealthTargets {
    param(
        $Site,
        [string]$ApplicationName = "teknofest",
        [string]$HostName = $script:TeknofestPublicHost
    )

    $targets = @()
    $seen = @{}
    foreach ($binding in @($Site.bindings.Collection)) {
        $info = [string]$binding.bindingInformation
        if ($info -notmatch ':(\d+):(.*)$') {
            continue
        }
        $port = $Matches[1]
        $header = $Matches[2]
        if ([string]::IsNullOrWhiteSpace($header)) {
            $header = $HostName
        }
        $scheme = [string]$binding.protocol
        if ($scheme -ne "http" -and $scheme -ne "https") {
            continue
        }
        $url = "${scheme}://127.0.0.1:${port}/${ApplicationName}"
        $key = "$url|$header"
        if ($seen.ContainsKey($key)) {
            continue
        }
        $seen[$key] = $true
        $targets += [pscustomobject]@{
            Url        = $url
            HostHeader = $header
            Insecure   = ($scheme -eq "https")
        }
    }

    foreach ($fallback in @(
            @{ Url = "http://127.0.0.1/${ApplicationName}";  Insecure = $false },
            @{ Url = "https://127.0.0.1/${ApplicationName}"; Insecure = $true }
        )) {
        $key = "$($fallback.Url)|$HostName"
        if ($seen.ContainsKey($key)) {
            continue
        }
        $seen[$key] = $true
        $targets += [pscustomobject]@{
            Url        = $fallback.Url
            HostHeader = $HostName
            Insecure   = [bool]$fallback.Insecure
        }
    }
    return @($targets)
}
