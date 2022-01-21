variable "cluster_name" {
  description = "Name of the rke2 cluster to create"
  type        = string
}

variable "unique_suffix" {
  description = "Enables/disables generation of a unique suffix to cluster name"
  type        = bool
  default     = true
}

variable "hcloud_token" {
  description = "HCloud token"
  type        = string
}

/*
variable "subnets" {
  description = "List of subnet IDs to create resources in"
  type        = list(string)
}*/

variable "network_id" {
  description = "ID of the network to create resources in"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to create resources in"
  type        = string
}

variable "tags" {
  description = "Map of tags to add to all resources created"
  default     = {}
  type        = map(string)
}

#
# LB variables
#
variable "lb_type" {
  description = "Type of load balancer to create"
  default     = "lb11"
  type        = string
}

#
# Server variables
#
variable "server_instance_type" {
  description = "Server type (size)"
  default     = "cx11" # 2 vCPU, 4 GB RAM, 40 GB Disk space
  validation {
    condition     = can(regex("^cx11$|^cpx11$|^cx21$|^cpx21$|^cx31$|^cpx31$|^cx41$|^cpx41$|^cx51$|^cpx51$|^ccx11$|^ccx21$|^ccx31$|^ccx41$|^ccx51$", var.server_instance_type))
    error_message = "Server type is not valid."
  }
}

variable "agent_instance_type" {
  description = "Agent type (size)"
  default     = "cx21" # 2 vCPU, 4 GB RAM, 40 GB Disk space
  validation {
    condition     = can(regex("^cx11$|^cpx11$|^cx21$|^cpx21$|^cx31$|^cpx31$|^cx41$|^cpx41$|^cx51$|^cpx51$|^ccx11$|^ccx21$|^ccx31$|^ccx41$|^ccx51$", var.agent_instance_type))
    error_message = "Agent type is not valid."
  }
}

variable "location" {
  description = "Hetzner Cloud location where resources resides (e.g. nbg1, fsn1, hel1)"
  default = "nbg1"
}

variable "servers" {
  description = "Number of servers to create"
  type        = number
  default     = 1
}

variable "agents" {
  description = "Number of agents to create"
  type        = number
  default     = 1
}

variable "ssh_authorized_keys" {
  description = "Server pool list of public keys to add as authorized ssh keys"
  type        = list(string)
  default     = []
}

#
# Controlplane Variables
#
variable "controlplane_internal" {
  description = "Toggle between public or private control plane load balancer"
  default     = false
  type        = bool
}

#
# RKE2 Variables
#
variable "rke2_version" {
  description = "Version to use for RKE2 server nodes"
  type        = string
  default     = "v1.22.5+rke2r2"
}

variable "rke2_config" {
  description = "Server pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/server_config for full list of options"
  type        = string
  default     = ""
}

variable "download" {
  description = "Toggle best effort download of rke2 dependencies (rke2 and aws cli), if disabled, dependencies are assumed to exist in $PATH"
  type        = bool
  default     = true
}

variable "pre_userdata" {
  description = "Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed"
  type        = string
  default     = ""
}

variable "post_userdata" {
  description = "Custom userdata to run immediately after rke2 node attempts to join cluster"
  type        = string
  default     = ""
}

variable "enable_ccm" {
  description = "Toggle enabling the cluster as aws aware, this will ensure the appropriate IAM policies are present"
  type        = bool
  default     = true
}
