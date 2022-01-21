locals {
  name = length(var.name) == 0 ? var.cluster_name : "${var.cluster_name}-${var.name}"

  default_tags = {
    "ClusterType" = "rke2",
  }
}

#
# RKE2 Userdata
#
module "init" {
  source = "../userdata"

  server_url    = var.server_url
  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  ccm           = var.enable_ccm
  token         = var.token
  agent         = true
}

data "template_cloudinit_config" "init" {
  gzip          = true
  base64_encode = true

  # Main cloud-init config file
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/../nodepool/files/cloud-config.yaml", {
      ssh_authorized_keys = var.ssh_authorized_keys
    })
  }

  dynamic "part" {
    for_each = var.download ? [1] : []
    content {
      filename     = "00_download.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/../common/download.sh", {
        # Must not use `version` here since that is reserved
        rke2_version = var.rke2_version
        type         = "agent"
      })
    }
  }

  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content      = module.init.templated
  }
}

#
# RKE2 Node Pool
#
module "nodepool" {
  source = "../nodepool"
  name   = "${local.name}-agent"

  subnet_id = var.subnet_id
  instance_type               = var.instance_type
  user_data                    = [data.template_cloudinit_config.init.rendered]
  node_count = var.agent_count


  tags = merge({
    "Role" = "agent",
  }, local.default_tags, var.tags)
}
