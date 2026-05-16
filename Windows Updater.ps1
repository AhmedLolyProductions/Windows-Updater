& "$env:windir\system32\UsoClient.exe" StartScan
Get-Service wuauserv -ErrorAction SilentlyContinue | Start-Service -ErrorAction SilentlyContinue
Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
Install-Module -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue
Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
Add-WUServiceManager -ServiceID '7971f918-a847-4430-9279-4a52d1efe18d' -Confirm:$false
Get-WindowsUpdate -AcceptAll -Install -MicrosoftUpdate -ErrorAction SilentlyContinue
winget upgrade --all --force --accept-package-agreements --accept-source-agreements --silent
& "$env:windir\system32\UsoClient.exe" ScanInstallWait
