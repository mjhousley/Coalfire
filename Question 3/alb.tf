#Create Application Load Balancer
resource "aws_lb" "external-elb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webaccess-sg.id]
  subnets            = [aws_subnet.wp-private-subnets[0].id, aws_subnet.wp-private-subnets[1].id]
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cf-vpc.id
}

resource "aws_lb_target_group_attachment" "external-elb" {
  count            = var.item_count
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.wp-server[count.index].id
  port             = 80

  depends_on = [
    aws_instance.wp-server[1]
  ]
}

resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}

# Create Web Access Security Group
resource "aws_security_group" "webaccess-sg" {
  name        = "webaccess-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.cf-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webaccess-sg"
    Environment = var.app_environment
  }
}