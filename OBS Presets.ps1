# OBS Presets 2.0 - Chandler Hooley - 11/02/26
#
# Runs on the Windows PowerShell 5.1 that is built into Windows 10 and 11.
# Nothing to install: no PowerShell 7 and no obs-powershell module. It talks to
# OBS directly over the OBS WebSocket (OBS 28 or later, WebSocket v5).
#
# Start it with "Start OBS Presets.cmd" (keep both files in the same folder).
#
# OBS source names must match exactly, including capitalization:
#       song1File song2File song3File song4File song5File sermonetteFile sermonFile

# ============================================================================
#  SETTINGS - change these if a computer is set up differently
# ============================================================================

$DesktopFolder    = [Environment]::GetFolderPath('Desktop')
$HymnFolder       = Join-Path $DesktopFolder 'Hymns'
$SermonetteFolder = Join-Path $DesktopFolder 'Sermonettes'
$SermonFolder     = Join-Path $DesktopFolder 'Sermons'

$ObsUri           = 'ws://127.0.0.1:4455'
$ObsPassword      = 'iforgot'     # OBS > Tools > WebSocket Server Settings > Show Connect Info

$ProjectorMonitor = 1             # Monitor number for the fullscreen projector (may need changing)
# Studio Mode ON  -> OBS_WEBSOCKET_VIDEO_MIX_TYPE_PROGRAM
# Studio Mode OFF -> OBS_WEBSOCKET_VIDEO_MIX_TYPE_PREVIEW
$ProjectorMix     = 'OBS_WEBSOCKET_VIDEO_MIX_TYPE_PROGRAM'

$HymnCount        = 5
# ============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ----------------------------------------------------------------------------
#  OBS WebSocket (v5) - minimal client, no extra modules needed
# ----------------------------------------------------------------------------
function Send-ObsMessage {
    param($Socket, $Message)
    $json  = $Message | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $segment = New-Object 'System.ArraySegment[byte]' -ArgumentList (,$bytes)
    $task = $Socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None)
    if (-not $task.Wait(5000)) { throw 'Timed out sending to OBS.' }
}

function Receive-ObsMessage {
    param($Socket, [int]$TimeoutMs = 10000)
    $buffer = New-Object byte[] 65536
    $stream = New-Object System.IO.MemoryStream
    do {
        $segment = New-Object 'System.ArraySegment[byte]' -ArgumentList (,$buffer)
        $task = $Socket.ReceiveAsync($segment, [System.Threading.CancellationToken]::None)
        if (-not $task.Wait($TimeoutMs)) { throw 'Timed out waiting for OBS to answer.' }
        $result = $task.Result
        if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
            throw ("OBS closed the connection (code {0}). {1}" -f [int]$Socket.CloseStatus, $Socket.CloseStatusDescription)
        }
        $stream.Write($buffer, 0, $result.Count)
    } while (-not $result.EndOfMessage)
    $json = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
    return ($json | ConvertFrom-Json)
}

function Get-Sha256Base64 {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try   { return [Convert]::ToBase64String($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))) }
    finally { $sha.Dispose() }
}

function Connect-ObsSocket {
    param([string]$Uri, [string]$Password)
    $socket = New-Object System.Net.WebSockets.ClientWebSocket
    try {
        $task = $socket.ConnectAsync([Uri]$Uri, [System.Threading.CancellationToken]::None)
        if (-not $task.Wait(5000)) { throw 'timeout' }
    } catch {
        $socket.Dispose()
        throw ("Could not connect to OBS at $Uri.`n`n" +
               "Make sure OBS is open and the WebSocket server is turned on " +
               "(OBS > Tools > WebSocket Server Settings > Enable WebSocket server).")
    }

    # OBS says Hello (op 0); we Identify (op 1); OBS confirms with Identified (op 2)
    $hello = Receive-ObsMessage -Socket $socket
    $identify = @{ rpcVersion = 1; eventSubscriptions = 0 }
    if ($hello.d.authentication) {
        $secret = Get-Sha256Base64 ($Password + $hello.d.authentication.salt)
        $identify.authentication = Get-Sha256Base64 ($secret + $hello.d.authentication.challenge)
    }
    Send-ObsMessage -Socket $socket -Message @{ op = 1; d = $identify }

    try {
        $reply = Receive-ObsMessage -Socket $socket
    } catch {
        if ([int]$socket.CloseStatus -eq 4009) {
            throw 'OBS rejected the WebSocket password. Update $ObsPassword at the top of the script.'
        }
        throw
    }
    if ($reply.op -ne 2) { throw 'OBS did not accept the connection.' }
    return $socket
}

function Invoke-ObsRequest {
    param($Socket, [string]$RequestType, $RequestData)
    $id = [guid]::NewGuid().ToString()
    $d = @{ requestType = $RequestType; requestId = $id }
    if ($null -ne $RequestData) { $d.requestData = $RequestData }
    Send-ObsMessage -Socket $Socket -Message @{ op = 6; d = $d }

    while ($true) {
        $msg = Receive-ObsMessage -Socket $Socket
        if ($msg.op -eq 7 -and $msg.d.requestId -eq $id) {
            if (-not $msg.d.requestStatus.result) {
                throw ("OBS could not do '{0}': {1} (code {2})" -f $RequestType, $msg.d.requestStatus.comment, $msg.d.requestStatus.code)
            }
            return $msg.d.responseData
        }
    }
}

function Disconnect-ObsSocket {
    param($Socket)
    if ($null -eq $Socket) { return }
    try {
        if ($Socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            [void]$Socket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'Done', [System.Threading.CancellationToken]::None).Wait(2000)
        }
    } catch { }
    $Socket.Dispose()
}

# ----------------------------------------------------------------------------
#  File helpers
# ----------------------------------------------------------------------------
# Returns State = Blank | Found | Missing, plus the file path when found.
function Resolve-Hymn {
    param([string]$Text)
    $entry = $Text.Trim()
    if ($entry -match '(?i)\.mp4$') { $entry = $entry.Substring(0, $entry.Length - 4).Trim() }
    if ($entry -eq '') { return [pscustomobject]@{ State = 'Blank'; Entry = ''; Path = '' } }

    $candidates = @($entry)
    if ($entry -match '^\d+$') { $candidates += [string][int64]$entry }   # "07" also tries "7"

    foreach ($name in $candidates) {
        try {
            $path = Join-Path $HymnFolder ($name + '.mp4')
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                return [pscustomobject]@{ State = 'Found'; Entry = $entry; Path = $path }
            }
        } catch { }   # characters that can't be in a file name = not found
    }
    return [pscustomobject]@{ State = 'Missing'; Entry = $entry; Path = '' }
}

function Get-LatestVideo {
    param([string]$Folder)
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) { return $null }
    return Get-ChildItem -LiteralPath $Folder -Filter '*.mp4' -File |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

# ----------------------------------------------------------------------------
#  Window
# ----------------------------------------------------------------------------
$cBackground = [System.Drawing.Color]::FromArgb(245, 247, 250)
$cHeader     = [System.Drawing.Color]::FromArgb(31, 42, 68)
$cHeaderSub  = [System.Drawing.Color]::FromArgb(190, 200, 220)
$cAccent     = [System.Drawing.Color]::FromArgb(0, 103, 192)
$cAccentDark = [System.Drawing.Color]::FromArgb(0, 84, 158)
$cText       = [System.Drawing.Color]::FromArgb(32, 32, 32)
$cMuted      = [System.Drawing.Color]::FromArgb(100, 108, 118)
$cGood       = [System.Drawing.Color]::FromArgb(16, 124, 16)
$cBad        = [System.Drawing.Color]::FromArgb(196, 43, 28)
$cBadFill    = [System.Drawing.Color]::FromArgb(253, 231, 233)

function New-Font {
    param([single]$Size, [string]$Family = 'Segoe UI', [System.Drawing.FontStyle]$Style = 'Regular')
    return New-Object System.Drawing.Font($Family, $Size, $Style)
}

function New-Label {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H, $Font, $Color, $Parent)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.Location = New-Object System.Drawing.Point($X, $Y)
    $l.Size = New-Object System.Drawing.Size($W, $H)
    $l.Font = $Font
    $l.ForeColor = $Color
    $l.BackColor = [System.Drawing.Color]::Transparent
    $Parent.Controls.Add($l)
    return $l
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'OBS Presets'
$form.ClientSize = New-Object System.Drawing.Size(520, 700)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = $cBackground
$form.Font = New-Font 10

# Header band
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(520, 92)
$header.BackColor = $cHeader
$form.Controls.Add($header)
[void](New-Label 'Service Setup' 22 14 470 40 (New-Font 20 'Segoe UI Semibold') ([System.Drawing.Color]::White) $header)
[void](New-Label 'Type the hymn numbers, then click Load into OBS.' 24 56 470 24 (New-Font 10) $cHeaderSub $header)

# Hymns
[void](New-Label 'HYMNS' 24 108 200 20 (New-Font 9 'Segoe UI' 'Bold') $cMuted $form)

$HymnBoxes  = @()
$HymnStatus = @()
for ($i = 0; $i -lt $HymnCount; $i++) {
    $y = 134 + ($i * 58)
    [void](New-Label ("Hymn {0}" -f ($i + 1)) 24 ($y + 9) 90 30 (New-Font 13) $cText $form)

    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Location = New-Object System.Drawing.Point(120, $y)
    $tb.Size = New-Object System.Drawing.Size(120, 44)
    $tb.Font = New-Font 20
    $tb.TextAlign = 'Center'
    $tb.MaxLength = 12
    $tb.Tag = $i
    $tb.TabIndex = $i
    $form.Controls.Add($tb)
    $HymnBoxes += $tb

    $HymnStatus += (New-Label '' 256 ($y + 11) 240 28 (New-Font 11) $cMuted $form)
}

function Update-HymnRow {
    param([int]$Index)
    $box = $script:HymnBoxes[$Index]
    $status = $script:HymnStatus[$Index]
    $r = Resolve-Hymn $box.Text
    switch ($r.State) {
        'Blank'   { $status.Text = '';                      $box.BackColor = [System.Drawing.Color]::White }
        'Found'   { $status.Text = 'Found';                 $status.ForeColor = $script:cGood; $box.BackColor = [System.Drawing.Color]::White }
        'Missing' { $status.Text = 'Not found in hymn folder'; $status.ForeColor = $script:cBad; $box.BackColor = $script:cBadFill }
    }
    return $r
}

foreach ($tb in $HymnBoxes) {
    $tb.Add_TextChanged({ [void](Update-HymnRow ([int]$this.Tag)) })
}

# Videos (shows which files will be loaded)
[void](New-Label 'VIDEOS (newest .mp4 in each folder)' 24 432 470 20 (New-Font 9 'Segoe UI' 'Bold') $cMuted $form)

function Format-VideoText {
    param($File, [string]$Folder)
    if ($null -eq $File) { return "None found in $Folder" }
    return ("{0}   ({1:ddd MMM d, h:mm tt})" -f $File.Name, $File.LastWriteTime)
}

$Sermonette = Get-LatestVideo $SermonetteFolder
$Sermon     = Get-LatestVideo $SermonFolder

[void](New-Label 'Sermonette' 24 458 470 22 (New-Font 11 'Segoe UI Semibold') $cText $form)
$sermonetteLabel = New-Label (Format-VideoText $Sermonette $SermonetteFolder) 24 480 472 22 (New-Font 10) $cMuted $form
$sermonetteLabel.AutoEllipsis = $true
if ($null -eq $Sermonette) { $sermonetteLabel.ForeColor = $cBad }

[void](New-Label 'Sermon' 24 512 470 22 (New-Font 11 'Segoe UI Semibold') $cText $form)
$sermonLabel = New-Label (Format-VideoText $Sermon $SermonFolder) 24 534 472 22 (New-Font 10) $cMuted $form
$sermonLabel.AutoEllipsis = $true
if ($null -eq $Sermon) { $sermonLabel.ForeColor = $cBad }

# Load button
$loadButton = New-Object System.Windows.Forms.Button
$loadButton.Text = 'Load into OBS'
$loadButton.Location = New-Object System.Drawing.Point(24, 584)
$loadButton.Size = New-Object System.Drawing.Size(472, 58)
$loadButton.Font = New-Font 14 'Segoe UI Semibold'
$loadButton.FlatStyle = 'Flat'
$loadButton.FlatAppearance.BorderSize = 0
$loadButton.FlatAppearance.MouseOverBackColor = $cAccentDark
$loadButton.BackColor = $cAccent
$loadButton.ForeColor = [System.Drawing.Color]::White
$loadButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$loadButton.TabIndex = $HymnCount
$form.Controls.Add($loadButton)
$form.AcceptButton = $loadButton     # Enter key = Load

$statusLabel = New-Label '' 24 652 472 30 (New-Font 10) $cMuted $form
$statusLabel.TextAlign = 'MiddleCenter'

function Set-Status {
    param([string]$Text, $Color = $script:cMuted)
    $script:statusLabel.ForeColor = $Color
    $script:statusLabel.Text = $Text
    $script:form.Refresh()
}

function Show-Message {
    param([string]$Text, [string]$Title,
          [System.Windows.Forms.MessageBoxIcon]$Icon = 'Information',
          [System.Windows.Forms.MessageBoxButtons]$Buttons = 'OK',
          [System.Windows.Forms.MessageBoxDefaultButton]$Default = 'Button1')
    return [System.Windows.Forms.MessageBox]::Show($script:form, $Text, $Title, $Buttons, $Icon, $Default)
}

# ----------------------------------------------------------------------------
#  Load button: check everything first, then program OBS
# ----------------------------------------------------------------------------
$loadButton.Add_Click({
    # 1. Every hymn typed in must exist as a file
    $hymns   = @()
    $missing = @()
    $blank   = @()
    for ($i = 0; $i -lt $script:HymnCount; $i++) {
        $r = Update-HymnRow $i
        $hymns += $r
        if ($r.State -eq 'Missing') { $missing += ("    Hymn {0}:  {1}" -f ($i + 1), $r.Entry) }
        if ($r.State -eq 'Blank')   { $blank   += ($i + 1) }
    }

    if ($missing.Count -gt 0) {
        Set-Status 'Fix the hymns marked in red, then try again.' $script:cBad
        [void](Show-Message ("These hymns could not be found:`n`n" + ($missing -join "`n") +
            "`n`nLooked in:`n$($script:HymnFolder)`n`nCheck the numbers and try again.") 'Hymn not found' 'Error')
        for ($i = 0; $i -lt $script:HymnCount; $i++) {
            if ($hymns[$i].State -eq 'Missing') { $script:HymnBoxes[$i].Focus(); $script:HymnBoxes[$i].SelectAll(); break }
        }
        return
    }

    # 2. Warn (but allow) blanks and missing videos
    $warnings = @()
    if ($blank.Count -gt 0) {
        $warnings += ("Hymn {0} is blank. That OBS source will be cleared." -f ($blank -join ', '))
    }
    $sermonette = Get-LatestVideo $script:SermonetteFolder
    $sermon     = Get-LatestVideo $script:SermonFolder
    if ($null -eq $sermonette) { $warnings += "No sermonette video found. sermonetteFile will be left as it is." }
    if ($null -eq $sermon)     { $warnings += "No sermon video found. sermonFile will be left as it is." }
    if ($warnings.Count -gt 0) {
        $answer = Show-Message (($warnings -join "`n`n") + "`n`nContinue anyway?") 'Please check' 'Warning' 'YesNo' 'Button2'
        if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { Set-Status ''; return }
    }

    # 3. Program OBS
    $script:loadButton.Enabled = $false
    $socket = $null
    try {
        Set-Status 'Connecting to OBS...'
        $socket = Connect-ObsSocket -Uri $script:ObsUri -Password $script:ObsPassword

        # Make sure the sources exist before changing anything
        $needed = @()
        for ($i = 1; $i -le $script:HymnCount; $i++) { $needed += "song${i}File" }
        if ($sermonette) { $needed += 'sermonetteFile' }
        if ($sermon)     { $needed += 'sermonFile' }
        $existing = @((Invoke-ObsRequest $socket 'GetInputList' $null).inputs | ForEach-Object { $_.inputName })
        $absent = @($needed | Where-Object { $existing -cnotcontains $_ })
        if ($absent.Count -gt 0) {
            throw ("OBS is missing these sources (names are case-sensitive):`n`n    " + ($absent -join "`n    ") +
                   "`n`nNothing was changed.")
        }

        for ($i = 0; $i -lt $script:HymnCount; $i++) {
            Set-Status ("Loading hymn {0}..." -f ($i + 1))
            Invoke-ObsRequest $socket 'SetInputSettings' @{
                inputName     = "song$($i + 1)File"
                inputSettings = @{ local_file = $hymns[$i].Path }
            } | Out-Null
        }

        if ($sermonette) {
            Set-Status 'Loading sermonette...'
            Invoke-ObsRequest $socket 'SetInputSettings' @{ inputName = 'sermonetteFile'; inputSettings = @{ local_file = $sermonette.FullName } } | Out-Null
        }
        if ($sermon) {
            Set-Status 'Loading sermon...'
            Invoke-ObsRequest $socket 'SetInputSettings' @{ inputName = 'sermonFile'; inputSettings = @{ local_file = $sermon.FullName } } | Out-Null
        }

        Set-Status 'Opening fullscreen projector...'
        Invoke-ObsRequest $socket 'OpenVideoMixProjector' @{ videoMixType = $script:ProjectorMix; monitorIndex = $script:ProjectorMonitor } | Out-Null

        Disconnect-ObsSocket $socket
        $socket = $null

        Set-Status 'OBS is ready.' $script:cGood
        $loaded = @($hymns | Where-Object { $_.State -eq 'Found' } | ForEach-Object { $_.Entry })
        $summary = "OBS is ready.`n`nHymns: " + ($loaded -join ', ')
        if ($sermonette) { $summary += "`nSermonette: " + $sermonette.Name }
        if ($sermon)     { $summary += "`nSermon: " + $sermon.Name }
        [void](Show-Message $summary 'All set')
        $script:form.Close()
    }
    catch {
        $e = $_.Exception
        while ($e.InnerException) { $e = $e.InnerException }
        $text = $_.Exception.Message
        if ($text -match '^(Exception calling|One or more errors)') { $text = $e.Message }
        Set-Status 'Something went wrong. Nothing else was changed after the error.' $script:cBad
        [void](Show-Message $text 'OBS Presets' 'Error')
    }
    finally {
        Disconnect-ObsSocket $socket
        $script:loadButton.Enabled = $true
    }
})

if (-not (Test-Path -LiteralPath $HymnFolder -PathType Container)) {
    [void][System.Windows.Forms.MessageBox]::Show(
        "The hymn folder was not found:`n`n$HymnFolder`n`nUpdate `$HymnFolder at the top of the script.",
        'OBS Presets', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

$form.Add_Shown({ $script:HymnBoxes[0].Focus() })
[void]$form.ShowDialog()
$form.Dispose()
