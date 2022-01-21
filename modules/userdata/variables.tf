variable "agent" {
  description = "Toggle server or agent init, defaults to agent"
  type        = bool
  default     = true
}

variable "is_leader" {
  description = "Toggle leader or follower, defaults to follower"
  type        = bool
  default     = false
}

variable "server_url" {
  description = "rke2 server url"
  type        = string
}

variable "token" {
  description = "Join token"
  type        = string
  default     = "token"
}

variable "config" {
  description = "RKE2 config file yaml contents"
  type        = string
  default     = ""
}

#
# Cloud Controller Manager
#
variable "ccm" {
  description = "Toggle cloud controller manager"
  type        = bool
  default     = true
}

variable "hcloud_token" {
  description = "HCloud token"
  type        = string
  default     = ""
}

variable "hcloud_network_id" {
  description = "HCloud network id"
  type        = string
  default     = ""
}

#
# Custom Userdata
#
variable "pre_userdata" {
  description = "Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed"
  default     = ""
}

variable "post_userdata" {
  description = "Custom userdata to run immediately after rke2 node attempts to join cluster"
  default     = ""
}
