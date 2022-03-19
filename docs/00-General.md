# General information for check_by_icingaforwindows

This plugin is intended as Icinga for Windows remote execution connector from Linux based systems by using WinRM. WinRM (Windows Remote Management), allows for remote connections from different systems, to access the Windows command line.

## Requirements

* Installed [PowerShell for Linux](https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-on-linux)
* Configured WinRM service on the Windows machines
* [Icinga for Windows](https://icinga.com/docs/icinga-for-windows/latest/) >=1.8.0 installed on the Windows machines

## Plugin Installation

To install this plugin, you simply require to copy the `check_by_icingaforwindows.ps1` to your base plugin directory on your Icinga machine (e.g. `/usr/lib64/nagios/plugins/`).

For detailed instructions, please follow the [Installation](01-Installation.md) guide.

## WinRM Installation

On some systems, WinRM might not be enabled by default. Please have a look on the [WinRM config](02-WinRM_config.md) section, in case you require to install it.

## WinRM Security

By default, WinRM will listen on a HTTP socket for incoming connections on port `5985`. Even though this is a HTTP connection, WinRM based connections are not plain text and always encrypted, unless explicitly specified to allow unencrypted connections *which you should never enable*.

You can add more security to the encryption by using HTTPS instead of HTTP, which requires a trusted and signed TLS certificate. The [WinRM config](02-WinRM_config.md) section covers, on how to setup and install WinRM by using TLS.

**Note:** On some Linux systems and depending on your environment, it might not be able to connect from Linux to WinRM by using TLS, as the authentication request is not properly passed through. Therefor, even while more secure, we would not advice to rely on WinRM over TLS connections and stick to the default behaviour by using HTTP sockets.
