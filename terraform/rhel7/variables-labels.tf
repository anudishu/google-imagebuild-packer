variable "environment" {
  description = "env label (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "billing / cost tag"
  type        = string
  default     = "engineering"
}

variable "owner_contact" {
  description = "contact for this stack"
  type        = string
  default     = "platform-team"
}

variable "additional_labels" {
  description = "extra labels merged into the default set"
  type        = map(string)
  default     = {}
}
