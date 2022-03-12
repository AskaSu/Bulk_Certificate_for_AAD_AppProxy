<#
 
 .Description
  For createing AAD AppProxy report
   
 .Notes
  Reference: https://dectur.com/bulk-update-app-proxy-cert
  Modified by Aska Su
  URL: www.askasu.idv.tw

#>


Param(
    [Parameter(Mandatory = $true)]
    [string] $CustomDomain
)

$QueryDomain = "*"+ $CustomDomain + "/*"

#Connect to AzureAD
Write-Host 'Connecting to AzureAD' -ForegroundColor Yellow
Connect-AzureAD

#ExportFile
$AADName = @((@((Get-AzureADDomain | Where-Object {$_.Name -like "*.onmicrosoft.com"}).Name )[0]).Split("."))[0]
$ExportFilePath = "C:\Temp\" + $AADName + "_AADAppProxy_Checking_list_" + "$((Get-Date -format yyyy-MMdd).ToString()).csv"


#Get all Azure AD App Proxy Proxy Applications checking the ObjectID of all apps. 
Write-Host 'Obtaining Azure AD App Proxy Applications for your Domain' -ForegroundColor Yellow
$ProxyApps = foreach ($a in (Get-AzureADApplication -All:$true | Sort-Object DisplayName))
 {
     try
     {
         $p = Get-AzureADApplicationProxyApplication -ObjectId $a.ObjectId
         [pscustomobject]@{DisplayName=$a.DisplayName; ObjectID=$a.ObjectId; ExternalUrl=$p.ExternalUrl; InternalUrl=$p.InternalUrl; AuthenticationType=$p.ExternalAuthenticationType; ServerTimeout=$p.ApplicationServerTimeout; CertSubjectName = $p.VerifiedCustomDomainCertificatesMetadata.SubjectName; CertThumbprint = $p.VerifiedCustomDomainCertificatesMetadata.Thumbprint; CertExpiryDate = $p.VerifiedCustomDomainCertificatesMetadata.ExpiryDate ; CertificateInfo=$p.VerifiedCustomDomainCertificatesMetadata}
     }
     catch
     {
         continue
     }
}

#Filter the proxy applications with the ExternalURL of your domain to askacloud.com only, and not including Jira site series, rd.askacloud.com and iot.askacloud.com etc.
$AppsOnCustomDomain = $ProxyApps | Where-Object {$_.ExternalUrl -like $QueryDomain `
-and $_.ExternalUrl -notlike "*.jira*" `
-and $_.ExternalUrl -notlike "*rd.askacloud.com*" `
-and $_.ExternalUrl -notlike "*iot.askacloud.com*" `
}  | Sort-Object DisPlayName

Write-Host 'The following applications need to been reviewed for Certificate Update' -ForegroundColor Yellow
$AppsOnCustomDomain | Out-Host

#Export list for checking again and updating
$AppsOnCustomDomain | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $ExportFilePath
