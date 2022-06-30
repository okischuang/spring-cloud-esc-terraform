terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "okis-terraform-state-bucket"
    key    = "state/terraform_state.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

locals {
  internal_alb_target_groups = {for service, config in var.microservice_config : service => config.alb_target_group if !config.is_public}
  public_alb_target_groups   = {for service, config in var.microservice_config : service => config.alb_target_group if config.is_public}
}

module "iam" {
  source   = "./modules/iam"
  app_name = var.app_name
  env      = var.env
}

module "vpc" {
  source             = "./modules/vpc"
  app_name           = var.app_name
  env                = var.env
  cidr               = var.cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

module "internal_alb_security_group" {
  source        = "./modules/security-group"
  name          = "${lower(var.app_name)}-internal-alb-sg"
  description   = "${lower(var.app_name)}-internal-alb-sg"
  vpc_id        = module.vpc.vpc_id
  ingress_rules = var.internal_alb_config.ingress_rules
  egress_rules  = var.internal_alb_config.egress_rules
}

module "public_alb_security_group" {
  source        = "./modules/security-group"
  name          = "${lower(var.app_name)}-public-alb-sg"
  description   = "${lower(var.app_name)}-public-alb-sg"
  vpc_id        = module.vpc.vpc_id
  ingress_rules = var.public_alb_config.ingress_rules
  egress_rules  = var.public_alb_config.egress_rules
}

# module "ec2_sg" {
#   source = "terraform-aws-modules/security-group/aws"

#   name   = "ec2_sg"
#   vpc_id = module.vpc.vpc_id

#   ingress_with_cidr_blocks = [
#     {
#       from_port   = 8080 #80
#       to_port     = 8080 #80
#       protocol    = "tcp"
#       description = "http port"
#       cidr_blocks = "0.0.0.0/0"
#     },
#     {
#       from_port   = 22 #22
#       to_port     = 22 #22
#       protocol    = "tcp"
#       description = "ssh port"
#       cidr_blocks = "0.0.0.0/0"
#     }
#   ]
#   egress_with_cidr_blocks = [
#     {
#       from_port = 0
#       to_port   = 0
#       protocol  = "-1"
#     cidr_blocks = "0.0.0.0/0" }
#   ]
# }

module "internal-alb" {
  source            = "./modules/alb"
  name              = "${lower(var.app_name)}-internal-alb"
  subnets           = module.vpc.private_subnets
  vpc_id            = module.vpc.vpc_id
  target_groups     = local.internal_alb_target_groups
  internal          = true
  listener_port     = 80
  listener_protocol = "HTTP"
  listeners         = var.internal_alb_config.listeners
  security_groups   = [module.internal_alb_security_group.security_group_id]
}

module "public-alb" {
  source            = "./modules/alb"
  name              = "${lower(var.app_name)}-public-alb"
  subnets           = module.vpc.public_subnets
  vpc_id            = module.vpc.vpc_id
  target_groups     = local.public_alb_target_groups
  internal          = false
  listener_port     = 80
  listener_protocol = "HTTP"
  listeners         = var.public_alb_config.listeners
  security_groups   = [module.public_alb_security_group.security_group_id]
}

module "route53_private_zone" {
  source            = "./modules/route53"
  internal_url_name = var.internal_url_name
  alb               = module.internal-alb.internal_alb
  vpc_id            = module.vpc.vpc_id
}

module "ecr" {
  source           = "./modules/ecr"
  app_name         = var.app_name
  ecr_repositories = var.app_services
}

# module "ec2" {
#   source                      = "./modules/ec2"
#   ec2_security_group          = module.ec2_sg.
# }

module "ecs" {
  source                      = "./modules/ecs"
  app_name                    = var.app_name
  env                         = var.env
  app_services                = var.app_services
  account                     = var.account
  region                      = var.region
  service_config              = var.microservice_config
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_instance_role_name      = module.iam.ecs_instance_role_name
  ecs_service_role_arn        = module.iam.ecs_service_role_arn
  vpc_id                      = module.vpc.vpc_id
  private_subnets             = module.vpc.private_subnets
  public_subnets              = module.vpc.public_subnets
  public_alb_security_group   = module.public_alb_security_group
  internal_alb_security_group = module.internal_alb_security_group
  internal_alb_target_groups  = module.internal-alb.target_groups
  public_alb_target_groups    = module.public-alb.target_groups
}

