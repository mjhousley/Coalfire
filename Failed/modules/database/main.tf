# resource "random_password" "password" {
#   length = 16
#   special = true
#   override_special = "_%@/'\""
# }

resource "aws_db_instance" "RDS-01" {
  allocated_storage = 10
  engine = "postgres"
  engine_version = "11.15"
  instance_class = "db.t3.micro"
  identifier = "${var.namespace}-db-instance"
  name = "RDS-01"
  username = "admin"
  password = "password" #random_password.password.result
  db_subnet_group_name = var.vpc.database_subnet_group
  vpc_security_group_ids = [var.sg.db]
  skip_final_snapshot = true
}

# Create rules for WP Access Security Group
resource "aws_security_group_rule" "AllowPostgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  #cidr_blocks              = ["0.0.0.0/0"]
  source_security_group_id = var.sg.websvr
  security_group_id        = var.sg.db
}

# Create rules for WP Access Security Group - Egress
resource "aws_security_group_rule" "RDSEgress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.sg.db
}