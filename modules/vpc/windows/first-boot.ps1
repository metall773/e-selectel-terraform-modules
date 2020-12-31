#ps1_sysnative

$logFile = 'c:\init-log.txt'

Function LogWrite
{
  Param ([string]$log1, [string]$log2, [string]$log3, [string]$log4,  [string]$log5)
  $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
  $line = "$stamp $log1 $log2 $log3 $log4 $log5"
  Write-host $line
  Add-content $logFile -value $Line
}

LogWrite "------------------------------------------------"
LogWrite "Script start"
LogWrite "Runtime parameters:"
LogWrite "Script file: " $PSScriptRoot

LogWrite "------------------------------------------------"
LogWrite "Get Metadata"
$user_data = Invoke-RestMethod -Uri http://169.254.169.254/openstack/latest/user_data  -Method Get
$meta_data = Invoke-RestMethod -Uri http://169.254.169.254/openstack/latest/meta_data.json  -Method Get
LogWrite $user_data
LogWrite $meta_data

LogWrite "------------------------------------------------"
LogWrite "Set TimeZone Russia TZ 2 Standard Time"

Set-TimeZone -Name "Russia TZ 2 Standard Time"

$choco_list="${install_packages}"
#install choco packages
if ( $choco_list -ne "" ) {
    LogWrite "Install choco packages:"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $down = New-Object System.Net.WebClient
    
    iex ($down.DownloadString('https://chocolatey.org/install.ps1'))
    choco feature enable -n allowGlobalConfirmation 
    $choco_list.Split() |ForEach-Object { 
      LogWrite "     Installing " $_
      choco install $_ -y
    } 
  } else {
    LogWrite "No choco packages listed for install, skip..."
  }

LogWrite "------------------------------------------------"
LogWrite "Install openssh service"
$file = "$env:ProgramFiles\OpenSSH-Win64\install-sshd.ps1"
powershell.exe -ExecutionPolicy ByPass -File $file
Set-Service sshd -StartupType Automatic
Start-Service -Name sshd

#remove 2 last line from config
$sshd_config=@"
AuthenticationMethods   publickey
AuthorizedKeysFile      .ssh/authorized_keys
Subsystem       sftp    sftp-server.exe
# Logging
SyslogFacility AUTH
LogLevel DEBUG
"@
Set-Content "$env:ProgramData\ssh\sshd_config" -Value $sshd_config

Restart-Service -Name sshd

#firewall allow 22 tcp connection
New-NetFirewallRule `
  -Name sshd -DisplayName 'OpenSSH Server (sshd)' `
  -Enabled True `
  -Direction Inbound `
  -Protocol TCP `
  -Action Allow `
  -LocalPort 22

#add ssh keys
$ssh_user="Administrator"
New-Item -ItemType Directory -Force -Path "C:\Users\$ssh_user\.ssh"

#change defaul shell to powershell
New-ItemProperty `
  -Path "HKLM:\SOFTWARE\OpenSSH" `
  -Name "DefaultShell" `
  -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -PropertyType String `
  -Force

#get keys from repo
Start-Process -FilePath "$env:ProgramFiles\git\bin\git.exe" -Wait -WorkingDirectory $env:temp -ArgumentList "clone https://github.com/metall773/e-keys.git"
Get-Content "$env:temp\e-keys\*.pub" | Set-Content "C:\Users\$ssh_user\.ssh\authorized_keys"
Remove-Item –path "$env:temp\e-keys" -Force -Recurse

#set key file acl
$acl = Get-Acl "C:\Users\$ssh_user\.ssh\authorized_keys"
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
$acl | Set-Acl

LogWrite "------------------------------------------------"
LogWrite "Init done"
LogWrite "user_data http://169.254.169.254/openstack/latest/user_data"
LogWrite "metadata http://169.254.169.254/openstack/latest/meta_data.json"
LogWrite "------------------------------------------------"
LogWrite "Install windows update..."
usoclient StartScan