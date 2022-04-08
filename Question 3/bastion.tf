# Get latest Windows Server 2019 AMI
data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}

#Security group for the Bastion
resource "aws_security_group" "aws-bastion-win-sg" {
  name        = "${var.app_name}-${var.app_env}-bastion-win-sg"
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

  vpc_id = aws_vpc.cf-vpc.id

  tags = {
    Name        = "${var.app_name}-${var.app_env}-bastion-win-sg"
    Environment = var.app_env
  }
}

# Create a Windows Bastion Server instance on EC2
resource "aws_instance" "aws-bastion-win" {
  ami                         = data.aws_ami.windows-2019.id
  instance_type               = "t3.medium"
  key_name                    = var.aws_key_name
  subnet_id                   = aws_subnet.public-subnets[0].id
  vpc_security_group_ids      = [aws_security_group.aws-bastion-win-sg.id]
  associate_public_ip_address = true
  user_data                   = file("windows-config.tpl")
  source_dest_check           = false

  root_block_device {
            volume_size = 50
  }

  tags = {
    Name        = "bastion-01"
    Environment = var.app_env
  }
}
