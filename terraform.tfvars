# Guacamole HTML5 Clientless Remote Desktop Gateway
# Configuration variables

### REQUIRED ###
# OpenStack variables
# ${var.openstack-user}
# ${var.openstack-project}
# ${var.openstack-password}

user       = ""
project    = ""
password   = ""

### OPTIONAL ###
# Openstack flavor (instance size)
# ${var.server_size}

# server_size = ""

# Remote administrator cidr
# Default is '0.0.0.0/0' & '::0' meaning that by default ssh access to the instance is open to all IP addresses
# ${var.allowed_cidr_v4}
# ${var.allowed_cidr_v6}

# allowed_cidr_v4 = ""
# allowed_cidr_v6 = ""
