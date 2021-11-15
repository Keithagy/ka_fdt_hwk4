# Write Terraform code that creates an EC2 instance which has port 22 (SSH) only accessible from your own public IP address using a specific TLS private key. All resources needed must be also provisioned by Terraform. After the EC2 instance has been created you should be able to SSH into it , but anyone else shouldn’t.


variable "name" {
  type    = string
  default = "ka-funda-devtools-hwk4"
}

locals {
  ami_id        = "ami-0f511ead81ccde020"
  instance_type = "t2.micro"
}

data "aws_vpc" "default_vpc" {
  default = true
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "local_file" "private_key" {
  content = tls_private_key.private_key.private_key_pem
  filename = "server.pem"
}

resource "aws_key_pair" "server_key" {
  key_name   = "server"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "aws_security_group" "allow_app_servers" {
  name = "allow-port-22"

  ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["103.6.151.70/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_app_servers"
  }
}

# resource "aws_network_acl" "default" {
#   vpc_id = aws_vpc.default_vpc.id

#   egress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "10.3.0.0/18"
#     from_port  = 443
#     to_port    = 443
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "10.3.0.0/18"
#     from_port  = 80
#     to_port    = 80
#   }

#   tags = {
#     Name = var.name
#   }
# }


resource "aws_instance" "ka-hw4" {
  ami           = local.ami_id
  instance_type = local.instance_type
  key_name = aws_key_pair.server_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_app_servers.name]

  tags = {
    Name = var.name
  }
}
