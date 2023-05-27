#Chandler Hooley - 05/26/23
#Disclamer: This command only works with OBS V.28 (tested) or later OR with OBS-Websocket v.5 or later (untested, but should work)
#ALSO NOTE: sources need to be formatted as the code calls for (make sure there is correct capitalization as well): 
#       song1File song2File song3File song4File song5File sermonetteFile sermonFile

Install-Module obs-powershell
Import-Module obs-powershell -PassThru -Force


# Connect to OBS Studio
Connect-OBS -WebSocketUri "ws://127.0.0.1:4455" -WebSocketToken "iforgot"

#Example Filepath: "C:\Users\chand\Videos\OBS_V\LCG_Hymnal\TV\1.mp4"


#*** IF YOU NEED TO CHANGE THE FILEPATHs:  REPLACE BETWEEN QUOTATION MARKS BELOW ***

$File_Path_V1 = "C:\Users\chand\Videos\OBS_V\LCG_Hymnal\TV\"
$File_Path_V2 = "C:\Users\chand\Desktop\"

#song 1
do {

$sONEs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #1 Page Number:", "OBS Setup")

$sONE = [int]$sONEs

#031921

Set-OBSInputSettings -InputName "song1File" -InputSettings @{

    local_file=($File_Path_V1 + $sONE + '.mp4')
}

} until (Test-Path ($File_Path_V1 + $sONE + '.mp4'))


#song 2
do {

$sTWOs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #2 Page Number:", "OBS Setup")

$sTWO = [int]$sTWOs

#122503

Set-OBSInputSettings -InputName "song2File" -InputSettings @{

    local_file=($File_Path_V1 + $sTWO + '.mp4')
}

} until (Test-Path ($File_Path_V1 + $sTWO + '.mp4'))


#song 3
do {

$sTHREEs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #2 Page Number:", "OBS Setup")

$sTHREE = [int]$sTHREEs

Set-OBSInputSettings -InputName "song3File" -InputSettings @{

    local_file=($File_Path_V1 + $sTHREE + '.mp4')
}

} until (Test-Path ($File_Path_V1 + $sTHREE + '.mp4'))


#song 4
do {

    $sFOURs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #4 Page Number:", "OBS Setup")

    $sFOUR = [int]$sFOURs

    Set-OBSInputSettings -InputName "song4File" -InputSettings @{

        local_file=($File_Path_V1 + $sFOUR + '.mp4')
    }

} until (Test-Path ($File_Path_V1 + $sFOUR + '.mp4'))


#song 5
do {

    $sFIVEs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #5 Page Number:", "OBS Setup")

    $sFIVE = [int]$sFIVEs

    Set-OBSInputSettings -InputName "song5File" -InputSettings @{

        local_file=($File_Path_V1 + $sFIVE + '.mp4')
    }

} until (Test-Path ($File_Path_V1 + $sFIVE + '.mp4'))






#Sermonette Loader
$folderPath = ($File_Path_V2 + "Sermonettes")

$mostRecentFile = Get-ChildItem -Path $folderPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($mostRecentFile) {
    $filePath = $mostRecentFile.FullName
    
    $filePath
    Set-OBSInputSettings -InputName "sermonetteFile" -InputSettings @{

        local_file=($filePath)
    }

} else {
    Write-Host "No sermonettes found in the folder."
}



#Sermonette Loader
$folderPath = ($File_Path_V2 + "Sermons")

$mostRecentFile = Get-ChildItem -Path $folderPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($mostRecentFile) {
    $filePath = $mostRecentFile.FullName
    
    $filePath
    Set-OBSInputSettings -InputName "sermonFile" -InputSettings @{

        local_file=($filePath)
    }

} else {
    Write-Host "No files found in the folder."
}


Open-OBSVideoMixProjector -VideoMixType OBS_WEBSOCKET_VIDEO_MIX_TYPE_PROGRAM -MonitorIndex 1
#If studio mode is enabled, make sure command above has PROGRAM (replace PREVIEW).
#If studio mode is disabled, make sure command above has PREVIEW (replace PROGRAM).
#Monitor number may need to be changed.


# Disconnect from OBS Studio
Disconnect-OBS


Disconnect-OBS