# Windows Update Diagnostic Suite - Uninstaller
# Target: https://github.com/09sychic/DevilCamUpdated

$Dir = "$env:LOCALAPPDATA\WinUpdateDiagnostic"
$Lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateAssistant.lnk"

Write-Host "Stopping background diagnostic services..." -ForegroundColor Yellow

# 1. Kill the specific PowerShell process running the service
$ServicePID = Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*UpdateAuditService.ps1*" } | Select-Object -ExpandProperty ProcessId
if ($ServicePID) {
    Stop-Process -Id $ServicePID -Force -ErrorAction SilentlyContinue
    Write-Host "Background process terminated."
}

# 2. Remove the Startup Shortcut
if (Test-Path $Lnk) {
    Remove-Item $Lnk -Force
    Write-Host "Startup trigger removed."
}

# 3. Purge the hidden data directory
if (Test-Path $Dir) {
    # Remove hidden attribute first to ensure clean deletion
    attrib -h $Dir
    Remove-Item -Recurse -Force $Dir
    Write-Host "Hidden directory purged."
}

Write-Host "Uninstallation successful. System is clean." -ForegroundColor Green