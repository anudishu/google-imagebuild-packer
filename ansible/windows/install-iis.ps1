# Install and configure IIS on Windows Server 2016
Write-Host "Installing IIS and related features..."

# Enable IIS and required features
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All

# Import WebAdministration module
Import-Module WebAdministration

# Create a custom index page
$indexContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows Server 2016 - CIS Hardened</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #0078d4; }
        .security-list { background-color: #e8f4fd; padding: 20px; border-left: 4px solid #0078d4; }
        ul { list-style-type: none; padding: 0; }
        li { padding: 5px 0; }
        li:before { content: "✓ "; color: #107c10; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello from Windows Server 2016!</h1>
        <p>This is a Windows Server 2016 running IIS on a CIS Level 2 hardened golden image.</p>
        
        <div class="security-list">
            <h3>Security Features Applied:</h3>
            <ul>
                <li>CIS Level 2 Hardening Applied</li>
                <li>Google Cloud Ops Agent Monitoring</li>
                <li>Windows Firewall Configured</li>
                <li>Audit Logging Enabled</li>
                <li>SMBv1 Disabled</li>
                <li>Strong Password Policies</li>
                <li>User Account Control Enabled</li>
                <li>Unnecessary Services Disabled</li>
            </ul>
        </div>
        
        <p><strong>Server Information:</strong></p>
        <ul>
            <li>OS: Windows Server 2016</li>
            <li>Web Server: IIS 10.0</li>
            <li>Security: CIS Level 2 Compliant</li>
            <li>Monitoring: Google Cloud Ops Agent</li>
        </ul>
    </div>
</body>
</html>
"@

# Write the custom index page
$indexContent | Out-File -FilePath "C:\inetpub\wwwroot\index.html" -Encoding UTF8

# Remove default IIS files
Remove-Item "C:\inetpub\wwwroot\iisstart.htm" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\inetpub\wwwroot\iisstart.png" -Force -ErrorAction SilentlyContinue

# Configure IIS security settings
Write-Host "Configuring IIS security settings..."

# Remove unnecessary HTTP headers
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/httpProtocol/customHeaders/add[@name='X-Powered-By']" -name "." -value ""
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/httpProtocol/customHeaders" -name "." -value @{name='X-Content-Type-Options';value='nosniff'}
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/httpProtocol/customHeaders" -name "." -value @{name='X-Frame-Options';value='SAMEORIGIN'}

# Configure request filtering
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxAllowedContentLength" -value 30000000
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxUrl" -value 4096
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/requestFiltering/requestLimits" -name "maxQueryString" -value 2048

# Disable directory browsing
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/directoryBrowse" -name "enabled" -value "False"

# Configure logging
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/httpLogging" -name "enabled" -value "True"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/httpLogging" -name "logExtFileFlags" -value "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Cookie,Referer,ProtocolVersion,Host,HttpSubStatus"

# Start IIS service
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic

Write-Host "IIS installation and configuration completed successfully!"
