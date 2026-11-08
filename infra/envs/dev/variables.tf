variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "admin_cidr" {
  type        = string
  description = "Your public IP as x.x.x.x/32"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "github_repo" {
  type        = string
  description = "owner/repo allowed to push images, e.g. kovendhan5/opspulse"
}
