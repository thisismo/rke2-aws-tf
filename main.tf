locals {
  # Create a unique cluster name we'll prefix to all resources created and ensure it's lowercase
  uname = var.unique_suffix ? lower("${var.cluster_name}-${random_string.uid.result}") : lower(var.cluster_name)

  default_tags = {
    "ClusterType" = "rke2",
  }

  cluster_data = {
    name       = local.uname
    server_url = module.cp_lb.ipv4
    token      = random_password.token.result
  }
}

resource "random_string" "uid" {
  # NOTE: Don't get too crazy here, several aws resources have tight limits on lengths (such as load balancers), in practice we are also relying on users to uniquely identify their cluster names
  length  = 3
  special = false
  lower   = true
  upper   = false
  number  = true
}

#
# Cluster join token
#
resource "random_password" "token" {
  length  = 40
  special = false
}

#
# Controlplane Load Balancer
#
module "cp_lb" {
  source    = "./modules/lb"
  name      = local.uname

  internal  = var.controlplane_internal
  subnet_id = var.subnet_id
  location  = var.location
  lb_type   = var.lb_type

  tags = merge({}, local.default_tags, var.tags)
}

#
# Public Firewall
#
resource "hcloud_firewall" "firewall" {
  name = "${local.uname}-rke2-firewall"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule { #open ssh port
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "any"
    source_ips = [
      "10.0.0.0/8"
    ]
  }
  apply_to {
    label_selector = "Role=agent"
  }
  labels = merge({}, local.default_tags, var.tags)
}

#
# Server Nodepool
#
module "servers" {
  source = "./modules/nodepool"
  name   = "${local.uname}-server"

  subnet_id                   = var.subnet_id
  instance_type               = var.server_instance_type
  node_count                  = var.servers

  # Overrideable variables
  user_data                   = data.template_cloudinit_config.this[*].rendered

  tags = merge({
    "Role" = "server",
  }, var.tags)
}
