resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name ="main-vpc"
  }
}

resource "aws_subnet" "subnet_public_a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "192.168.100.0/24"
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "subnet-public-a"
    }
}

resource "aws_subnet" "subnet_public_c" {
    vpc_id = aws_vpc.main.id
    cidr_block = "192.168.200.0/24"
    availability_zone = "ap-northeast-1c"

    tags = {
        Name = "subnet-public-c"
    }
}

resource "aws_subnet" "subnet_private_a" {
    vpc_id = aws_vpc.main.id
    cidr_block = "192.168.0.0/25"
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "subnet-private-a"
    }
}

resource "aws_subnet" "subnet_private_c" {
    vpc_id = aws_vpc.main.id
    cidr_block = "192.168.0.128/25"
    availability_zone = "ap-northeast-1c"

    tags = {
        Name = "subnet-private-c"
    }
}

resource "aws_vpc_endpoint" "main_s3_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  tags = {
    Name = "main-s3"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "main_rtb_public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-rtb-public"
  }
}

resource "aws_route" "main_route_to_internet" {
  route_table_id         = aws_route_table.main_rtb_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route_table_association" "main_associate_rtb_public_a" {
  subnet_id      = aws_subnet.subnet_public_a.id
  route_table_id = aws_route_table.main_rtb_public.id
}

resource "aws_route_table_association" "main_associate_rtb_public_c" {
  subnet_id      = aws_subnet.subnet_public_c.id
  route_table_id = aws_route_table.main_rtb_public.id
}


resource "aws_route_table" "main_rtb_private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-rtb-private-1a"
  }
}

resource "aws_route" "private_1a_route_to_nat" {
  route_table_id         = aws_route_table.main_rtb_private_1a.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id        = aws_instance.nat_a.primary_network_interface_id
}

resource "aws_route_table_association" "main_associate_rtb_private_a" {
  subnet_id      = aws_subnet.subnet_private_a.id
  route_table_id = aws_route_table.main_rtb_private_1a.id
}

resource "aws_vpc_endpoint_route_table_association" "main_associate_endpoint_private_a" {
  vpc_endpoint_id = aws_vpc_endpoint.main_s3_endpoint.id
  route_table_id  = aws_route_table.main_rtb_private_1a.id
}

resource "aws_route_table" "main_rtb_private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-rtb-private-1c"
  }
}

resource "aws_route" "private_1c_route_to_nat" {
  route_table_id         = aws_route_table.main_rtb_private_1c.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id        = aws_instance.nat_c.primary_network_interface_id
}

resource "aws_route_table_association" "main_associate_rtb_private_c" {
  subnet_id      = aws_subnet.subnet_private_c.id
  route_table_id = aws_route_table.main_rtb_private_1c.id
}

resource "aws_vpc_endpoint_route_table_association" "main_associate_endpoint_private_c" {
  vpc_endpoint_id = aws_vpc_endpoint.main_s3_endpoint.id
  route_table_id  = aws_route_table.main_rtb_private_1c.id
}
