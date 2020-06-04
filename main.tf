provider "aws" {
  region = "ap-northeast-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


data "aws_ami" "main" {
  owners      = ["self", "amazon"]
  most_recent = true
  name_regex  = "^amzn2-ami"
}

resource "aws_key_pair" "main" {
  key_name   = "ytamura-test"
  public_key = file("./id_rsa.pub")
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
    Name = "main"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.main.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.main.key_name
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "main"
  }
  private_ip                  = "10.0.1.10"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.web.id]
}

output "web_ip_addr" {
  value = aws_instance.web.public_ip
}

output "web_dns" {
  value = aws_instance.web.public_dns
}


resource "aws_security_group" "db" {
  name   = "db"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "main"
  }
}

resource "aws_instance" "db" {
  ami           = data.aws_ami.main.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.main.key_name
  subnet_id     = aws_subnet.private.id
  tags = {
    Name = "main"
  }
  private_ip      = "10.0.2.10"
  security_groups = [aws_security_group.db.id]
}

resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "db" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "db"
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.db.id
  }

  tags = {
    Name = "db"
  }
}

resource "aws_route_table_association" "db" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.db.id
}
