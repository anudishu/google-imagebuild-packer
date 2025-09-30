# Install Google Cloud Ops Agent on Windows Server 2016
Write-Host "Installing Google Cloud Ops Agent..."

# Download and install Google Cloud Ops Agent
$opsAgentUrl = "https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.ps1"
$tempScript = "$env:TEMP\add-google-cloud-ops-agent-repo.ps1"

try {
    # Download the installation script
    Invoke-WebRequest -Uri $opsAgentUrl -OutFile $tempScript -UseBasicParsing
    
    # Run the installation script
    & $tempScript -AlsoInstall
    
    Write-Host "Google Cloud Ops Agent installed successfully!"
    
    # Verify installation
    $service = Get-Service -Name "google-cloud-ops-agent*" -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Ops Agent service is running: $($service.Name)"
        Write-Host "Service Status: $($service.Status)"
    } else {
        Write-Host "Warning: Ops Agent service not found"
    }
    
} catch {
    Write-Host "Error installing Ops Agent: $($_.Exception.Message)"
    
    # Fallback: Try direct MSI installation
    Write-Host "Attempting fallback installation method..."
    try {
        $msiUrl = "https://dl.google.com/cloudagents/windows/StackdriverAgent.msi"
        $msiPath = "$env:TEMP\StackdriverAgent.msi"
        
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
        Start-Process msiexec.exe -Wait -ArgumentList "/i $msiPath /quiet"
        
        Write-Host "Fallback installation completed"
    } catch {
        Write-Host "Fallback installation also failed: $($_.Exception.Message)"
    }
}

# Clean up temporary files
Remove-Item $tempScript -Force -ErrorAction SilentlyContinue

# Create a basic configuration file for Ops Agent
$configContent = @"
# Google Cloud Ops Agent Configuration
# This configuration enables basic monitoring and logging

logging:
  receivers:
    windows_event_log:
      type: windows_event_log
      channels: [System, Application, Security]
    iis_access:
      type: files
      include_paths: ["C:\\inetpub\\logs\\LogFiles\\W3SVC1\\*.log"]
      record_log_file_path: true
  processors:
    batch:
      type: batch
  exporters:
    google:
      type: google_cloud_logging
  service:
    pipelines:
      default_pipeline:
        receivers: [windows_event_log, iis_access]
        processors: [batch]
        exporters: [google]

metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
      scrapers:
        cpu: {}
        disk: {}
        filesystem: {}
        memory: {}
        network: {}
        process: {}
    iis:
      type: iis
      collection_interval: 60s
  processors:
    batch:
      type: batch
  exporters:
    google:
      type: google_cloud_monitoring
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics, iis]
        processors: [batch]
        exporters: [google]
"@

# Write configuration file
$configPath = "C:\Program Files\Google\Cloud Operations\Ops Agent\config\config.yaml"
$configDir = Split-Path $configPath -Parent

if (Test-Path $configDir) {
    $configContent | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "Ops Agent configuration file created at: $configPath"
    
    # Restart the service to apply configuration
    try {
        Restart-Service "google-cloud-ops-agent*" -Force
        Write-Host "Ops Agent service restarted successfully"
    } catch {
        Write-Host "Warning: Could not restart Ops Agent service: $($_.Exception.Message)"
    }
} else {
    Write-Host "Warning: Ops Agent configuration directory not found"
}

Write-Host "Google Cloud Ops Agent installation completed!"
