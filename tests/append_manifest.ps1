#Requires -RunAsAdministrator

param ([Parameter(Mandatory = $true)][string]$ManifestPath)

$manifestFile = Resolve-Path $ManifestPath
Set-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" -Name DistributionListUrlAppend -Value "file://$manifestFile" -Type String -Force
