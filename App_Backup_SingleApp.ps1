#################################################
# Configurable Variables #
#################################################
# Specify the app ID in GUID format, e.g. 871c53f3-f53b-4d32-b5a6-5135f16910d0
$appId = '43ff4fb1-e916-451c-aae9-587fa07bc7f5'  #App ID
# Specify the location for the backup, e.g. C:\tmp
$backupLocation = 'D:\Qlik CLI\Qlik SaaS Managed Space Backups'    #Change folder path
#################################################
# Main Logic #
#################################################
$backupDate = Get-Date -Format yyyy-MM-dd
# Prep locations for files
Set-Location $backupLocation # GOTO backup path
$app = qlik app get $appId | ConvertFrom-Json # Get App Metadata, used elsewhere
$tmp = (New-GUID).Guid # Get GUID for stage path
New-Item $tmp -ItemType Directory | Out-Null # Create stage path
Set-Location "$($backupLocation)\$($tmp)" # GOTO stage path

# Unbuild the app
qlik app unbuild -a $appId | Out-Null

# GOTO unbuild dir
$backupAppDirName = (Get-ChildItem -Directory).Name
Set-Location $backupAppDirName

# Create directories for today's backup of the specified app
New-Item -Path "$($backupLocation)\$backupAppDirName-$backupDate" -Type Directory | Out-Null # Base Directory
New-Item -Path "$($backupLocation)\$backupAppDirName-$backupDate\objects" -Type Directory | Out-Null # Non-Sheet objects

# Move app property files over
Move-Item -Path "$(pwd)\*.*" -Destination "$($backupLocation)\$backupAppDirName-$backupDate"

# Go into objects dir
Set-Location objects

# Get non-sheet objects & move them
$notSheetObjects = Get-ChildItem -Exclude sheet*.json
$notSheetObjects | %{ Move-Item $_.Name -Destination "$($backupLocation)\$backupAppDirName-$backupDate\objects"}

# Create sheet directories
New-Item -Path "$($backupLocation)\$backupAppDirName-$backupDate\sheets-community" -Type Directory | Out-Null
New-Item -Path "$($backupLocation)\$backupAppDirName-$backupDate\sheets-private" -Type Directory | Out-Null

# Handle sheet objects
$sheetObjects = Get-ChildItem -Filter sheet*.json
$sheetObjects | %{

# Get the sheet's contents
$sheet = gc $_.Name | ConvertFrom-Json

# Get the sheet metadata from Qlik SaaS; used to determine it's state (base / community / private)
$sheetId = $sheet.qProperty.qInfo.qId
$sheetLayout = qlik app object layout $sheetId -a $appId | ConvertFrom-Json
$sheetPublished = $sheetLayout.qMeta.published
$sheetApproved = $sheetLayout.qMeta.approved

<#
If the sheet is a base sheet, then move it to the objects directory (the
base contents of an app)
If the sheet is a community sheet, then move it to the community sheets
directory
If the sheet is a private sheet, then move it to the private sheets
directory
#>
IF($sheetApproved -eq $true -and $sheetPublished -eq $true) {

# BASE sheet
Move-Item $_.Name -Destination "$($backupLocation)\$backupAppDirName-$backupDate\objects"
} ELSEIF ($sheetApproved -eq $false -and $sheetPublished -eq $true) {

# COMMUNITY sheet
# Add note of who originally owned the sheet
$sheet.qProperty.qMetaDef.description = "Originally owned by
$($sheetLayout.qMeta.owner)" + "$($sheet.qProperty.qMetaDef.description)"

# Save the sheet with the new ownership
$sheet | ConvertTo-Json -Depth 100 | Out-File $($_.Name) -Encoding Ascii - Force
Move-Item $_.Name -Destination "$($backupLocation)\$backupAppDirName-$backupDate\sheets-community"
} ELSEIF ($sheetApproved -eq $false -and $sheetPublished -eq $false) {

# PRIVATE sheet
Move-Item $_.Name -Destination "$($backupLocation)\$backupAppDirName-$backupDate\sheets-private"
} ELSE {
Write-Host "Sheet $($sheet.qMeta.title) is an UNCLASSIFIED sheet"
}
}
# Remove the temporary directory
Set-Location "$($backupLocation)"
Remove-Item -Path $tmp -Recurse -Force