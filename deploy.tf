variable "server_name" {
    default = "guac-proxy"
}
variable "server_size" {
    default = "m1.tiny"
}
variable "allowed_cidr_v4" {
    default = "0.0.0.0/0"
}
variable "allowed_cidr_v6" {
    default = "::/0"
}

# generate key-pair for provisioning instance
# output private key to local file
resource "tls_private_key" "keygen" {
   algorithm   = "RSA"
   rsa_bits    = "4096"
}
resource "local_file" "private-key-file" {
    content  = "${tls_private_key.keygen.private_key_pem}"
    filename = "${path.module}/${var.server_name}.key"
}
resource "openstack_compute_keypair_v2" "pubkey" {
    name       = "${var.server_name}"
    public_key = "${tls_private_key.keygen.public_key_openssh}"
}

# create security groups for ssh, rdp and web (8080)
resource "openstack_compute_secgroup_v2" "ssh" {
    name               = "${var.server_name}-ssh"
    description        = "open 22/ssh to specified address (default: 0.0.0.0/0, ::/0)"
    rule {
        from_port      = 22
        to_port        = 22
        ip_protocol    = "tcp"
        cidr           = "${var.allowed_cidr_v4}"
    }
    rule {
        from_port      = 22
        to_port        = 22
        ip_protocol    = "tcp"
        cidr           = "${var.allowed_cidr_v6}"
    }
}
resource "openstack_compute_secgroup_v2" "web" {
    name               = "${var.server_name}-web"
    description        = "open 8080 for ${var.server_name} access"
    rule {
        from_port      = 8080
        to_port        = 8080
        ip_protocol    = "tcp"
        cidr           = "0.0.0.0/0"
    }
    rule {
        from_port      = 8080
        to_port        = 8080
        ip_protocol    = "tcp"
        cidr           = "::/0"
    }
}
resource "openstack_compute_secgroup_v2" "rdp" {
    name               = "${var.server_name}-rdp"
    description        = "open 3389/rdp to all members of rdp security group"
    rule {
        from_port      = 3389
        to_port        = 3389
        ip_protocol    = "tcp"
        self           = true
    }
}

# create guacproxy instance and floating IP; associate floating IP with instance
resource "openstack_compute_instance_v2" "proxy" {
    name               = "${var.server_name}"
    image_name         = "Ubuntu 16.04"
    flavor_name        = "${var.server_size}"
    key_pair           = "${openstack_compute_keypair_v2.pubkey.name}"
    lifecycle {
          ignore_changes = ["image_name", "image_id"]
      }
    security_groups    = [
        "${openstack_compute_secgroup_v2.ssh.name}",
        "${openstack_compute_secgroup_v2.web.name}",
        "${openstack_compute_secgroup_v2.rdp.name}",
    ]
}
resource "openstack_networking_floatingip_v2" "fip_1" {
    pool = "public"
}
resource "openstack_compute_floatingip_associate_v2" "fip_1" {
    floating_ip = "${openstack_networking_floatingip_v2.fip_1.address}"
    instance_id = "${openstack_compute_instance_v2.proxy.id}"
}

# After the proxy instance is built, download install script to instance and set it executable
resource "null_resource" "guac-prox-prov" {
    depends_on         = ["openstack_compute_instance_v2.proxy"]
    connection {
        type           = "ssh",
        host           = "${openstack_networking_floatingip_v2.fip_1.address}"
        user           = "ubuntu",
        private_key    = "${tls_private_key.keygen.private_key_pem}"
    }
	provisioner "remote-exec" {
		inline = [
            "wget https://raw.githubusercontent.com/cybera/guac-install/master/guac-install.sh",
            "sed -i 's/\x0D$//' guac-install.sh",
            "chmod +x guac-install.sh"
		]
	}
}

# output further instructions to screen along with private key
output "private_key_output" {
    value = "${tls_private_key.keygen.private_key_pem}"
}
output "instructions" {
    value = [
        "ssh to ${openstack_compute_instance_v2.proxy.name}:",
        "       'ssh -i ${local_file.private-key-file.filename} ubuntu@${openstack_networking_floatingip_v2.fip_1.address}'",
        "run /home/ubuntu/guac-install.sh as root:",
        "       'sudo ./guac-install.sh'",
        "You will be prompted during the script to create passwords.",
        "'terraform output instructions' can be used to print out this message again."
    ]
}
