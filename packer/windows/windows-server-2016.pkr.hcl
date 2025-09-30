packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
  default     = "root-cortex-465610-p8"
}

variable "zone" {
  type        = string
  description = "GCP Zone"
  default     = "us-central1-a"
}

variable "source_image" {
  type        = string
  description = "Source image for Windows Server 2016"
  default     = "windows-server-2016-dc-v20250913"
}

source "googlecompute" "windows" {
  project_id          = var.project_id
  source_image        = var.source_image
  source_image_project_id = ["windows-cloud"]
  zone                = var.zone
  machine_type        = "n1-standard-2"
  image_name          = "windows-server-2016-hardened-{{timestamp}}"
  image_family        = "windows-server-2016-hardened"
  image_description   = "Windows Server 2016 with CIS hardening and IIS"

  disk_size           = 50
  disk_type           = "pd-standard"

  # Windows-specific settings
  communicator        = "winrm"
  winrm_username      = "packer"
  winrm_insecure      = true
  winrm_use_ssl       = true
  winrm_timeout       = "30m"

  metadata = {
    enable-oslogin = "FALSE"
    windows-startup-script-ps1 = <<-EOT
      # Enable WinRM for Packer
      winrm quickconfig -q
      winrm set winrm/config/service '@{AllowUnencrypted="true"}'
      winrm set winrm/config/service/auth '@{Basic="true"}'
      
      # Set up packer user
      net user packer PackerTemp123! /add /y
      net localgroup administrators packer /add
      
      # Enable RDP (optional)
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    EOT
  }
}

build {
  name = "windows-server-2016"
  sources = ["source.googlecompute.windows"]

  # Wait for Windows to be ready
  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for Windows to be ready...'",
      "Start-Sleep -Seconds 30"
    ]
  }

  # Install Chocolatey for package management
  provisioner "powershell" {
    inline = [
      "Set-ExecutionPolicy Bypass -Scope Process -Force",
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
      "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    ]
  }

  # Install required tools
  provisioner "powershell" {
    inline = [
      "choco install -y powershell-core",
      "choco install -y googlechrome",
      "choco install -y notepadplusplus"
    ]
  }

  # Run CIS hardening
  provisioner "powershell" {
    scripts = [
      "../../ansible/windows/cis-hardening.ps1",
      "../../ansible/windows/install-iis.ps1",
      "../../ansible/windows/install-ops-agent.ps1"
    ]
  }

  # Sysprep and shutdown
  provisioner "powershell" {
    inline = [
      "Write-Host 'Running Sysprep...'",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}
