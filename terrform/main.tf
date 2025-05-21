# Provider Configuration (you can specify the provider here or in the modules themselves)


provider "aws" {
  region = "us-east-1"
}



# VPC Module
module "vpc" {

  source                = "./modules/vpc"
  vpc_cidr              = "10.0.0.0/16"
  vpc_name              = "main_vpc_virginia"
  public_subnet_a_cidr  = "10.0.1.0/24"
  public_subnet_b_cidr  = "10.0.3.0/24"
  private_subnet_a_cidr = "10.0.2.0/24"
  az_a                  = "us-east-1a"
  az_b                  = "us-east-1b"
}

# Gateways Module
module "gateways" {

  source             = "./modules/gateways"
  vpc_id             = module.vpc.vpc_id
  public_subnet_a_id = module.vpc.public_subnet_a_id
  public_subnet_b_id = module.vpc.public_subnet_b_id
  private_subnet_a_id = module.vpc.private_subnet_a_id
  name_prefix        = "main"
}

# Security Groups
module "wordpress_sg_virginia" {

  source      = "./modules/security_group"
  name        = "wordpress_sg_virginia"
  description = "Allow HTTP/HTTPS and SSH to WordPress instances"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "wordpress-sg"
  }
}


module "mariadb_sg_virginia" {

  source      = "./modules/security_group"
  name        = "mariadb_sg_virginia"
  description = "Allow MariaDB connections from WordPress"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["${module.wordpress_instance_a.private_ip}/32", "${module.wordpress_instance_b.private_ip}/32"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "mariadb-sg"
  }
}

# EC2 Instances
module "wordpress_instance_a" {

  source                     = "./modules/ec2"
  ami                        = "ami-084568db4383264d4"
  instance_type              = "t2.micro"
  key_name                   = "ec2_key"
  subnet_id                  = module.vpc.public_subnet_a_id
  security_group_ids         = [module.wordpress_sg_virginia.security_group_id]
  associate_public_ip_address = true
  name                       = "wordpress_instance_a AZ 1"
    user_data = ""

}

module "wordpress_instance_b" {

  source                     = "./modules/ec2"
  ami                        = "ami-084568db4383264d4"
  instance_type              = "t2.micro"
  key_name                   = "ec2_key"
  subnet_id                  = module.vpc.public_subnet_b_id
  security_group_ids         = [module.wordpress_sg_virginia.security_group_id]
  associate_public_ip_address = true
  name                       = "wordpress_instance_a AZ 2"
  user_data = ""

}

module "mariadb_instance" {

  source                     = "./modules/ec2"
  ami                        = "ami-084568db4383264d4"
  instance_type              = "t2.micro"
  key_name                   = "ec2_key"
  subnet_id                  = module.vpc.private_subnet_a_id
  security_group_ids         = [module.mariadb_sg_virginia.security_group_id]
  associate_public_ip_address = true
  name                       = "mariadb_instance"

  user_data = ""
}



module "alb_sg_virginia" {

  source      = "./modules/security_group"
  name        = "alb_sg_virginia"
  description = "Allow HTTP access to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name = "alb_sg_virginia"
  }
}

# ALB Module
module "alb_virginia" {

  source = "./modules/alb"
  name                        = "app-lb-virginia"
  internal                    = false
  load_balancer_type          = "application"
  security_group_ids          = [module.alb_sg_virginia.security_group_id]
  subnet_ids                  = [module.vpc.public_subnet_a_id, module.vpc.public_subnet_b_id]
  enable_deletion_protection = false
  tags                        = {
    Name = "AppLBVirginia"
  }
  vpc_id             = module.vpc.vpc_id
  target_group_name  = "app-tg-virginia"
  target_group_port  = 80
  target_group_protocol = "HTTP"
  instance_id_map = {
    "wordpress-a" = module.wordpress_instance_a.instance_id
    "wordpress-b" = module.wordpress_instance_b.instance_id
  }
}





