variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type_app" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_openvpn" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  default = "EC2-Keypair"
}

# RDS settings
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_username" {
  type    = string
  default = "appdb"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "ChangeMe123!"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

# Aantal app servers
variable "app_instance_count" {
  type    = number
  default = 2
}

