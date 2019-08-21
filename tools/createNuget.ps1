# UpdateAssemblyVersion.ps1
#
# This script will get the fileversion of ReactiveDomain.Core.dll. 
# This version number will be used to create the corresponding nuget package 
# The nuget is then pushed to nuget.org
# 
# Note: If build is unstable, a beta (pre release) version of the nuget will be pushed
#       If build is stable, a stable (release) version will be pushed


$branch = $env:TRAVIS_BRANCH
$masterString = "master"

# create and push nuget off of master branch
if ($branch -ne $masterString)  
{
  Write-Host ("Not a master branch. Will not create nuget")   
  Exit
}

Write-Host ("Powershell script location is " + $PSScriptRoot)

$ReactiveDomainDll = $PSScriptRoot + "\..\bld\Release\net472\ReactiveDomain.Core.dll"
$RDVersion = (Get-Item $ReactiveDomainDll).VersionInfo.FileVersion
$nuspec = $PSScriptRoot + "\..\src\ReactiveDomain.nuspec"
$nuget = $PSScriptRoot + "\..\src\.nuget\nuget.exe"
$isStable = $env:STABLE


Write-Host ("Reactive Domain version is " + $RDVersion)
Write-Host ("Stable is " + $isStable)
Write-Host ("nuspec file is " + $nuspec)
Write-Host ("Branch is file is " + $branch)

& $nuget update -self

$versionString = ""

if ($isStable -eq "false" )
{
  $versionString = $RDVersion + "-beta"
  Write-Host ("This is an unstable master build. pushing unstable nuget version: " + $versionString)
  & $nuget pack $nuspec -Version $versionString
}

if ($isStable -eq "true" )
{
  $versionString = $RDVersion
  Write-Host ("This is a stable master build. pushing stable nuget version: " + $versionString)
  & $nuget pack $nuspec -Version $versionString
}

$nupkg = $PSScriptRoot + "\ReactiveDomain." + $versionString + ".nupkg"

# TODO: Push the nuget to nuget.org
#& $nuget push -Source "https://api.nuget.org/v3/index.json" -ApiKey $PKI_APIKEY $nupkg


# TODO: Commit the change to build.props files and push to the reactivedomain repo
# Set-Location -Path $PSScriptRoot + "\.."
# git commit -m "increment assembly version"
# git push origin master
