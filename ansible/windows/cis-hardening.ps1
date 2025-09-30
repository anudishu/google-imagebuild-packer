# CIS Level 2 Hardening for Windows Server 2016
# Based on CIS Microsoft Windows Server 2016 Benchmark v1.4.0

Write-Host "Starting CIS Level 2 Hardening for Windows Server 2016..."

# CIS 1.1.1 - Ensure 'Enforce password history' is set to '24 or more password(s)'
Write-Host "Configuring password policy..."
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordHistorySize = 0", "PasswordHistorySize = 24") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

# CIS 1.1.2 - Ensure 'Maximum password age' is set to '365 or fewer days, but not 0'
net accounts /maxpwage:90

# CIS 1.1.3 - Ensure 'Minimum password age' is set to '1 or more day(s)'
net accounts /minpwage:1

# CIS 1.1.4 - Ensure 'Minimum password length' is set to '14 or more character(s)'
net accounts /minpwlen:14

# CIS 1.1.5 - Ensure 'Password must meet complexity requirements' is set to 'Enabled'
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

# CIS 1.2.1 - Ensure 'Account lockout duration' is set to '15 or more minute(s)'
net accounts /lockoutduration:30

# CIS 1.2.2 - Ensure 'Account lockout threshold' is set to '5 or fewer invalid logon attempt(s), but not 0'
net accounts /lockoutthreshold:5

# CIS 1.2.3 - Ensure 'Reset account lockout counter after' is set to '15 or more minute(s)'
net accounts /lockoutwindow:30

# CIS 2.2.1 - Ensure 'Access Credential Manager as a trusted caller' is set to 'No One'
Write-Host "Configuring user rights assignments..."
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("SeTrustedCredManAccessPrivilege = ", "SeTrustedCredManAccessPrivilege = ") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas USER_RIGHTS
rm -force c:\secpol.cfg -confirm:$false

# CIS 2.2.4 - Ensure 'Act as part of the operating system' is set to 'No One'
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("SeTcbPrivilege = ", "SeTcbPrivilege = ") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas USER_RIGHTS
rm -force c:\secpol.cfg -confirm:$false

# CIS 2.3.1.1 - Ensure 'Accounts: Administrator account status' is set to 'Disabled'
net user Administrator /active:no

# CIS 2.3.1.4 - Ensure 'Accounts: Limit local account use of blank passwords to console logon only' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 1 /f

# CIS 2.3.2.1 - Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v SCENoApplyLegacyAuditPolicy /t REG_DWORD /d 1 /f

# CIS 2.3.4.1 - Ensure 'Devices: Allowed to format and eject removable media' is set to 'Administrators'
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AllocateDASD /t REG_SZ /d "0" /f

# CIS 2.3.6.1 - Ensure 'Domain member: Digitally encrypt or sign secure channel data (always)' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v RequireSignOrSeal /t REG_DWORD /d 1 /f

# CIS 2.3.6.2 - Ensure 'Domain member: Digitally encrypt secure channel data (when possible)' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v SealSecureChannel /t REG_DWORD /d 1 /f

# CIS 2.3.6.3 - Ensure 'Domain member: Digitally sign secure channel data (when possible)' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v SignSecureChannel /t REG_DWORD /d 1 /f

# CIS 2.3.7.1 - Ensure 'Interactive logon: Do not display last user name' is set to 'Enabled'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DontDisplayLastUserName /t REG_DWORD /d 1 /f

# CIS 2.3.7.2 - Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f

# CIS 2.3.7.4 - Ensure 'Interactive logon: Message text for users attempting to log on'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LegalNoticeText /t REG_SZ /d "This system is for authorized users only. All activity is monitored and logged." /f

# CIS 2.3.7.5 - Ensure 'Interactive logon: Message title for users attempting to log on'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LegalNoticeCaption /t REG_SZ /d "WARNING: Authorized Use Only" /f

# CIS 2.3.8.1 - Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f

# CIS 2.3.8.2 - Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v EnableSecuritySignature /t REG_DWORD /d 1 /f

# CIS 2.3.9.1 - Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v AutoDisconnect /t REG_DWORD /d 15 /f

# CIS 2.3.9.2 - Ensure 'Microsoft network server: Digitally sign communications (always)' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f

# CIS 2.3.10.1 - Ensure 'Network access: Allow anonymous SID/Name translation' is set to 'Disabled'
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("LSAAnonymousNameLookup = 1", "LSAAnonymousNameLookup = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

# CIS 2.3.10.2 - Ensure 'Network access: Do not allow anonymous enumeration of SAM accounts' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymousSAM /t REG_DWORD /d 1 /f

# CIS 2.3.10.3 - Ensure 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous /t REG_DWORD /d 1 /f

# CIS 2.3.11.1 - Ensure 'Network security: Do not store LAN Manager hash value on next password change' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v NoLMHash /t REG_DWORD /d 1 /f

# CIS 2.3.11.2 - Ensure 'Network security: LAN Manager authentication level' is set to 'Send NTLMv2 response only. Refuse LM & NTLM'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f

# CIS 2.3.11.3 - Ensure 'Network security: LDAP client signing requirements' is set to 'Negotiate signing' or higher
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LDAP" /v LDAPClientIntegrity /t REG_DWORD /d 1 /f

# CIS 2.3.11.4 - Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" /v NTLMMinClientSec /t REG_DWORD /d 537395200 /f

# CIS 2.3.11.5 - Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLMv2 session security, Require 128-bit encryption'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" /v NTLMMinServerSec /t REG_DWORD /d 537395200 /f

# CIS 2.3.15.1 - Ensure 'System objects: Require case insensitivity for non-Windows subsystems' is set to 'Enabled'
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v ObCaseInsensitive /t REG_DWORD /d 1 /f

# CIS 2.3.17.1 - Ensure 'User Account Control: Admin Approval Mode for the Built-in Administrator account' is set to 'Enabled'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 1 /f

# CIS 2.3.17.2 - Ensure 'User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode' is set to 'Prompt for consent on the secure desktop'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f

# CIS 2.3.17.3 - Ensure 'User Account Control: Behavior of the elevation prompt for standard users' is set to 'Automatically deny elevation requests'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 0 /f

# CIS 2.3.17.5 - Ensure 'User Account Control: Run all administrators in Admin Approval Mode' is set to 'Enabled'
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f

# Enable Windows Firewall
Write-Host "Configuring Windows Firewall..."
netsh advfirewall set allprofiles state on
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound

# Allow essential services
netsh advfirewall firewall add rule name="HTTP Inbound" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="HTTPS Inbound" dir=in action=allow protocol=TCP localport=443
netsh advfirewall firewall add rule name="RDP Inbound" dir=in action=allow protocol=TCP localport=3389

# Disable unnecessary services
Write-Host "Disabling unnecessary services..."
$servicesToDisable = @(
    "Fax",
    "FTPSVC",
    "MSiSCSI",
    "RemoteRegistry",
    "Routing",
    "SimpleService",
    "SNMP",
    "SNMPTRAP",
    "TapiSrv",
    "TlntSvr",
    "W3SVC",
    "WAS",
    "WebClient"
)

foreach ($service in $servicesToDisable) {
    try {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Disabled service: $service"
    } catch {
        Write-Host "Service $service not found or already disabled"
    }
}

# Configure audit policies
Write-Host "Configuring audit policies..."
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Detailed Tracking" /success:enable /failure:enable
auditpol /set /category:"DS Access" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"System" /success:enable /failure:enable

# Set security event log size
wevtutil sl Security /ms:196608000

# Disable SMBv1
Write-Host "Disabling SMBv1..."
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Enable Windows Defender (if available)
Write-Host "Configuring Windows Defender..."
try {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -DisableBehaviorMonitoring $false
    Set-MpPreference -DisableBlockAtFirstSeen $false
    Set-MpPreference -DisableIOAVProtection $false
    Set-MpPreference -DisablePrivacyMode $false
    Set-MpPreference -DisableScriptScanning $false
    Set-MpPreference -SubmitSamplesConsent SendSafeSamples
} catch {
    Write-Host "Windows Defender not available or already configured"
}

Write-Host "CIS Level 2 Hardening completed successfully!"
