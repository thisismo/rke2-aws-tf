locals {
  # Handle case where target group/load balancer name exceeds 32 character limit without creating illegal names
  controlplane_name = "${substr(var.name, 0, 23)}-rke2-cp"
}

resource "hcloud_load_balancer" "controlplane" {
  name = local.controlplane_name
  load_balancer_type = var.lb_type
  location = var.location

  labels = merge({}, var.tags)
}

resource "hcloud_load_balancer_network" "srvnetwork" {
  load_balancer_id        = hcloud_load_balancer.controlplane.id
  subnet_id               = var.subnet_id
  enable_public_interface = !var.internal
}

resource "hcloud_load_balancer_service" "apiserver_service" {
  load_balancer_id    = hcloud_load_balancer.controlplane.id
  listen_port         = var.cp_port
  destination_port    = var.cp_port
  protocol            = "tcp"
}

resource "hcloud_load_balancer_service" "supervisor_service" {
  load_balancer_id    = hcloud_load_balancer.controlplane.id
  listen_port         = var.cp_supervisor_port
  destination_port    = var.cp_supervisor_port
  protocol            = "tcp"
}

resource "hcloud_load_balancer_target" "load_balancer_target" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.controlplane.id
  label_selector   = "Role=server"
}