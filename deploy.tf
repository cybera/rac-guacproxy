variable "key-pair" {}
variable "ssh-private-key" {}
variable "allowed-addresses-v4" {
    default = "0.0.0.0/0"
}
variable "allowed-addresses-v6" {
    default = "::/0"
}

# create security groups
# when new Windows instances are created, each Windows machine will need to be a member of the 'rdp' security group
resource "openstack_compute_secgroup_v2" "ssh" {
    name               = "ssh"
    description        = "open 22/ssh to specified address (default: 0.0.0.0/0, ::/0)"
    rule {
        from_port      = 22
        to_port        = 22
        ip_protocol    = "tcp"
        cidr           = "${var.allowed-addresses-v4}"
    }
    rule {
        from_port      = 22
        to_port        = 22
        ip_protocol    = "tcp"
        cidr           = "${var.allowed-addresses-v6}"
    }
}
resource "openstack_compute_secgroup_v2" "web" {
    name               = "web"
    description        = "open 443 and 80 for guac-proxy access"
    rule {
        from_port      = 443
        to_port        = 443
        ip_protocol    = "tcp"
        cidr           = "0.0.0.0/0"
    }
    rule {
        from_port      = 443
        to_port        = 443
        ip_protocol    = "tcp"
        cidr           = "::/0"
    }
    rule {
        from_port      = 80
        to_port        = 80
        ip_protocol    = "tcp"
        cidr           = "0.0.0.0/0"
    }
    rule {
        from_port      = 80
        to_port        = 80
        ip_protocol    = "tcp"
        cidr           = "::/0"
    }
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
    name               = "rdp"
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
    name               = "guacproxy"
    image_name         = "Ubuntu 16.04"
    flavor_name        = "m1.tiny"
    key_pair           = "${var.key-pair}"
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

resource "null_resource" "guac-prox-prov" {
    depends_on         = ["openstack_compute_instance_v2.proxy"]
    connection {
        type           = "ssh",
        host           = "${openstack_networking_floatingip_v2.fip_1.address}"
        user           = "ubuntu",
        private_key    = "${file(var.ssh-private-key)}"
    }
	provisioner "remote-exec" {
		inline = [
            "wget https://raw.githubusercontent.com/cybera/guac-install/master/guac-install.sh",
            "sed -i 's/\x0D$//' guac-install.sh",
            "chmod +x guac-install.sh"
		]
	}
}

output "instructions" {
    value = [
        "1. ssh to ${openstack_compute_instance_v2.proxy.name} using 'ssh -i ${var.ssh-private-key} ubuntu@${openstack_networking_floatingip_v2.fip_1.address}",
        "2. run /home/ubuntu/guac-install.sh as root 'sudo ./guac-proxy.sh'",
        "You will be prompted during the script to create passwords."
    ]
}
