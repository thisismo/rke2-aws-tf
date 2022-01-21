variable "name" {
  description = "Nodepool name"
  type        = string
  default = ""
}

//agent_count
variable "agent_count" {
  description = "Number of agents to create"
  type        = number
  default     = 1
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "instance_type" {
  description = "Node pool instance type"
  default     = "cx21"
}

variable "tags" {
  description = "Map of additional tags to add to all resources created"
  type        = map(string)
  default     = {}
}

variable "token" {
  description = "Join token"
  type        = string
}

#
# Nodepool Variables
#

variable "ssh_authorized_keys" {
  description = "Node pool list of public keys to add as authorized ssh keys, not required"
  type        = list(string)
  default     = []
}

#
# RKE2 Variables
#
variable "server_url" {
  description = "RKE2 server url"
  type        = string
}

variable "rke2_version" {
  description = "Version to use for RKE2 server nodepool"
  type        = string
  default     = "v1.22.5+rke2r2"
}

variable "rke2_config" {
  description = "Node pool additional configuration passed as rke2 config file, see https://docs.rke2.io/install/install_options/agent_config for full list of options"
  default     = ""
}

variable "enable_ccm" {
  description = "Deploy CCM"
  type        = bool
  default     = true
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
