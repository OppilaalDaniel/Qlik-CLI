#################################################
# Configurable Variables #
#################################################
# Specify the target shared space for restoration, e.g. 5e42f2cc0ea40d0001214b3a
$sharedSpaceId = '63109dd8a9027605d475f069'    #Shared Space ID
# Specify the target managed space for publish, e.g. 5e42f31c5d851d0001f8ca56
$managedSpaceId = '63109deacdc002266e7e013e'    #Managed Space ID
# Specify the location for the backed up app, e.g. C:\tmp\admin-playbook-unbuild-2022-02-22
$restoreDirectory = 'C:\Users\Oppilaale\Documents\Projects\Internal Activities\Backups\tips-and-tricks-unbuild-2022-09-01'    #Backup App folder path

#################################################
# Main Logic #
#################################################
# Create a dummy app in the shared space
$myNewApp = qlik app create --attributes-spaceId $sharedSpaceId --attributes-name "RESTORE IN PROCESS" | ConvertFrom-Json

# GOTO the backed up app's directory
Set-Location $restoreDirectory

# Restore the backed up app from the contents on disk (this app will be in a Shared space)
qlik app build --app $($myNewApp.attributes.id) --app-properties app-properties.json --dimensions dimensions.json --measures measures.json --objects objects\*.json --script script.qvs --variables variables.json

# Publish the sheets of the app in the Shared space
Set-Location "objects"
$baseSheetObjects = Get-ChildItem -Filter sheet*.json
$baseSheetObjects | %{
 $sheetInfo = gc $_ | ConvertFrom-Json
 qlik app object publish $($sheetInfo.qProperty.qInfo.qId) --app $($myNewApp.attributes.id)
}

# Publish the app to a managed space
$publishedApp = qlik app publish create $($myNewApp.attributes.id) --data source --spaceId $managedSpaceId | ConvertFrom-Json

# GOTO the Community sheets directory & Publish them on the app version in the managed space
Set-Location '..\sheets-community'
$communitySheetObjects = Get-ChildItem -Filter sheet*.json
$communitySheetObjects | %{
 qlik app object set $_ --app $($publishedApp.attributes.id)
 $sheetInfo = gc $_ | ConvertFrom-Json
 qlik app object publish $($sheetInfo.qProperty.qInfo.qId) --app
$($publishedApp.attributes.id)
}

# GOTO the Private sheets directory & Publish them on the app version in the managed space
Set-Location '..\sheets-private'
$privateSheetObjects = Get-ChildItem -Filter sheet*.json
$privateSheetObjects | %{
 qlik app object set $_ --app $($publishedApp.attributes.id)
}