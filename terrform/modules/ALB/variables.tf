variable "name" {}
variable "internal" {
  type    = bool
  default = false
}
variable "load_balancer_type" {
  default = "application"
}
variable "security_group_ids" {
  type = list(string)
}
variable "subnet_ids" {
  type = list(string)
}
variable "enable_deletion_protection" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {}
variable "target_group_name" {}
variable "target_group_port" {
  type = number
}
variable "target_group_protocol" {
  type = string
}


# variable "instance_id" {
#   description = "List of EC2 instance IDs to register"
#   type        = list(string)
# }

variable "instance_id_map" {
  description = "Map of instance IDs to register"
  type        = map(string)
}
