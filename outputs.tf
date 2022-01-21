output "cluster_name" {
  description = "Name of the rke2 cluster"
  value       = local.uname
}

output "cluster_data" {
  description = "Data of the rke2 cluster"
  value       = local.cluster_data
}

output "server_url" {
  value = module.cp_lb.ipv4
}
