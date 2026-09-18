# pubspec.yaml icindeki `version: X.Y.Z+B` degerini okur.
function Get-AppVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MobileRoot
    )

    $pubspecPath = Join-Path $MobileRoot "pubspec.yaml"
    if (-not (Test-Path $pubspecPath)) {
        throw "pubspec.yaml bulunamadi: $pubspecPath"
    }

    $match = Select-String -Path $pubspecPath -Pattern '^version:\s*([0-9]+(?:\.[0-9]+)*)(?:\+([0-9]+))?' |
        Select-Object -First 1

    if (-not $match) {
        throw "pubspec.yaml icinde 'version:' satiri okunamadi: $pubspecPath"
    }

    $name = $match.Matches[0].Groups[1].Value
    $buildGroup = $match.Matches[0].Groups[2]
    $build = if ($buildGroup.Success) { [int]$buildGroup.Value } else { 0 }

    return [pscustomobject]@{
        Name  = $name
        Build = $build
        Label = if ($build -gt 0) { "$name+$build" } else { $name }
    }
}
