#VPC variables

# Define application name
variable "app_name" {
  type        = string
  description = "Application name"
  default     = "client.app"
}

variable "aws_key_name" {
  type        = string
  description = "AWS Key Name"
  default     = "coalfire"
}

# Define app environment
variable "app_environment" {
  type        = string
  description = "Application environment"
  default     = "production"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for the provider"
  default     = "us-east-1"
}

variable "item_count" {
  description = "Number of AZs, Subnets, Web, and App servers to deploy"
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "route53_private_domain" {
  description = "Route 53 Private Hosted Domain"
  type        = string
  default     = "clientapp.com"
}

variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidr" {
  description = "List of subnet CIDRs for Public access"
  type        = list(string)
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "WP_private_subnet_cidr" {
  description = "List of subnet CIDRs for Private Web access"
  type        = list(string)
  default     = ["10.1.2.0/24", "10.1.3.0/24"]
}

variable "DB_private_subnet_cidr" {
  description = "List of subnet CIDRs for Private DB access"
  type        = list(string)
  default     = ["10.1.4.0/24", "10.1.5.0/24"]
}

#Instance variables
variable "ami_id" {
  description = "default ami"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  description = "default instance type"
  type        = string
  default     = "t3a.micro"
}


# Database Variables
variable "rds_postgres" {
  type = map(any)
  default = {
    allocated_storage   = 10
    engine              = "postgres"
    engine_version      = "11.15"
    instance_class      = "db.t3.micro"
    multi_az            = false
    name                = "RDS1"
    skip_final_snapshot = true
  }
}

# These would be better kept in a secrets vault. 
variable "user_information" {
  type = map(any)
  default = {
    username = "username"
    password = "password"
  }
  sensitive = true
}

variable "remote_access_ip" {
  type        = string
  default     = "98.230.82.175/32"
  description = "IP address for remote access to Bastion"
}