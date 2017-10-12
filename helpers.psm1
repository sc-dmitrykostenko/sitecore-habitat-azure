Function Set-SCAzureStorageFile(
    [Parameter(Position=0,Mandatory=$true)][string]$Path,
    [Parameter(Position=1,Mandatory=$true)][string]$StorageAccountName,
    [Parameter(Position=2,Mandatory=$true)][string]$StorageContainerName,
    [Parameter(Position=3)][string]$RemotePath = "",
    [Parameter(Position=4)][int]$ExpirationDays = 60
    )
{
  $StorageAccount = Get-AzureRMStorageAccount | ? { $_.StorageAccountName -eq $StorageAccountName }
  $StorageAccountKey = $(Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $StorageAccount.ResourceGroupName).Value[0]

  $Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Protocol https

  $StorageContainer = Get-AzureStorageContainer -Name $StorageContainerName -Context $Context -ErrorAction SilentlyContinue
  if ($StorageContainer -eq $null) {
    $StorageContainer = New-AzureStorageContainer -Name $StorageContainerName -Context $Context
  }

  $Blob = Set-AzureStorageBlobContent -Context $Context -File $Path -Container $StorageContainerName -Blob $RemotePath -Force

  return New-AzureStorageBlobSASToken -Container $StorageContainerName -Blob $Blob.Name -Context $Context -Protocol HttpsOnly -Permission r -ExpiryTime $([datetime]::UtcNow.AddDays($ExpirationDays)) -FullUri
}

Export-ModuleMember -Function Set-SCAzureStorageFile

