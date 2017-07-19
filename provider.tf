variable "openstack-user" {}
variable "openstack-project" {}
variable "openstack-user-password" {}
provider "openstack" {
  user_name   = "${var.openstack-user}"
  tenant_name = "${var.openstack-project}"
  password    = "${var.openstack-user-password}"
  auth_url    = "https://keystone-yyc.cloud.cybera.ca:5000/v2.0"
}
