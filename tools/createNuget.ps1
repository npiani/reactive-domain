




Write-Host ("Powershell script location is " + $PSScriptRoot)

$ReactiveDomainDll = $PSScriptRoot + "\..\bld\Release\net472\ReactiveDomain.Core.dll"
$RDVersion = (Get-Item $ReactiveDomainDll).VersionInfo.FileVersion

Write-Host ("Reactive Domain version is " + $RDVersion)
Write-Host ("Stable is " + $env:STABLE)

