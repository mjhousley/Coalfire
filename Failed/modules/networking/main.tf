data "aws_availability_zones" "available" {}

module "vpc" {
  source                           = "terraform-aws-modules/vpc/aws"
  version                          = "2.64.0"
  name                             = "${var.namespace}-vpc"
  cidr                             = "10.1.0.0/16"
  azs                              = data.aws_availability_zones.available.names
  private_subnets                  = ["10.1.2.0/24", "10.1.3.0/24"]
  public_subnets                   = ["10.1.0.0/24", "10.1.1.0/24"]
  database_subnets                 = ["10.1.4.0/24", "10.1.5.0/24"]
  
  create_database_subnet_group     = true
  enable_nat_gateway               = true
  single_nat_gateway               = true
  create_igw                       = true
  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.name}-default" }
  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.name}-default" }
  create_route_table         = true
}

module "lb_sg" {
  source = "terraform-in-action/sg/aws"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [{
    port        = 80
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

module "websvr_sg" {
  source = "terraform-in-action/sg/aws"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port            = 8080
      security_groups = [module.lb_sg.security_group.id]
    },
    {
      port        = 22
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}

module "db_sg" {
  source = "terraform-in-action/sg/aws"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [{
    port            = 3306
    security_groups = [module.websvr_sg.security_group.id]
  }]
}
