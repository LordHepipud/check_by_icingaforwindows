#!/usr/bin/pwsh 

<#
.SYNOPSIS
    This plugin can be executed on Linux to remotely connect to a Windows machine, for executing Icinga for Windows checks.
    For easier usage, the plugin is designed to work as replacement for the `PowerShell Base` CheckCommand, which ensures you do
    not have to run multiple configurations for your CheckCommands itself, but can simply import this plugin as CheckCommand to
    services which should be checked by PowerShell remote instead of the Icinga Agent.
.DESCRIPTION
    This plugin can be executed on Linux to remotely connect to a Windows machine, for executing Icinga for Windows checks.
    For easier usage, the plugin is designed to work as replacement for the `PowerShell Base` CheckCommand, which ensures you do
    not have to run multiple configurations for your CheckCommands itself, but can simply import this plugin as CheckCommand to
    services which should be checked by PowerShell remote instead of the Icinga Agent.
.PARAMETER Command
    The Icinga for Windows command being executed on the Windows machine
.PARAMETER WindowsUser
    The Windows user being used for login into the Windows machine.
.PARAMETER WindowsPassword
    The Windows user password being used for login into the Windows machine.
.PARAMETER AuthenticationMethod
    Defines on how PowerShell remote execution is authenticating to the Windows machine.
.PARAMETER Server
    The Windows machine IP or FQDN to execute the check on.
.PARAMETER ConfigurationName
    The JEA profile the PowerShell session should be created with.
.EXAMPLE
    ./check_by_icingaforwindows.ps1 -Server 'windows.example.com' -WindowsUser 'domain\exampleuser' -WindowsPassword 'examplepassword' -C "Use-Icinga -Minimal; Exit-IcingaExecutePlugin -Command 'Invoke-IcingaCheckPartitionSpace' "
    [OK] Free Partition Space: 4 Ok
    | 'free_space_partition_s'=1855056000000B;;;0;1999841000000 'free_space_partition_i'=799003800000B;;;0;2199021000000 'free_space_partition_c'=442423800000B;;;0;478964400000 'free_space_partition_t'=102553700000B;;;0;107237900000
.NOTES
    Version:   1.0
    Author:    Lord Hepipud
    Company:   Icinga GmbH
    COPYRIGHT: (c) 2022 Icinga GmbH | GPLv2
    License:   https://github.com/Icinga/check_by_icingaforwindows/blob/master/LICENSE
    Project:   https://github.com/Icinga/check_by_icingaforwindows
#>

param (
    [Alias('C')]
    [string]$Command              = '',
    [string]$WindowsUser          = '',
    [string]$WindowsPassword      = '',
    [ValidateSet('Basic', 'Credssp', 'Default', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
    [string]$AuthenticationMethod = 'Negotiate',
    [string]$Server               = '',
    [string]$ConfigurationName    = ''
);

if ([string]::IsNullOrEmpty($Command)) {
    Write-Output '[UNKNOWN]: check_by_icingaforwindows: No command specified for execution';
    exit 3;
}

if ([string]::IsNullOrEmpty($Server)) {
    Write-Output '[UNKNOWN]: check_by_icingaforwindows: No server fqdn specified to run checks against';
    exit 3;
}

if ([string]::IsNullOrEmpty($WindowsUser) -Or [string]::IsNullOrEmpty($WindowsPassword)) {
    Write-Output '[UNKNOWN]: check_by_icingaforwindows: WindowsUser or WindowsPassword argument are empty';
    exit 3;
}

[SecureString]$EncryptedPassword = ConvertTo-SecureString -String $WindowsPassword -AsPlainText -Force;
[PSCredential]$Credential        = New-Object System.Management.Automation.PSCredential -ArgumentList $WindowsUser, $EncryptedPassword;
$WindowsPassword                        = $null;
[hashtable]$InvokeArguments      = @{
    '-ComputerName'   = $Server;
    '-Credential'     = $Credential;
    '-Authentication' = $AuthenticationMethod;
}

# Set JEA configuration if defined
if ([string]::IsNullOrEmpty($ConfigurationName) -eq $FALSE) {
    $InvokeArguments.Add('-ConfigurationName', $ConfigurationName);
}

# Create a new PowerShell remote session with above arguments
$RemoteSession = New-PSSession @InvokeArguments;

# Add the arguments from our plugins to our check command
$Command = [string]::Format('{0} {1}', $Command, ($args -Join ' '));

# Execute our plugin locally within a new shell, allowing us to fetch the exit code
$scriptblock = [ScriptBlock]::create("powershell.exe -NoProfile -NoLogo -C { $Command }");

# Invoke the actual check
Invoke-Command -Session $RemoteSession -ScriptBlock $ScriptBlock | Out-Null;

# Fetch the exit code of our check execution
[int]$ExitCode = Invoke-Command -Session $RemoteSession -ScriptBlock { return $LASTEXITCODE };

# Close the session
Remove-PSSession $RemoteSession | Out-Null;

# Close the shell with our exit code
exit $ExitCode;
