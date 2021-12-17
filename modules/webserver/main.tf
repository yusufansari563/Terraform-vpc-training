
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

# 1. create vpc 
resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "developement vpc"
  }
}

# 2. create internet gateway
resource "aws_internet_gateway" "dev-gw" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    Name = "developement gateway"
  }
}

# 3. create custom Route Table
resource "aws_route_table" "dev-rt" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.dev-gw.id
  }

  tags = {
    Name = "development_table"
  }
}

# 4. create a subnet
resource "aws_subnet" "dev-subnet-1" {
  vpc_id            = aws_vpc.dev-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone

  tags = {
    Name = "development subnet"
  }
}

# 5. associate subnet with route table
resource "aws_route_table_association" "dev-associate-1" {
  subnet_id      = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.dev-rt.id
}

# 6. Create security group to allow 80,22,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_web"
  }
}

# 7. Create a network interface with an IP address in the subnet that was created in step 4

resource "aws_network_interface" "dev-NIT" {
  subnet_id       = aws_subnet.dev-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic ip address to the network interface created in step 7

resource "aws_eip" "dev-elastic-ip-1" {
  vpc                       = true
  network_interface         = aws_network_interface.dev-NIT.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.dev-gw, aws_instance.dev-instance]
}

# 9. create ubuntu server and install/enable apache2
resource "aws_instance" "dev-instance" {
  ami               = var.ami
  instance_type     = var.instance_type
  availability_zone = var.zone
  key_name          = "access-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.dev-NIT.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              EOF
  tags = {
    Name = var.server_name
  }

}
