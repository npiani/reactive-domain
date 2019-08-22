# UpdateAssemblyVersion.ps1
#
# This script will get the fileversion of ReactiveDomain.Core.dll. 
# This version number will be used to create the corresponding nuget package 
# The nuget is then pushed to nuget.org
# 
# Note: If build is unstable, a beta (pre release) version of the nuget will be pushed
#       If build is stable, a stable (release) version will be pushed

# branch must be master to create a nuget
$masterString = "update-nuspec-for-builds"
$branch = $env:TRAVIS_BRANCH
$apikey = $env:NugetOrgApiKey

# create and push nuget off of master branch ONLY
if ($branch -ne $masterString)  
{
  Write-Host ("Not a master branch. Will not create nuget")   
  Exit
}

# This changes when its a CI build or a manually triggered via the web UI
# api --> means manual/stable build ;  push --> means CI/unstable build
$buildType = $env:TRAVIS_EVENT_TYPE    


Write-Host ("Powershell script location is " + $PSScriptRoot)

$ReactiveDomainDll = $PSScriptRoot + "\..\bld\Release\net472\ReactiveDomain.Core.dll"
$RDVersion = (Get-Item $ReactiveDomainDll).VersionInfo.FileVersion
$nuspec = $PSScriptRoot + "\..\src\ReactiveDomain.nuspec"
$nuget = $PSScriptRoot + "\..\src\.nuget\nuget.exe"

Write-Host ("Reactive Domain version is " + $RDVersion)
Write-Host ("Build type is " + $buildType)
Write-Host ("nuspec file is " + $nuspec)
Write-Host ("Branch is file is " + $branch)

& $nuget update -self

$versionString = ""

if ($buildType -eq "push" )
{
  $versionString = $RDVersion + "-beta"
  Write-Host ("This is an unstable master build. pushing unstable nuget version: " + $versionString)
  & $nuget pack $nuspec -Version $versionString
}

if ($buildType -eq "api" )
{
  $versionString = $RDVersion
  Write-Host ("This is a stable master build. pushing stable nuget version: " + $versionString)
  & $nuget pack $nuspec -Version $versionString
}

$nupkg = $PSScriptRoot + "\..\TestReactiveDomainNnuget." + $versionString + ".nupkg"

# TODO: Push the nuget to nuget.org
#& $nuget push $nupkg -Source "https://api.nuget.org/v3/index.json" -ApiKey $apikey 


# TODO: Commit the change to build.props files and push to the reactivedomain repo
$solutionDir = $PSScriptRoot + "\.."
Set-Location -Path $solutionDir
git init
git config user.email "josh.kempner@perkinelmer.com"
git config user.name "joshkempner"
git add .
git commit -m "Increment AssemblyVersion"
git push origin "update-nuspec-for-builds" -v -f
