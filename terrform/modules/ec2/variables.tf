variable "ami" {}
variable "instance_type" {}
variable "key_name" {}
variable "subnet_id" {}
variable "security_group_ids" {
  type = list(string)
}
variable "associate_public_ip_address" {
  type = bool
  default = false
}
variable "name" {}
variable user_data {}