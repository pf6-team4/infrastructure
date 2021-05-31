
variable "location" {
	default = "northeurope"
}

variable "prefix" {
  default = "vm"
}

variable "tags" {
  type = map

  default = {
    Environment = "Terraform"
    Dept        = "DevOps"
  }
}

variable "sku" {
  type = map

  default = {
    northeurope = "16.04-LTS"
  }
}

variable admin_username {
  type = string
}

variable admin_password {
  type = string
}
