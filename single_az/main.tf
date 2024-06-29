resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = {
    Name     = "terraform-sandbox-${var.suffix}"
  }
}

resource "aws_security_group" "ssh_sg" {
  name        = "ssh_sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH ingress"
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
  tags       = {
    Name     = "ssh_sg"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.all_azs, count.index)
  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
} 

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.all_azs, count.index)
  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id  = aws_vpc.main.id
  tags    = {
    Name  = "Internet Gateway"
  }
}

resource "aws_route" "bastion_gateway_route" {
  route_table_id = aws_vpc.main.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

# Put an instance in the "primary" subnet
resource "aws_instance" "public_bastions" {
  ami           = var.debian_ami
  associate_public_ip_address = "true"
  count         = 1
  instance_type = var.base_instance_type
  key_name      = "wmcdonald@gmail.com aws ed25519-key-20211205"
  subnet_id     = aws_subnet.public_subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  tags = {
    Name         = "bastion-${count.index}"
    InstanceName = "bastion-${count.index}"
    InstanceRole = "bastion"
  }
}
