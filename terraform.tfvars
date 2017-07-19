# Guacamole HTML5 RDP Proxy Variables

# OpenStack variables
# ${var.openstack-user}
# ${var.openstack-project}
# ${var.openstack-password}
# ${var.key-pair}

user       = ""
project    = ""
password   = ""
key-pair   = ""

# Private key file associated with ${var.key-pair} above
#${var.ssh-private-key}

ssh-private-key      = "/path/to/id_rsa"

# Remote administrator cidr
# Default is '0.0.0.0/0 & ::0' meaning that by default ssh access to the instance is open to all IP addresses
# ${var.allowed-cidr-v4}
# ${var.allowed-cidr-v6}

# allowed-cidr-v4 = ""
# allowed-cidr-v6 = ""
