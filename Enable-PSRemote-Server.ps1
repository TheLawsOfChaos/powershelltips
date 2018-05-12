########################################################################
################ Do this on the Server
########################################################################
Enable-PSRemoting -SkipNetworkProfileCheck -Force

$ComputerName = $env:computername

#Remove HTTP Listeners
Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTP" | Remove-Item -Recurse
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

mkdir C:\temp
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $ComputerName
Export-Certificate -Cert $Cert -FilePath C:\temp\cert

# Set up WinRM HTTPS listener
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force
New-NetFirewallRule -DisplayName 'Windows Remote Management (HTTPS-In)' -Name 'Windows Remote Management (HTTPS-In)' -Profile Any -LocalPort 5986 -Protocol TCP
New-NetFirewallRule -DisplayName "RemotePowerShell" -Direction Inbound –LocalPort 5985-5986 -Protocol TCP -Action Allow

# Copy the cert file to the local PC and run commands below with admin privileges
Import-Certificate -Filepath 'C:\temp\cert' -CertStoreLocation 'Cert:\LocalMachine\Root'

# Skip Certification Authority (CA) check
$so = New-PsSessionOption –SkipCACheck

# Establish a POSH Remoting session to test
Enter-PSSession -Computername $ComputerName -Credential (Get-Credential) -UseSSL -SessionOption $so

# Enable delegation of credentials
Enable-WSManCredSSP -Role Server -Force

Restart-Service winrm

 
 