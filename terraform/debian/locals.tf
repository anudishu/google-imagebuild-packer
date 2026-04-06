locals {
  name_prefix = "apache-packer-demo"

  region = join("-", slice(split("-", var.zone), 0, length(split("-", var.zone)) - 1))

  base_labels = {
    environment   = var.environment
    managed_by    = "terraform"
    component     = "apache-web"
    image_source  = "packer-debian"
    cost_center   = var.cost_center
    owner_contact = var.owner_contact
  }

  standard_labels = merge(local.base_labels, var.additional_labels)
}
