
variable "location" {
	default = "northeurope"
}

variable "prefix" {
  default = "VM"
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

variable "admin_username" {
  default = "team4"
}

variable "admin_password" {
  default = "Password123"
}


variable subscription_id {
    type = string
}

variable client_appId {
    type = string
}

variable client_password {
    type = string
}

variable tenant_id {
    type = string
}