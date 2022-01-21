variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "lb_type" {
  type = string
  default = "lb11"
}

variable "location" {
  type = string
  default = "nbg1"
}

variable "internal" {
  default = true
  type    = bool
}

variable "cp_port" {
  type    = number
  default = 6443
}

variable "cp_supervisor_port" {
  type    = number
  default = 9345
}

variable "tags" {
  type    = map(string)
  default = {}
}