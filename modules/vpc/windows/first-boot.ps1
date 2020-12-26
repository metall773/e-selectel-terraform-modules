#ps1

$logFile = 'c:\init-log.txt'

Function LogWrite
{
  Param ([string]$log1, [string]$log2, [string]$log3, [string]$log4,  [string]$log5)
  $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
  $line = "$stamp $log1 $log2 $log3 $log4 $log5"
  Write-host $line
  Add-content $logFile -value $Line
}

$Password = ConvertTo-SecureString '${vm_admin_pass}' –asplaintext –force 
$UserAccount = Get-LocalUser -Name "Administrator"
$UserAccount | Set-LocalUser -Password $Password

LogWrite "------------------------------------------------"
LogWrite "Script start"
LogWrite "Runtime parameters:"


LogWrite "------------------------------------------------"
LogWrite "Set TimeZone Russia TZ 2 Standard Time"

Set-TimeZone -Name "Russia TZ 2 Standard Time"

$choco_list="7zip putty notepadplusplus git googlechrome ublockorigin-chrome chocolateygui"
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
  } 
  else {
    LogWrite "No choco packages listed for install, skip..."
  }

LogWrite "------------------------------------------------"
LogWrite "Init done"