# Habitat Deployment to Azure

Sample scripts and assets to deploy a Habitat solution to Azure.

  * Using modular ARM templates in Sitecore
  * Support for initial deployment and update
  * Support for Blue/Green deployment for the site instance
  * XP0 topology

What these scripts do NOT do:

  * Set up and maintenance of Traffic Manager
  * DNS or SSL management
  * Database backup or restore on failure

## Components

  * deploy.ps1 - main deployment script
  * deploy.config.ps1 - script configuration parameters
  * helpers.psm1 - Powershell module with helper functions
  * packages/convert.ps1 - example script to remove database operations from vanilla Sitecore XP and module packages.
  * parameters.json - template parameters file

## Setup
  
  1. Set up Management Key Vault:

      * Create Azure Key Vault and fill the secrets used in deployment parameters:

        * Passwords: `habitat-sqlpassword`, `habitat-sitecorepassword`
        * Connection strings: `habitat-mongodb-analytics`, `habitat-mongodb-trackinglive`, `habitat-mongodb-trackinghistory`, `habitat-mongodb-trackingcontact`

      * Grant access to the Key Vault to the accounts that will perform deployment
      * Copy resource ID of the Key Vault from Azure Portal and paste into all relevant parameters in the `parameters.json`.

  2. Prepare base Sitecore packages:

      * Download packages from [dev.sitecore.net](dev.sitecore.net) to `packages` folder (Sitecore, Web Forms for Marketers and Bootloader).
      * Run `packages\convert.ps1` to prepare 'withoutdb' versions of the packages.

  3. Prepare storage account
    
      * Create storage account
      * Create storage blob container
      * Create a folder and upload base Sitecore packages into the folder.
      * Put storage account name, container name and folder name (path) into `Deploy.config.ps1`

  4. Initial deployment

      * Put path to Sitecore license into `deploy.config.ps1`
      * Deploy 'blue' slot

      ``` PowerShell
      .\deploy.ps1 -DeploymentId <deployment ID> -PackagePath <path to Habitat.scwdp.zip> -Location <location> -Type initial -Slot blue
      ```

      * Deploy 'green' slot

      ``` PowerShell
      .\deploy.ps1 -DeploymentId <deployment ID> -PackagePath <path to Habitat.scwdp.zip> -Location <location> -Type initial -Slot green
      ```

  5. Continuous deployment
   
      * Choose slot (blue or green)
      * Deploy into the slot

      ``` PowerShell
      .\deploy.ps1 -DeploymentId <deployment ID> -PackagePath <path to Habitat.scwdp.zip> -Location <location> -Type update -Slot <slot>
      ```

