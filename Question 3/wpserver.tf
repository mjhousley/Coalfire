data template_file "user_data" {
  template = file("./userdata.txt")
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
  user_data              = data.template_file.user_data[count.index].rendered


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