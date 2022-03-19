# Check By Icinga for Windows

This repository provides a plugin which can be executed on Linux to remotely connect to a Windows machine, for executing [Icinga for Windows](https://icinga.com/docs/icinga-for-windows/latest/) checks.
For easier usage, the plugin is designed to work as replacement for the `PowerShell Base` CheckCommand, which ensures you do not have to run multiple configurations for your CheckCommands itself, but can simply import this plugin as CheckCommand to services which should be checked by PowerShell remote instead of the Icinga Agent.

## Requirements

* Installed [PowerShell for Linux](https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-linux)
* Configured WinRM service on the Windows machines
* [Icinga for Windows](https://icinga.com/docs/icinga-for-windows/latest/) >=1.8.0 installed on the Windows machines

## Usage

```text
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

## Contributing

The check_by_icingaforwindows plugin is an Open Source project and lives from your contributions. No matter whether these are feature requests, issues, translations, documentation or code.

* Please check whether a related issue already exists on our Issue Tracker
* Send a Pull Request
* The master branch shall never be corrupt!
