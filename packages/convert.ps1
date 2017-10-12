# Remove DB operations from standard Sitecore packages to make them re-deployable

Remove-SCDatabaseOperations -Path "$PWD\Sitecore 8.2 rev. 170614_single.scwdp.zip"
Remove-SCDatabaseOperations -Path "$PWD\Web Forms for Marketers 8.2 rev. 170518_single.scwdp.zip"