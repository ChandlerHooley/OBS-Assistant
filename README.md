# Intro:
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


# Prerequisites:
The prerequisites for this tool to work are as follows:
You must have OBS v.28 or above for this to work OR OBS-WebSocket v.5 
or above.

The OBS Websocket server should be (A) enabled and (B) have a server password of:
iforgot

It should be noted that this is requiring the format of the MP4 files 
to be in numerical value only, no other words or dashes or anything

The OBS Sources need to be formatted as follows:
song1File
song2File
song3File
song4File
song5File
sermonetteFile
sermonFile

The following 3 folders should exist on the desktop:
1. Hymns
2. Sermonettes
3. Sermons

You must have the numeric version of the Hymnal MP4 files (in the Hymns folder on the desktop)


# Setup:
1. Go to the version 2 release and download the .ps1 and the .cmd file
2. Put the .ps1 file at the root of the C drive
3. Put the .cmd file on the desktop


# Usage
After setup, you can double click the cmd file on the desktop and it will run the tool.
