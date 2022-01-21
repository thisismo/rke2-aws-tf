module "init" {
  source = "./modules/userdata"

  server_url    = module.cp_lb.ipv4
  token         = local.cluster_data.token
  config        = var.rke2_config
  pre_userdata  = var.pre_userdata
  post_userdata = var.post_userdata
  ccm           = var.enable_ccm
  hcloud_token  = var.hcloud_token
  hcloud_network_id = var.network_id
  agent         = false
  is_leader     = count.index == 0 ? true : false

  count = var.servers
}

data "template_cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  count = var.servers

  # Main cloud-init config file
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/modules/nodepool/files/cloud-config.yaml", {
      ssh_authorized_keys = var.ssh_authorized_keys
    })
  }

  dynamic "part" {
    for_each = var.download ? [1] : []
    content {
      filename     = "00_download.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/modules/common/download.sh", {
        # Must not use `version` here since that is reserved
        rke2_version = var.rke2_version
        type         = "server"
      })
    }
  }

  part {
    filename     = "01_rke2.sh"
    content_type = "text/x-shellscript"
    content      = module.init[count.index].templated
  }
}
