provider "aws" {
  region = "us-east-1"
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "assignment2-ec2" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.medium"
  # key_name                    = "vockey"
  vpc_security_group_ids      = [aws_security_group.assignment2-yjm-ec2_sg.id] //new
  associate_public_ip_address = true
  iam_instance_profile = "LabInstanceProfile"

  root_block_device {
    volume_size = 16
  }

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl start docker
    sudo usermod -a -G docker ec2-user
    curl -sLo kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-amd64
    sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
    rm -f ./kind
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f ./kubectl
    kind create cluster --config kind.yaml​
  EOF

  tags = {
    Name = "assignment2-yjm-clo835-ec2"
  }
  key_name   = aws_key_pair.assignment2-key-name.key_name
  monitoring = true
  # disable_api_termination = false
  ebs_optimized = true
}

resource "aws_security_group" "assignment2-yjm-ec2_sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from private IP of CLoud9 machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP8080-8083"
    from_port   = 8080
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP30000-32000"
    from_port   = 30000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "assignment2-yjm-ec2-bastion-sg"
  }
}

resource "aws_ecr_repository" "assignment2-images" {
  name                 = "assignment2-images-repo"
  image_tag_mutability = "MUTABLE"
}

resource "aws_key_pair" "assignment2-key-name" {
  key_name   = "ass2"
  public_key = file("${path.module}/ass2.pub")
}

# resource "aws_ecr_repository" "assignment2-mysql" {
#  name                 = "assignment2-mysql-repo"
#  image_tag_mutability = "MUTABLE"
#}
