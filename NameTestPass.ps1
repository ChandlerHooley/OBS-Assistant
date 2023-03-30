# Ask user for video name
$video_name = Read-Host "Enter video name"

# Get video file path
$video_path = "C:\Users\chand\Videos\OBS_V\LCG_Hymnal\TV\$video_name.mp4"

# Check if file exists
if (Test-Path $video_path) {
    # Get VLC executable path
    $vlc_path = "C:\Program Files\VideoLAN\VLC\vlc.exe"

    # Start VLC with video file
    Start-Process -FilePath $vlc_path -ArgumentList $video_path
}
else {
    # Show error
    Write-Error "Video not found"
}