locals {
  name_prefix = "windows-packer-demo"

  base_labels = {
    environment   = var.environment
    managed_by    = "terraform"
    component     = "windows-iis"
    image_source  = "packer-windows-2016"
    cost_center   = var.cost_center
    owner_contact = var.owner_contact
  }

  standard_labels = merge(local.base_labels, var.additional_labels)
}
