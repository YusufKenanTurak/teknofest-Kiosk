# IIS sitelerini listeler. Kayit icin SiteName buradan kopyalanir.
#
#   .\tool\iis_inspect.ps1

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "iis_site.ps1")
Assert-TeknofestAdministrator
Import-Module WebAdministration
Write-TeknofestIisInventory
