if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
try {
    & "$env:windir\system32\UsoClient.exe" StartScan 2>&1 | Out-Null
    & "$env:windir\system32\wuauclt.exe" 2>&1 | Out-Null
    sc query wuauserv 2>&1 | Out-Null
    & "$env:windir\system32\wuauclt.exe" /detectnow 2>&1 | Out-Null
    $au = New-Object -ComObject Microsoft.Update.AutoUpdate
    $au.DetectNow()
} catch { exit 1 }
try {
    $ErrorActionPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-PackageProvider -Name NuGet -Force -Confirm:$false
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    }
    Import-Module PSWindowsUpdate
    Add-WUServiceManager -ServiceID '7971f918-a847-4430-9279-4a52d1efe18d' -Confirm:$false
    $retry = 0
    while ($retry -lt 3) {
        $updates = Install-WindowsUpdate -AcceptAll -UpdateType Driver -MicrosoftUpdate -ForceDownload -ForceInstall -IgnoreReboot -ErrorAction SilentlyContinue
        if ($updates -eq $null -or $updates.Count -eq 0) { break }
        $retry++
    }
    winget upgrade --all --include-unknown --include-pinned --force --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    & "$env:windir\system32\UsoClient.exe" ScanInstallWait 2>&1 | Out-Null
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result = $searcher.Search('IsInstalled=0 and Type=''Software''')
    $updates = $result.Updates
    if ($updates.Count -gt 0) {
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $updates
        $downloader.Download()
        $installer = New-Object -ComObject Microsoft.Update.Installer()
        $installer.Updates = $updates
        $installer.Install()
    }
    reg query "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy\VerifiedAndReputablePolicyState" /v Enabled 2>&1 | Out-Null
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2>&1 | Out-Null
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" 2>&1 | Out-Null
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" 2>&1 | Out-Null
    reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations" 2>&1 | Out-Null
} catch { exit 1 }
exit 0
