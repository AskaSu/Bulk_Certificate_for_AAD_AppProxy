<#
 
 .Description
  For bulk update Certificate to multiple AAD AppProxy 
   
 .Notes
  Reference: https://dectur.com/bulk-update-app-proxy-cert
  Modified by Aska Su
  URL: www.askasu.idv.tw

#>


Param(
    [Parameter(Mandatory=$True)]
    [String] $PFXLocation
)

#Connect to AzureAD
#Write-Host 'Connecting to AzureAD' -ForegroundColor Yellow
#Connect-AzureAD

# $PFXLocation = "C:\Temp\wildcard_askacloud_com.pfx"

#Enter the PFX password 
Write-Host 'Enter the password for PFX file' -ForegroundColor Yellow
$PFXPassword = Read-Host -AsSecureString

$AADName = @((@((Get-AzureADDomain | Where-Object {$_.Name -like "*.onmicrosoft.com"}).Name )[0]).Split("."))[0]
$ImportFilePath = "C:\Temp\" + $AADName + "_AADAppProxy_Checking_list_" + "$((Get-Date -format yyyy-MMdd).ToString()).csv"

$AppsOnCustomDomain = Import-CSV -path $ImportFilePath

Write-Host 'Are you sure you wish to change certificate on the above applications? (Y/N)' -ForegroundColor Yellow
$Answer = Read-Host


If ($Answer -eq 'Y'){
  #Loop through the custom domain apps and upload new TLS certificate 
  foreach ($CustomDomainApp in $AppsOnCustomDomain) {
      Write-Host "Setting Certificate on Application" $CustomDomainApp.DisplayName -ForegroundColor Green
      Set-AzureADApplicationProxyApplicationCustomDomainCertificate -ObjectId $CustomDomainApp.ObjectID -PfxFilePath $PFXLocation -Password $PFXPassword
    }

}

else {
  Write-Host 'Apps not approved for change' -ForegroundColor Red
}
