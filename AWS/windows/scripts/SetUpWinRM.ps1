<powershell>

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse
Set-Item WSMan:\localhost\MaxTimeoutms 1800000
Set-Item WSMan:\localhost\Service\Auth\Basic $true

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5986 "Port 5986"
# WinRS Tweaks
Set-Item WSMan:\localhost\Shell\MaxConcurrentUsers 100
set-item WSMan:\localhost\Shell\MaxProcessesPerShell 10000
set-item WSMan:\localhost\Shell\MaxMemoryPerShellMB 7500
set-item WSMan:\localhost\Shell\MaxShellsPerUser 1000
# PowerShell Plugin Tweaks
Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxConcurrentUsers 100
Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxProcessesPerShell 10000
Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxShells 1000
Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxShellsPerUser 1000
# Auto Startup & Restart
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm

# Pagefile
cmd.exe /c --% reg add "hklm\system\currentcontrolset\control\session manager\memory management" /v pagingfiles /t reg_multi_sz /d "D:\pagefile.sys 8912 8912" /f
</powershell>
<persist>true</persist>
