# Install check_by_icingaforwindows

## Install the Plugin

To install this plugin, you simply require to copy the `check_by_icingaforwindows.ps1` to your base plugin directory on your Icinga machine (e.g. `/usr/lib64/nagios/plugins/`).

In addition to that, make the plugin executable

```bash
chmod +x /usr/lib64/nagios/plugins/check_by_icingaforwindows.ps1
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
sudo yum install epel-release -y
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

### SSL Error on Authentication

In some cases you will receive the following error:

```bash
pwsh: symbol lookup error: /opt/microsoft/powershell/7/libmi.so: undefined symbol: SSL_library_init
```

**Solution**: Install WSMan

```powershell
pwsh -Command 'Install-Module -Name PSWSMan'
sudo pwsh -Command 'Install-WSMan'
```

### NTML authentication not working

MI_RESULT_ACCESS_DENIED is returned while using the plugin

**Solution**: Use `Negotiate` method (which the plugin defaults to) for authentication
