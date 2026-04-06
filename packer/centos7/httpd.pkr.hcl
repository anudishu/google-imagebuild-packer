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

# centos-cloud, ssh user centos. EPEL installed in shell step for ansible rpm.
source "googlecompute" "centos7_httpd" {
  project_id              = var.project_id
  source_image_family     = "centos-7"
  source_image_project_id = ["centos-cloud"]
  zone                    = var.zone
  machine_type            = "e2-medium"
  image_name              = "centos7-httpd-golden"
  image_family            = "centos7-httpd"
  image_description       = "centos7 httpd"

  ssh_username = "centos"
  ssh_timeout  = "30m"
  disk_size    = 20
  disk_type    = "pd-standard"

  metadata = {
    enable-oslogin = "TRUE"
  }
}

build {
  name    = "centos7-httpd"
  sources = ["source.googlecompute.centos7_httpd"]

  provisioner "shell" {
    inline = [
      "sudo yum install -y epel-release",
      "sudo yum install -y ansible libselinux-python",
      "ansible --version | head -1",
    ]
  }

  provisioner "ansible" {
    playbook_file = "../../ansible/centos7/playbook.yml"
    extra_arguments = [
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python2",
    ]
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
  }
}
