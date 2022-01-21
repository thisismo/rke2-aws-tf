variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "user_data" {
  type    = list
  default = []
}

variable "instance_type" {
  default = "cx21"
  type = string
}

variable "location" {
  description = "Hetzner datacenter where resources resides (nbg1, fsn1, hel1)"
  default     = "nbg1"
}

variable "node_count" {
  description = "Count on nodes in group"
  default     = 1
}

variable "image" {
  description = "Node boot image"
  default     = "ubuntu-20.04"
}
