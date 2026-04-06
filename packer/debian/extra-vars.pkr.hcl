# Split out so simple-apache.pkr.hcl stays short.
# CI can pass -var-file=foo.pkrvars.hcl with these filled in.

variable "build_revision" {
  type        = string
  description = "git sha or build id — whatever your pipeline stamps on artifacts"
  default     = "unknown"
}

variable "build_url" {
  type        = string
  description = "jenkins/github run url pasted into logs when debugging who broke the build"
  default     = ""
}

variable "golden_image_notes" {
  type        = string
  description = "freeform string; we concat into metadata when non-empty"
  default     = ""
}

# not wired into every builder block yet — kept for when we unify family naming in CI
variable "image_family_override" {
  type        = string
  description = "override image family string if you forked naming"
  default     = ""
}

variable "disk_size_gb" {
  type        = number
  description = "builder disk size; debian needs at least ~10 for apt noise"
  default     = 10
}

variable "machine_type_override" {
  type        = string
  description = "if set, your wrapper script should swap builder machine type — placeholder here"
  default     = ""
}

variable "ansible_verbose" {
  type        = bool
  description = "flip true when ansible hides the actual error"
  default     = false
}

variable "skip_create_image" {
  type        = bool
  description = "debug — provision only, skip final image (packer -except pattern)"
  default     = false
}

variable "network_tags_csv" {
  type        = string
  description = "documentation / tagging only right now"
  default     = ""
}

locals {
  packer_audit_tags = {
    build_revision = var.build_revision
    build_tool     = "packer"
    template       = "debian/simple-apache"
    disk_gb        = var.disk_size_gb
    verbose        = var.ansible_verbose ? "on" : "off"
  }

  effective_family_suffix = var.image_family_override != "" ? var.image_family_override : "apache-simple"

  build_metadata_lines = compact([
    length(var.build_url) > 0 ? "build_url=${var.build_url}" : "",
    length(var.golden_image_notes) > 0 ? "notes=${var.golden_image_notes}" : "",
    length(var.network_tags_csv) > 0 ? "tags=${var.network_tags_csv}" : "",
  ])
}
