#
# Script to deploy the ARM template vpn.json
#
# The value of variables:
#    mngIP: management IP 
#    subscriptionName: Azure subscription name
#    ResourceGroupName: Name of the Resource group 
#    location1: Azure region of the vnet1
#    location2: Azure region of the vnet2
# are colleted from the file "init.txt"
#
#
[CmdletBinding()]
param (
    [Parameter( Mandatory = $false, ValueFromPipeline=$false, HelpMessage='VMs administrator username')]
    [string]$adminUsername = "ADMINISTRATOR_USERNAME",
 
    [Parameter(Mandatory = $false, HelpMessage='VMs administrator password')]
    [string]$adminPassword = "ADMINISTRATOR_PASSWORD"
    )

################# Input parameters #################
$deploymentName = "vpn1"
$armTemplateFile = "vpn.json"
####################################################

$pathFiles = Split-Path -Parent $PSCommandPath
$templateFile = "$pathFiles\$armTemplateFile"


#Reading the resource group name from the file init.txt
If (Test-Path -Path $pathFiles\init.txt) {
        Get-Content $pathFiles\init.txt | Foreach-Object{
        $var = $_.Split('=',[System.StringSplitOptions]::RemoveEmptyEntries)
        Try {New-Variable -Name $var[0].Trim() -Value $var[1].Trim() -ErrorAction Stop}
        Catch {Set-Variable -Name $var[0].Trim() -Value $var[1].Trim()}
        }
}
Else {Write-Warning "init.txt file not found, please change to the directory where these scripts reside ($pathFiles) and ensure this file is present.";Return}

if (!$mngIP) { Write-Host 'variable $mngIP is null' ; Exit }
if (!$subscriptionName) { Write-Host 'variable $subscriptionName is null' ; Exit }
if (!$ResourceGroupName) { Write-Host 'variable $ResourceGroupName is null' ; Exit }
if (!$location1) { Write-Host 'variable $location1 is null' ; Exit }
if (!$location2) { Write-Host 'variable $location2 is null' ; Exit }
$rgName=$ResourceGroupName

write-host "reading Azure subscription name: $subscriptionName from the file init.txt " -ForegroundColor Green
write-host "reading resource group name: $rgName from the file init.txt " -ForegroundColor Green
write-host "reading location1 name: $location1 from the file init.txt " -ForegroundColor Green
write-host "reading location2 name: $location2 from the file init.txt " -ForegroundColor Green


$parameters=@{
              "mngIP"= $mngIP;
              "adminUsername"= $adminUsername;
              "adminPassword"= $adminPassword;
              "location1"= $location1;
              "location2"= $location2
              }
write-host "parameters value:" $parameters.Values -ForegroundColor Yellow

$subscr=Get-AzSubscription -SubscriptionName $subscriptionName
Select-AzSubscription -SubscriptionId $subscr.Id

# Create Resource Group
Write-Host "$(Get-Date) - Creating Resource Group $rgName " -ForegroundColor Cyan
Try {$rg = Get-AzResourceGroup -Name $rgName  -ErrorAction Stop
     Write-Host '  resource exists, skipping'}
Catch {$rg = New-AzResourceGroup -Name $rgName  -Location $location1  }

$startTime = Get-Date
$runTime=Measure-Command {
write-host "running ARM template:"$templateFile
     New-AzResourceGroupDeployment  -Name $deploymentName -ResourceGroupName $rgName -TemplateFile $templateFile -TemplateParameterObject $parameters -Verbose 
}

write-host "runtime...: "$runTime.ToString() -ForegroundColor Yellow
write-host "start time: "$startTime -ForegroundColor Yellow
write-host "end  time.: "$(Get-Date) -ForegroundColor Yellow