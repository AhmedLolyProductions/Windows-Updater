@echo off
setlocal

net file 1>nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Set UAC = CreateObject("Shell.Application") > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs" 2>nul
    exit /b
)

if exist "%windir%\system32\UsoClient.exe" (
  "%windir%\system32\UsoClient.exe" StartScan >nul 2>&1
) else if exist "%windir%\system32\wuauclt.exe" (
  sc query wuauserv >nul 2>&1
  if %ERRORLEVEL%==0 (
    net stop wuauserv >nul 2>&1
    net start wuauserv >nul 2>&1
  )
  "%windir%\system32\wuauclt.exe" /detectnow >nul 2>&1
) else (
  where /q powershell.exe >nul 2>&1
  if %ERRORLEVEL%==0 (
    powershell -NoProfile -Command "Try { $au = New-Object -ComObject Microsoft.Update.AutoUpdate; $au.DetectNow(); exit 0 } Catch { exit 1 }" >nul 2>&1
  )
)

where /q powershell.exe >nul 2>&1
if %ERRORLEVEL%==0 (
  powershell -NoProfile -Command "if not (Get-Module -ListAvailable -Name PSWindowsUpdate) { Install-PackageProvider -Name NuGet -Force -Confirm:$false; Install-Module -Name PSWindowsUpdate -Force -Confirm:$false }; Import-Module PSWindowsUpdate; Add-WUServiceManager -ServiceID '7971f918-a847-4430-9279-4a52d1efe18d' -Confirm:$false; Install-WindowsUpdate -AcceptAll -UpdateType Driver -MicrosoftUpdate -ForceDownload -ForceInstall -IgnoreReboot -ErrorAction SilentlyContinue"
)

where /q winget.exe >nul 2>&1
if %ERRORLEVEL%==0 (
  winget upgrade --all --accept-package-agreements --accept-source-agreements --force
)

endlocal
exit /b 0
