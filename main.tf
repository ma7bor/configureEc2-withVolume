terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web tier"  # Changed to ASCII characters only

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "web-sg"
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-0fb83b36371e7dab5" # us-west-2
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform</h1>" > /var/www/html/index.html
              EOF
}

resource "aws_ebs_volume" "web_volume" {
  availability_zone = aws_instance.web_instance.availability_zone
  size              = 1 # Size reduced to 1 GB

  tags = {
    Name = "web-volume-ebs"
  }

  depends_on = [aws_instance.web_instance]
}

resource "aws_volume_attachment" "web_volume_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web_volume.id
  instance_id = aws_instance.web_instance.id
}