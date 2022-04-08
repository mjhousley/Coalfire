data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}


# Define the security group for the Bastion
resource "aws_security_group" "aws-bastion-win-sg" {
  name        = "${var.app_name}-${var.app_environment}-bastion-win-sg"
  description = "Access to Windows Bastion Server"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.remote_access_ip]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.Application-Plane-VPC.id

  tags = {
    Name        = "${var.app_name}-${var.app_environment}-bastion-win-sg"
    Environment = var.app_environment
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"
  name = "External-LB"
  load_balancer_type = "application"
  vpc_id = var.vpc.vpc_id
  subnets = var.vpc.public_subnets
  security_groups = [var.sg.lb]
  http_tcp_listeners = [
      {
          port = 80,
          protocol = "HTTP"
          target_group_index = 0
      }
  ]

  target_groups = [
      {
          name_prefix = "ALB-TG-01",
          backend_protocol = "HTTP",
          backend_port = 8080
          target_type = "instance"
      }
  ]
}

# Create EC2 Instance for Windows Bastion Server
resource "aws_instance" "aws-bastion-win" {
  ami                         = data.aws_ami.windows-2019.id
  instance_type               = "t3.medium"
  key_name                    = var.aws_key_name
  subnet_id                   = aws_subnet.public-subnets[0].id
  vpc_security_group_ids      = [aws_security_group.aws-bastion-win-sg.id]
  associate_public_ip_address = true
  source_dest_check           = false

  root_block_device {
            volume_size = 50
  }

  tags = {
    Name        = "bastion1"
    Environment = var.app_environment
  }
}
#Create WP Instances

# Modify the template file to set the hostname.
data template_file "user_data" {
  template = file("./user-data.tpl")
  count    = var.item_count
  vars = {
    hostname = "wpserver${count.index + 1}"
  }
}

resource "aws_instance" "wp-server" {
  count                  = var.item_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.aws_key_name
  availability_zone      = var.availability_zones[count.index]
  vpc_security_group_ids = [aws_security_group.wp-server-sg.id]
  subnet_id              = aws_subnet.wp-private-subnets[count.index].id
  #user_data              = file("config-linux.sh")
  user_data              = data.template_file.user_data[count.index].rendered
  #associate_public_ip_address = false

  root_block_device {
            volume_size = 20
  }

  tags = {
    Name = "wpserver${count.index + 1}"
    Environment = var.app_environment
  }
  depends_on = [
    aws_route_table_association.wp-private-subnet-route-table-association
  ]
}

# Create WP Access Security Group
resource "aws_security_group" "wp-server-sg" {
  name        = "wp-server-sg"
  description = "wp-server-sg"
  vpc_id      = aws_vpc.Application-Plane-VPC.id
  tags = {
    Name = "wp-server-sg"
    Environment = var.app_environment
  }
}

# Create rules for WP Access Security Group
resource "aws_security_group_rule" "AllowHTTP" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  #cidr_blocks              = ["0.0.0.0/0"]
  source_security_group_id = aws_security_group.webaccess-sg.id
  security_group_id        = aws_security_group.wp-server-sg.id
}

# Create rules for WP Access Security Group - SSH from Bastion
resource "aws_security_group_rule" "AllowSSHFromBastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  #cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wp-server-sg.id
}

# Create rules for WP Access Security Group - Egress
resource "aws_security_group_rule" "Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wp-server-sg.id
}