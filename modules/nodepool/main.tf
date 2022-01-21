locals {}

resource "hcloud_server" "node" {
  count       = var.node_count
  name        = "${var.name}-${count.index}"
  server_type = var.instance_type
  location    = var.location
  image       = var.image
  ssh_keys    = ["moritz"]
  user_data   = length(var.user_data) == 1 ? var.user_data[0] : var.user_data[count.index]
  labels      = var.tags
}

resource "hcloud_server_network" "node" {
  count     = var.node_count
  server_id = hcloud_server.node[count.index].id
  subnet_id = var.subnet_id
}