variable "user" {}
variable "project" {}
variable "password" {}
provider "openstack" {
  user_name   = "${var.user}"
  tenant_name = "${var.project}"
  password    = "${var.password}"
  auth_url    = "https://keystone-yyc.cloud.cybera.ca:5000/v2.0"
}
