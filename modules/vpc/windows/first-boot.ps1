$Password = ConvertTo-SecureString '${vm_admin_pass}' –asplaintext –force 
$UserAccount = Get-LocalUser -Name "Administrator"
$UserAccount | Set-LocalUser -Password $Password
