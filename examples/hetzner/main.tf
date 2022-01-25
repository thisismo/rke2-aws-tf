provider "hcloud" {
  token = local.hcloud_token
}

locals {
  cluster_name = "prod"
  hcloud_token = "23TnQRzzhJRT1dl6QIFxIKq0dn8RjJTL4kpHgt1hFuArmwARGvSI8R4eHnwr1mRd"
  server_count = 3
  agent_count  = 3

  tags = {
    "terraform" = "true",
    "env"       = "prod",
  }
}

# Key Pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_pem" {
  filename        = "${local.cluster_name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

#
# Network
#
resource "hcloud_network" "private" {
  name     = "${local.cluster_name}-network"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.private.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}

#
# Server
#
module "rke2" {
  source = "../.."

  cluster_name = local.cluster_name
  hcloud_token = local.hcloud_token
  subnet_id    = hcloud_network_subnet.subnet.id
  network_id   = hcloud_network.private.id

  ssh_authorized_keys   = [tls_private_key.ssh.public_key_openssh]
  server_instance_type  = "cx21"
  agent_instance_type   = "cx21"
  controlplane_internal = false # Note this defaults to best practice of true, but is explicitly set to public for demo purposes
  servers               = local.server_count
  agents                = local.agent_count

  # Enable Hetzner Cloud Controller Manager
  enable_ccm = true

  rke2_config = <<-EOT
node-label:
  - "name=server"
  - "os=ubuntu20.04"
disable:
  - "rke2-ingress-nginx"
EOT

  tags = local.tags
}

#
# Generic agent pool
#
module "agents" {
  source = "../../modules/agent-nodepool"

  name    = ""
  subnet_id  = hcloud_network_subnet.subnet.id
  ssh_authorized_keys = [tls_private_key.ssh.public_key_openssh]
  instance_type       = "cx21"
  server_url = module.rke2.server_url

  # Enable AWS Cloud Controller Manager and Cluster Autoscaler
  enable_ccm        = true
  cluster_name      = module.rke2.cluster_name
  agent_count       = local.agent_count
  token             = module.rke2.cluster_data.token

  tags = local.tags
}

# Generic outputs as examples
output "rke2" {
  value = module.rke2
  sensitive = true
}

# Example method of fetching kubeconfig from state store, requires aws cli and bash locally
/*resource "null_resource" "kubeconfig" {
  depends_on = [module.rke2]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws s3 cp ${module.rke2.kubeconfig_path} rke2.yaml"
  }
}*/