# Extra knobs for windows packer — main template still lives in windows-server-2016.pkr.hcl

variable "windows_build_revision" {
  type        = string
  description = "sha / build number from CI"
  default     = "unknown"
}

variable "windows_image_maintainer" {
  type        = string
  description = "who owns the image when it’s stale — put a distro list or slack channel"
  default     = "platform-team"
}

variable "windows_hardening_profile" {
  type        = string
  description = "label for which baseline you applied — doesn’t enforce anything by itself"
  default     = "cis-baseline"
}

variable "windows_disk_size_gb" {
  type        = number
  description = "C: size during build; windows wants more headroom than linux"
  default     = 50
}

variable "windows_machine_type" {
  type        = string
  description = "builder size — n1-standard-2 was the sweet spot for our tests"
  default     = "n1-standard-2"
}

variable "windows_image_family_override" {
  type        = string
  description = "if you renamed the family in packer publish"
  default     = ""
}

variable "windows_enable_winrm_debug" {
  type        = bool
  description = "noisier logs around winrm — flip when connections flake"
  default     = false
}

variable "windows_sysprep_timeout" {
  type        = string
  description = "how long packer waits on sysprep-y stuff before giving up"
  default     = "30m"
}

variable "windows_install_updates" {
  type        = bool
  description = "pull windows updates during build — makes runs loooong"
  default     = false
}

locals {
  windows_packer_context = {
    revision          = var.windows_build_revision
    maintainer        = var.windows_image_maintainer
    hardening_profile = var.windows_hardening_profile
    disk_gb           = var.windows_disk_size_gb
    machine_type      = var.windows_machine_type
    winrm_debug       = var.windows_enable_winrm_debug ? "verbose" : "normal"
    sysprep_timeout   = var.windows_sysprep_timeout
    install_updates   = var.windows_install_updates ? "yes" : "skip"
  }

  windows_effective_family = var.windows_image_family_override != "" ? var.windows_image_family_override : "windows-server-2016-hardened"
}
