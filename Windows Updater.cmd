@echo off
setlocal

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

where /q winget.exe >nul 2>&1
if %ERRORLEVEL%==0 (
  winget upgrade --all --accept-package-agreements --accept-source-agreements --force
)

endlocal
exit /b 0