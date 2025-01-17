$ErrorActionPreference = "stop"
$username = "Administrator"

# Temporary random password to allow autologon that will be replaced
# before the instance is put into service.
$syms = [char[]]([char]'a'..[char]'z'  `
               + [char]'A'..[char]'Z'  `
               + [char]'0'..[char]'9')
$rnd = [byte[]]::new(32)
[System.Security.Cryptography.RandomNumberGenerator]::create().
                                                      getBytes($rnd)
$password = ($rnd | % { $syms[$_ % $syms.length] }) -join ''

$encPass = ConvertTo-SecureString $password -AsPlainText -Force
Set-LocalUser -Name $username -Password $encPass

$winLogon= "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $winLogon "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty $winLogon "DefaultUsername" -Value $username -type String 
Set-ItemProperty $winLogon "DefaultPassword" -Value $password -type String

# Lock the screen immediately, even though it's unattended, just in case
Set-ItemProperty `
    -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run `
    -Name LockScreen -Value "rundll32.exe user32.dll,LockWorkStation" `
    -Type String

# NOTE: For now, we do not run sysprep, since initialization with reboots
# are exceptionally slow on metal nodes, which these target to run. This
# will lead to a duplicate machine id, which is not ideal, but allows
# instances to start instantly. So, instead of sysprep, trigger a reset so
# that the admin password reset, and activation rerun on boot
& 'C:\Program Files\Amazon\EC2Launch\ec2launch' reset --block
