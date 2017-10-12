param (
      [Parameter(Mandatory=$true)][string]$DeploymentId,
      [Parameter(Mandatory=$true)][string]$PackagePath, 

      # Change the location to East US for the demo
      [Parameter(Mandatory=$false)][string]$Location = "North Europe",

      # Deployment parameters
      [Parameter(Mandatory=$false)][string]$Type = "initial",
      [Parameter(Mandatory=$false)][string]$Slot = "blue")

$OperationStart = [datetime]::UtcNow

################################################################
# Import configuration

. $PSScriptRoot\deploy.config.ps1

################################################################
# Upload the package to the storage account for deployment

Import-Module $PSScriptRoot\helpers.psm1
$PackageUrl = Set-SCAzureStorageFile $PackagePath $StorageAccount $StorageContainer "$StoragePath/habitat-$([DateTime]::UtcNow.ToString("yyyyMMdd-HHmmss")).scwdp.zip"

$PackageUrl

################################################################
# Update the parameters with package URLs, depending on deployment type

$Parameters = Get-Content -Raw "$PSScriptRoot\parameters.json" | ConvertFrom-Json

$WDPLinks = @{
  "initial" = @{
    "sitecore" = "https://$StorageAccount.blob.core.windows.net/$StorageContainer/$StoragePath/Sitecore%208.2%20rev.%20170614_single.scwdp.zip";
    "wffm" = "https://$StorageAccount.blob.core.windows.net/$StorageContainer/$StoragePath/Web%20Forms%20for%20Marketers%208.2%20rev.%20170518_single.scwdp.zip";
    "bootloader" = "https://$StorageAccount.blob.core.windows.net/$StorageContainer/$StoragePath/Sitecore.Cloud.Integration.Bootload.wdp.zip";
  };
  "update" = @{
    "sitecore" = "https://$StorageAccount.blob.core.windows.net/$StorageContainer/$StoragePath/Sitecore%208.2%20rev.%20170614_single.withoutdb.scwdp.zip";
    "wffm" = "https://$StorageAccount.blob.core.windows.net/$StorageContainer/$StoragePath/Web%20Forms%20for%20Marketers%208.2%20rev.%20170518_single.withoutdb.scwdp.zip";
    "bootloader" = "https://$StorageAccount.blob.core.windows.net/$StorageContainer/$StoragePath/Sitecore.Cloud.Integration.Bootload.wdp.zip";
  }
}

if (!($WDPLinks[$Type])) {
  throw "Deployment type '$Type' is not supported. Use 'initial' or 'update'"
}

$Parameters.parameters.singleMsDeployPackageUrl.value = $WDPLinks[$Type].sitecore
$Parameters.parameters.modules.value.items[0].parameters.singleMsDeployPackageUrl = $WDPLinks[$Type].wffm
$Parameters.parameters.modules.value.items[1].parameters.singleMsDeployPackageUrl = $PackageUrl
$Parameters.parameters.modules.value.items[2].parameters.msDeployPackageUrl = $WDPLinks[$Type].bootloader

$Parameters | ConvertTo-Json -Depth 99 | Set-Content -Encoding UTF8 "parameters.gen.json"

################################################################
# Invoke the deployment

$TemplateUri = "https://raw.githubusercontent.com/Sitecore/Sitecore-Azure-Quickstart-Templates/master/Sitecore%208.2.4/xp0/azuredeploy.json"

echo "Start-SitecoreAzureDeployment -Name $DeploymentId -Location $Location -ArmTemplateUrl $TemplateUri -ArmParametersPath `"parameters.gen.json`" -LicenseXmlPath $LicensePath -SetKeyValue @{ `"singleWebAppName`" = `"$DeploymentId-$Slot`"}"
Start-SitecoreAzureDeployment -Name $DeploymentId -Location $Location -ArmTemplateUrl $TemplateUri -ArmParametersPath "parameters.gen.json" -LicenseXmlPath $LicensePath -SetKeyValue @{ "singleWebAppName" = "$DeploymentId-$Slot"}

################################################################
# Wait for the instance to start up

$Hostname = "$DeploymentId-$Slot.azurewebsites.net"

$R = try { Invoke-WebRequest "https://$Hostname/sitecore/login" -ea SilentlyContinue } catch {}
while (!$R) {
  Start-Sleep 10
  echo "Waiting for Sitecore to start up..."
  $R = try { Invoke-WebRequest "https://$Hostname/sitecore/login" -ea SilentlyContinue } catch {}
}

################################################################
# Publish 

echo "Publishing..."
echo "Invoke-WebRequest -Method POST -TimeoutSec 3600 `"https://$Hostname/devops/publishing/publishSync?apikey=...`""
$R = try { Invoke-WebRequest -Method POST -TimeoutSec 3600 "https://$Hostname/devops/publishing/publishSync?apikey=$ApiKey" -ea SilentlyContinue } catch {}
while (!$R) {
  echo "Request failed. Retrying in 1 min..."
  Start-Sleep 60
  echo "Invoke-WebRequest -Method POST -TimeoutSec 3600 `"https://$Hostname/devops/publishing/publishSync?apikey=...`""
  $R = try { Invoke-WebRequest -Method POST -TimeoutSec 3600 "https://$Hostname/devops/publishing/publishSync?apikey=$ApiKey" -ea SilentlyContinue } catch {}
}

################################################################
# Report

echo "Deployment finished, open https://$Hostname/"
$operationFinish = [datetime]::UtcNow

echo "Start: $OperationStart, Finish: $OperationFinish, Duration: $($OperationFinish - $OperationStart)"
