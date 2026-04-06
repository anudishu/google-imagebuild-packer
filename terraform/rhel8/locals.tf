locals {
  name_prefix = "rhel8-httpd-demo"

  region = join("-", slice(split("-", var.zone), 0, length(split("-", var.zone)) - 1))

  base_labels = {
    environment   = var.environment
    managed_by    = "terraform"
    component     = "rhel8-httpd"
    image_source  = "packer-rhel8"
    cost_center   = var.cost_center
    owner_contact = var.owner_contact
  }

  standard_labels = merge(local.base_labels, var.additional_labels)
}
