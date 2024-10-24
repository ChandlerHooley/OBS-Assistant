This is a simple app built for OBS to use powershell to manually
set Media Source files that are on the computer. It is 
specifically designed to give an option for the user to list hymns
that will be played during a church service. The user can then 
enter the hymn number, then powershell will check to make sure that 
hymn is in the folder of hymns, and then it will program it into the 
media source of OBS. After that, it will also grab a video sermonette 
and sermon from a specefied folder into their respective Media Sources.
Finally, it will put a fullscreen projector onto the second monitor.
This has the use case of wanting to play the hymns video on a 
projector that may be in the hall, and needs the video on it.


The instructions for setup are as follows:
You must have OBS v.28 or above for this to work OR OBS-WebSocket v.5 
or above.

You need to have powershell 7 installed. [Install From Microsoft Here] (https://github.com/PowerShell/PowerShell/releases/download/v7.3.4/PowerShell-7.3.4-win-x64.msi)

It should be noted that this is requiring the format of the MP4 files 
to be in numerical value only, no other words or dashes or anything

The OBS Sources need to be formatted as follows:
song1File
song2File
song3File
song4File
song5File

You must have the numeric version of the Hymnal MP4 files.

To set this up as an executable file do the following:

Step 1. Install the OBS Song Loader PS1 file and move it to a place 
you will remember in your files.

Step 2. On your desktop, right click and create a new shortcut and 
then copy and paste the following command into the 
"Location of the item" INCLUDING THE QUOTATION MARKS.

"C:\Program Files\PowerShell\7\pwsh.exe" -ExecutionPolicy Bypass -File "C:\OBS.Song.Loader.ps1"

Step 3. You shouldn't have to change this at all if you put the
PS1 file you downloaded earlier in the base C Drive. BUT if 
you put it somewhere else, replace the second filepath 
(between the second set of quotation marks) with where you have 
it saved.

Step 3a. You shouldn't have to do this either, but if for some 
reason you downloaded powershell 7 to a different spot, or if 
your main hard drive is something other than "C:", you will 
need to replace the first filepath (the first set of quotation 
marks) with the Powershell 7 "pwsh.exe" file. You should be 
able to follow and find it by following the filepath (i.e. 
Going to program files, then to Powershell, then to 7, then 
find the "pwsh.exe" file)
