locals {
  name_prefix = "centos7-httpd-demo"

  region = join("-", slice(split("-", var.zone), 0, length(split("-", var.zone)) - 1))

  base_labels = {
    environment   = var.environment
    managed_by    = "terraform"
    component     = "centos7-httpd"
    image_source  = "packer-centos7"
    cost_center   = var.cost_center
    owner_contact = var.owner_contact
  }

  standard_labels = merge(local.base_labels, var.additional_labels)
}
