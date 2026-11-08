terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Bucket/table come from backend.hcl (copy backend.hcl.example) so no values are hard-coded.
  backend "s3" {}
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "opspulse", Environment = "dev", ManagedBy = "terraform" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }

locals {
  name = "opspulse-dev"
}

module "vpc" {
  source = "../../modules/vpc"
  name   = local.name
  azs    = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "ecr" {
  source = "../../modules/ecr"
  name   = "opspulse"
}

module "k3s_node" {
  source        = "../../modules/k3s_node"
  name          = local.name
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  admin_cidr    = var.admin_cidr
  instance_type = var.instance_type
  region        = var.region
  account_id    = data.aws_caller_identity.current.account_id
}
