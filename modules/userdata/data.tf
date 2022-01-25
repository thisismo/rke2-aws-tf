locals {
  csi_yaml = file("${path.module}/files/hcloud-csi.yaml")
  ccm_yaml = file("${path.module}/files/hcloud-ccm.yaml")
  cilium_yaml = file("${path.module}/files/cilium-config.yaml")
}

data "template_file" "init" {
  template = file("${path.module}/files/rke2-init.sh")

  vars = {
    type = var.agent ? "agent" : "server"

    server_url   = var.server_url
    token        = var.token
    config       = var.config
    ccm          = var.ccm
    server_type  = var.is_leader ? "leader" : "server"

    hcloud_token = var.hcloud_token
    hcloud_network = var.hcloud_network_id

    ccm_manifest = local.ccm_yaml
    csi_manifest = local.csi_yaml
    cilium_config = local.cilium_yaml

    pre_userdata  = var.pre_userdata
    post_userdata = var.post_userdata
  }
}