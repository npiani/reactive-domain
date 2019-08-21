

Write-Host ("Powershell script location is " + $PSScriptRoot)

$buildProps = $PSScriptRoot + "\..\src\build.props"
$props = [xml] (get-content $buildProps)
$assemblyVersionNode = $props.SelectSingleNode("//Project/PropertyGroup/AssemblyVersion")
$fileVersionNode = $props.SelectSingleNode("//Project/PropertyGroup/FileVersion")

Write-Host ("Version node is " + $assemblyVersionNode.InnerText )

$major = $assemblyVersionNode.InnerText.Split('.')[0]
$minor = $assemblyVersionNode.InnerText.Split('.')[1]
$build = $assemblyVersionNode.InnerText.Split('.')[2]
$revision = $assemblyVersionNode.InnerText.Split('.')[3]
[int]$newRevision = 999
[bool]$result = [int]::TryParse($revision, [ref]$newRevision)

Write-Host ("revision is " + $revision )

$global:newRevision++

Write-Host ("New revision will be is " + $newRevision )

$newAssemblyVersion = $major + "." + $minor + "." + $build + "." + $newRevision

Write-Host ("New assembly version will be is " + $newAssemblyVersion )

#Update the props file
$assemblyVersionNode.InnerText = $newAssemblyVersion
$fileVersionNode.InnerText = $newAssemblyVersion

$props.Save($buildProps)

