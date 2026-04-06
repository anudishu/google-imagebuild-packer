# optional vars for CI / wrappers (not required for a plain local build)

variable "rhel9_build_revision" {
  type        = string
  description = "build id / git sha"
  default     = "unknown"
}

variable "rhel9_machine_type_override" {
  type        = string
  description = "non-empty overrides builder machine type"
  default     = ""
}

variable "rhel9_disk_size_gb" {
  type        = number
  description = "builder boot disk GB"
  default     = 20
}

variable "rhel9_image_family_override" {
  type        = string
  description = "override output image family"
  default     = ""
}

locals {
  rhel9_packer_notes = {
    revision = var.rhel9_build_revision
    os       = "rhel-9"
    target   = "httpd"
  }

  rhel9_effective_family = var.rhel9_image_family_override != "" ? var.rhel9_image_family_override : "rhel9-httpd"
}
