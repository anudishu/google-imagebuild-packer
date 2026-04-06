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
  description = "GCP project"
  default     = "root-cortex-465610-p8"
}

variable "zone" {
  type        = string
  description = "builder zone"
  default     = "us-central1-a"
}

# rhel-cloud (needs RHEL on GCP). cloud-user.
source "googlecompute" "rhel9_httpd" {
  project_id              = var.project_id
  source_image_family     = "rhel-9"
  source_image_project_id = ["rhel-cloud"]
  zone                    = var.zone
  machine_type            = "e2-medium"
  image_name              = "rhel9-httpd-golden"
  image_family            = "rhel9-httpd"
  image_description       = "rhel9 httpd"

  ssh_username = "cloud-user"
  ssh_timeout  = "25m"
  disk_size    = 20
  disk_type    = "pd-standard"

  metadata = {
    enable-oslogin = "TRUE"
  }
}

build {
  name    = "rhel9-httpd"
  sources = ["source.googlecompute.rhel9_httpd"]

  provisioner "shell" {
    inline = [
      "sudo dnf install -y ansible-core python3-libselinux",
      "ansible --version | head -1",
    ]
  }

  provisioner "ansible" {
    playbook_file = "../../ansible/rhel9/playbook.yml"
    extra_arguments = [
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
    ]
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
  }
}
