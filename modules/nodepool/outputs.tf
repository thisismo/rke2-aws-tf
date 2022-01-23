//output ipv4s
output "node_ips" {
    value = hcloud_server_network.node[*].ip
}

output "node_external_ips" {
    value = hcloud_server.node[*].ipv4_address
}