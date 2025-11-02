
resource "aws_db_subnet_group" "main" {
    name = "subnet_private_group"
    subnet_ids = [
        aws_subnet.subnet_private_a.id,
        aws_subnet.subnet_private_c.id
    ]
  tags = {
    Name = "MainDBSubnetGroup"
  }
}

resource "aws_db_instance" "main_db" {
    identifier = "maindb"
    allocated_storage = 20
    engine = "mysql"
    engine_version = "8.0.42"
    instance_class = "db.t3.micro"
    db_name = "maindb"
    username  = local.rds_credentials.username
    password  = local.rds_credentials.password
    skip_final_snapshot = true
    publicly_accessible = false
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
    db_subnet_group_name = aws_db_subnet_group.main.name
    availability_zone = "ap-northeast-1a"

    tags = {
      Name = "MainDB"
    }
}


