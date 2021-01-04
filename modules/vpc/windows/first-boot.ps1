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
LogWrite "Script file: " $PSScriptRoot

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
LogWrite "clone repo"
#get keys from repo
Start-Process `
  -FilePath "$env:ProgramFiles\git\bin\git.exe" `
  -Wait `
  -WorkingDirectory $env:temp `
  -ArgumentList "clone https://github.com/metall773/e-keys.git"

LogWrite "------------------------------------------------"
LogWrite "Install openssh service"
$file = "$env:temp\e-keys\scripts\openssh_install.ps1"
powershell.exe -ExecutionPolicy ByPass -File $file

LogWrite "------------------------------------------------"
LogWrite "Init done"
LogWrite "user_data http://169.254.169.254/openstack/latest/user_data"
LogWrite "metadata http://169.254.169.254/openstack/latest/meta_data.json"
LogWrite "------------------------------------------------"