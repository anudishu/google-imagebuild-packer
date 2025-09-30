packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
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

source "googlecompute" "apache" {
  project_id          = var.project_id
  source_image        = "debian-11-bullseye-v20250915"
  zone                = var.zone
  machine_type        = "e2-small"
  image_name          = "apache-simple-sumitk"
  image_family        = "apache-simple"
  image_description   = "Simple Apache image with basic monitoring"
  
  ssh_username        = "packer"
  ssh_timeout         = "20m"
  disk_size           = 10
  disk_type           = "pd-standard"
  
  metadata = {
    enable-oslogin = "TRUE"
  }
}

build {
  name = "apache-simple"
  sources = ["source.googlecompute.apache"]

  # Install Ansible
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ansible"
    ]
  }

  # Run Ansible playbook
  provisioner "ansible" {
    playbook_file = "../../ansible/debian/simple-playbook.yml"
    extra_arguments = [
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
  }
}
