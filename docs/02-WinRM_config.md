# Configuring WinRM on Windows

In order to be able to execute plugins by using `check_by_icingaforwindows`, we have to enable PowerShell remote by configuring `WinRM` (Windows Remote-Management).

## Preparing the Windows machine

By default, WinRM is most likely not enabled, and if enabled, will only allow Kerberos authentication. WinRM can be configured in many ways, to allow connections by HTTP or HTTPS.

Even by using HTTP as connection protocol, your communication is encrypted and **not** transmitted plain text. For more security, you can enable the HTTPS listener, by using a TLS certificate. More details on how to setup this, are listed below.

**Note:** On some Linux systems and depending on your environment, it might not be able to connect from Linux to WinRM by using TLS, as the authentication request is not properly passed through. Therefor, even while more secure, we would not advice to rely on WinRM over TLS connections and stick to the default behaviour by using HTTP sockets.

Anything you configure via cmd or powershell needs to be run from an administrative shell.

## WinRM quickconfig

If you have not yet configured `WinRM` on the system, you can use the `quickconfig` setting to get the basic configuration done:

```powershell
winrm quickconfig
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
```

`MaxMemoryPerShellMB` ensures that we will not run out of memory for executing our commands. For Icinga for Windows, we recommend at least `2GB` of memory per shell.

## Enable PowerShell Remoting

Even though `winrm quickconfig` should be enough, it can sometimes be required to explicitly enable PowerShell remote:

```powershell
Enable-PSRemoting -SkipNetworkProfileCheck -Force;
```

**Note:** On newer Windows machines, WinRM and PowerShell remote might already be enabled

## Allow Specific Hosts only (optional)

We can limit the access to our machine by adding a list of hosts that are allowed to connect. To allow every host, we can use `*`:

```powershell
# (optional) You can configure hosts that are allowed to connect to WinRM
winrm set winrm/config/client '@{TrustedHosts="*"}';
```

## Enabling Basic Auth (optional)

Basic auth can be enabled and used as fallback for NTLM, but will require a local account on each machine. You can enable it with:

```powershell
winrm set winrm/config/service/Auth '@{Basic="true"}'
```

## Setting up HTTPS Listener

While PowerShell remote might be enabled by default, it is most likely that it only listens on HTTP. Therefor we could setup a HTTPS listener with a TLS certificate, for increased encryption and security.

We can either use a certificate provided by our domain or use the local host certificate used by `Remote Desktop`.

WinRM HTTPS requires a local computer `Server Authentication` certificate with a CN matching the hostname, that is not expired, revoked, or self-signed to be installed.

**Note:** On some Linux systems and depending on your environment, it might not be able to connect from Linux to WinRM by using TLS, as the authentication request is not properly passed through. Therefor, even while more secure, we would not advice to rely on WinRM over TLS connections and stick to the default behaviour by using HTTP sockets.

### Own Certificate

To use an own certificate, you have to install it inside the `Cert:\LocalMachine\My` location of the `Cert Store`. You then have to note the `thumbprint` of the certificate for later use.

You can write it into a variable as follows

```powershell
$CertThumbprint = 'cert_thumbprint';
```

For creating self signed certificates, please have a look on the [guide on visualstudiogeeks.com](https://www.visualstudiogeeks.com/devops/how-to-configure-winrm-for-https-manually).

### Remote Desktop Certificate

In case you are using the `Remote Desktop` certificate, you can try to auto fetch the certificate from path `Cert:\LocalMachine\Remote Desktop` by using the hostname and the dns alias of the domain and install it inside the `Cert:\LocalMachine\My` location:

```powershell
$Certificate = Get-ChildItem `
    -Path 'Cert:\LocalMachine\Remote Desktop\' |
        ForEach-Object {
            if ($_.Subject -like ([string]::Format('CN={0}.{1}', $env:COMPUTERNAME, $env:USERDNSDOMAIN ))) {
                return $_;
            }
        };

$MyCertStore = New-Object 'System.Security.Cryptography.X509Certificates.X509Store' 'My', 'LocalMachine'
$MyCertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite);
$MyCertStore.Add($Certificate);

$MyCertStore.Close();

$CertThumbprint = $Certificate.ThumbPrint;
```

Otherwise you can manually lookup the `Thumbprint` at `Cert:\LocalMachine\Remote Desktop` by using the `mmc` or changing the filter to print all certificates:

```powershell
Get-ChildItem -Path 'Cert:\LocalMachine\Remote Desktop\'
```

## Disabling HTTP Listener (optional)

Now as we found our `Thumbprint` for the certificate to use, we can remove the HTTP listener to prevent connections for this:

```powershell
# (optional) Disable HTTP transport listener
Get-ChildItem WSMan:\Localhost\listener | Where-Object Keys -eq "Transport=HTTP" | Remove-Item -Recurse;
```

In addition, we can also disable the firewall rule for HTTP WinRM requests. This is language specific and has to be updated to your language. Both examples will cover German and English:

```powershell
# Disable possible old HTTP firewall rules (names language specific)
Disable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)";
Disable-NetFirewallRule -DisplayName "Windows-Remoteverwaltung (HTTP eingehend)";
```

Make sure to install the certificate in the local machine cert store. This example is using PowerShell.

**Note:** Please be aware, that disabling HTTP listener might break other remote execution tools, which rely on the HTTP listener and/or do not support the HTTPS listener. We would recommend leaving the HTTP listener enabled.

## Install HTTPS Listener

To install the HTTPS listener, we have to provide the `Thumbprint` of our certificate we provided and installed into `Cert:\LocalMachine\My` or use the `Remote Desktop` one we copied into the `Cert:\LocalMachine\My` space. The listen address can either be specified to a specific address or use `*` to listen everywhere:

```powershell
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $CertThumbprint -Force;
```

Last but not least we have to open the Windows firewall to accept connections to our HTTPS listener:

```powershell
# Create a new firewall rule to allow incoming HTTPS connection on port 5986
New-NetFirewallRule `
    -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Name "Windows Remote Management (HTTPS-In)" `
    -Profile 'Any' `
    -LocalPort 5986 `
    -Protocol 'TCP';
```

## Connecting by using HTTPS listener

In order to connect to the Windows host by using the HTTPS listener, we have to use the `-UseSSL` flag for the `Enter-PSSession` and `Invoke-Command` Cmdlet:

```powershell
Enter-PSSession -ComputerName 'windowstest.example.com' -UseSSL;
```

In case you are running self-signed certificates and receive an error that the validation failed, you can skip it by using `New-PSSessionOption`:

```powershell
Enter-PSSession -ComputerName 'windowstest.example.com' -UseSSL -SessionOption (New-PSSessionOption -SkipCNCheck -SkipCACheck)
```

## Important Notice

If you disable the `HTTP` listener or block the firewall rule, a connection to this specific Windows host is no longer possible without the `-UseSSL` flag for remote Cmdlets.
