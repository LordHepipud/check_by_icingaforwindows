# Check By Icinga for Windows

This repository provides a plugin which can be executed on Linux to remotely connect to a Windows machine, for executing [Icinga for Windows](https://icinga.com/docs/icinga-for-windows/latest/) checks.
For easier usage, the plugin is designed to work as replacement for the `PowerShell Base` CheckCommand, which ensures you do not have to run multiple configurations for your CheckCommands itself, but can simply import this plugin as CheckCommand to services which should be checked by PowerShell remote instead of the Icinga Agent.

## Requirements

* Installed [PowerShell for Linux](https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-linux)
* Configured WinRM service on the Windows machines
* [Icinga for Windows](https://icinga.com/docs/icinga-for-windows/latest/) >=1.8.0 installed on the Windows machines

## Usage

```
Arguments:
  -C, -Command string            The Icinga for Windows command being executed on the target machine
  -WindowsUser string            Username of the remote host
  -WindowsPassword string        Password of the user
  -AuthenticationMethod string   The method PowerShell will try to authenticate: Basic, Credssp, Default, Digest, Kerberos, Negotiate, NegotiateWithImplicitCredential (default 'Negotiate')
  -Server string                 FQDN of the host machine to connect to
  -ConfigurationName string      Specifies a JEA profile the PowerShell session should be created with
```

## Example

```powershell
./check_by_icingaforwindows.ps1 -Server 'windows.example.com' -WindowsUser 'domain\exampleuser' -WindowsPassword 'examplepassword' -C "Use-Icinga -Minimal; Exit-IcingaExecutePlugin -Command 'Invoke-IcingaCheckPartitionSpace' "
[OK] Free Partition Space: 4 Ok
| 'free_space_partition_s'=1855056000000B;;;0;1999841000000 'free_space_partition_i'=799003800000B;;;0;2199021000000 'free_space_partition_c'=442423800000B;;;0;478964400000 'free_space_partition_t'=102553700000B;;;0;107237900000
```

## Installing PowerShell on Linux

You can find a guide on how to install PowerShell on Linux on the [Microsoft Documentation](https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-linux).

## Troubleshooting

On some systems you can run into the below errors, with guides on how to resolve them

### Unspecified GSS failure

Connecting to remote server windows.example.com failed with the following error message : acquiring creds with username only failed Unspecified GSS failure.  Minor code may provide more information SPNEGO cannot find mechanisms to negotiate For more information, see the about_Remote_Troubleshooting Help topic.

**Solution**: Install the package `gssntlmssp` for your distribution

#### RedHat/CentOS/Fedora

```bash
sudo yum install gssntlmssp -y
```

#### Debian/Ubuntu

```bash
sudo apt install gss-ntlmssp -y
```

### WSMan client library was not found

This parameter set requires WSMan, and no supported WSMan client library was found. WSMan is either not installed or unavailable for this system.

**Solution**: Install WSMan by using PowerShell on Linux

```powershell
pwsh -Command 'Install-Module -Name PSWSMan'
sudo pwsh -Command 'Install-WSMan'
```

### NTML authentication not working

MI_RESULT_ACCESS_DENIED is returned while using the plugin

**Solution**: Use `Negotiate` method (which the plugin defaults to) for authentication

## Preparing the Windows machine

By default, WinRM is not enabled, and if enabled, will only allow Kerberos authentication. WinRM can be configured in many ways, to allow connections by HTTP or HTTPs.

Best practice would be to configure WinRM with a TLS certificate, signed by the PKI of the Active Directory domain, and using NTLM auth to access the systems.

Anything you configure via cmd or powershell needs to be run from an administrative shell.

We start with the minimal setup of enabling WinRM and raising the memory limit:

```powershell
winrm quickconfig
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
```

### Setting up a HTTPS / TLS listener

Make sure to install the certificate in the local machine cert store. This example is using PowerShell.

WinRM HTTPS requires a local computer "Server Authentication" certificate with a CN matching the hostname, that is not expired, revoked, or self-signed to be installed.

```powershell
# Find the cert
Get-ChildItem -Path cert:\LocalMachine\My -Recurse;

# Put the thumbprint here or script it otherwise
$CertThumbprint = 'cert_thumbprint';

# Allow PS-Remote configuration
Enable-PSRemoting -SkipNetworkProfileCheck -Force;

# (optional) Disable HTTP transport for PS-Remoting to ensure encryption
Get-ChildItem WSMan:\Localhost\listener | Where-Object Keys -eq "Transport=HTTP" | Remove-Item -Recurse;

# Set the HTTPS Transport with our provided Thumbprint for the SSL certificate
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $CertThumbprint -Force;

# Set Firewall Rule for allowing communication
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" `
  -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP;

# Enable the HTTPS listener
Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true;

# Disable possible old HTTP firewall rules (names language specific)
Disable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)";
Disable-NetFirewallRule -DisplayName "Windows-Remoteverwaltung (HTTP eingehend)";

# (optional) You can configure hosts that are allowed to connect to WinRM
winrm set winrm/config/client '@{TrustedHosts="*"}';

Restart-Service winrm;
```

If it's necessary to use a self-signed-certificate, you can follow the
[guide on visualstudiogeeks.com](https://www.visualstudiogeeks.com/devops/how-to-configure-winrm-for-https-manually).

### Enabling Basic Auth

Basic auth can be used as fallback for NTLM, but will require a local account on each machine.

```powershell
winrm set winrm/config/service/Auth '@{Basic="true"}'
```

## Contributing

The check_by_icingaforwindows plugin is an Open Source project and lives from your contributions. No matter whether these are feature requests, issues, translations, documentation or code.

* Please check whether a related issue already exists on our Issue Tracker
* Send a Pull Request
* The master branch shall never be corrupt!
