#Chandler Hooley - 04/04/23
#Disclamer: This command only works with OBS V.28 (tested) or later OR with OBS-Websocket v.5 or later (untested, but should work)
#ALSO NOTE: sources need to be formatted as the code calls for (make sure there is correct capitalization as well): song1File song2File song3File song4File song5File

Install-Module obs-powershell
Import-Module obs-powershell -PassThru -Force


# Connect to OBS Studio
Connect-OBS -WebSocketUri "ws://127.0.0.1:4455" -WebSocketToken "iforgot"

#Example Filepath: "C:\Users\chand\Videos\OBS_V\LCG_Hymnal\TV\1.mp4"


#*** IF YOU NEED TO CHANGE THE FILEPATH:  REPLACE BETWEEN QUOTATION MARKS BELOW ***


$File_Path_V1 = "C:\Users\chand\Videos\OBS_V\LCG_Hymnal\TV\"


$sONEs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #1 Page Number:", "OBS Setup")

$sONE = [int]$sONEs

#031921

Set-OBSInputSettings -InputName "song1File" -InputSettings @{

    local_file=($File_Path_V1 + $sONE + '.mp4')
}






$sTWOs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #2 Page Number:", "OBS Setup")

$sTWO = [int]$sTWOs

#122503

Set-OBSInputSettings -InputName "song2File" -InputSettings @{

    local_file=($File_Path_V1 + $sTWO + '.mp4')
}




$sTHREEs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #2 Page Number:", "OBS Setup")

$sTHREE = [int]$sTHREEs

Set-OBSInputSettings -InputName "song3File" -InputSettings @{

    local_file=($File_Path_V1 + $sTHREE + '.mp4')
}




$sFOURs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #4 Page Number:", "OBS Setup")

$sFOUR = [int]$sFOURs

Set-OBSInputSettings -InputName "song4File" -InputSettings @{

    local_file=($File_Path_V1 + $sFOUR + '.mp4')
}




$sFIVEs = [Microsoft.VisualBasic.Interaction]::InputBox("Song #5 Page Number:", "OBS Setup")

$sFIVE = [int]$sFIVEs

Set-OBSInputSettings -InputName "song5File" -InputSettings @{

    local_file=($File_Path_V1 + $sFIVE + '.mp4')
}


# Disconnect from OBS Studio
Disconnect-OBS


Disconnect-OBS