#################################################
# Configurable Variables #
#################################################
# Specify the target shared space for restoration, e.g. 1846a41c-edf6-474d-ad79-d20c1c13cb57
$sharedSpaceAppId = 'ec80858f-4b87-49da-a7b6-bb94d8ae8319'    #AppID of the Application in Shared space
# Specify the target managed space for publish, e.g. 5e42f31c5d851d0001f8ca56
$managedSpaceId = '63109deacdc002266e7e013e'     #Managed Space ID
# Specify the location for the backed up app, e.g. C:\tmp\admin-playbook-unbuild-2022-02-22
$restoreDirectory = 'C:\Users\Oppilaale\Documents\Projects\Internal Activities\Backups\tips-and-tricks-unbuild-2022-09-01'    #App Backup folder path

#################################################
# Main Logic #
#################################################
# GOTO the restored app's directory
Set-Location $restoreDirectory

# Publish the app to a managed space
$publishedApp = qlik app publish create $sharedSpaceAppId --data source --spaceId $managedSpaceId | ConvertFrom-Json

# GOTO the Community sheets directory & Publish them on the app version in the managed space
Set-Location '.\sheets-community'
$communitySheetObjects = Get-ChildItem -Filter sheet*.json
$communitySheetObjects | %{
 qlik app object set $_ --app $($publishedApp.attributes.id)
 $sheetInfo = gc $_ | ConvertFrom-Json
 qlik app object publish $($sheetInfo.qProperty.qInfo.qId) --app $($publishedApp.attributes.id)
}

# GOTO the Community sheets directory & Publish them on the app version in the managed space
Set-Location '..\sheets-private'
$communitySheetObjects = Get-ChildItem -Filter sheet*.json
$communitySheetObjects | %{
 qlik app object set $_ --app $($publishedApp.attributes.id)
}