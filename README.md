This project that sets up an infrastructure containing an EC2 instance, an EBS volume, and a security group, with the specified dependencies:

```markdown
# Terraform AWS Infrastructure Project

## Description

This project uses Terraform to create an AWS infrastructure consisting of:

- An EC2 instance
- An EBS volume
- A security group

## Dependencies and Requirements

- The EC2 instance should be created before the EBS volume.
- The security group should be created before the EC2 instance.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- AWS account with appropriate permissions
- AWS access key and secret key

## Configuration

Create a `terraform.tfvars` file with the following variables:

```hcl
AWS_ACCESS_KEY = "your_access_key"
AWS_SECRET_KEY = "your_secret_key"
AWS_REGION = "us-west-2"
source_bucket_name = "your-source-bucket"
destination_bucket_name = "your-destination-bucket"
file_name = "your-file-name"
local_file_path = "your/local/file/path"
```

## Variables

Define the following variables in your `variables.tf` file:

```hcl
variable "AWS_REGION" {
  description = "The AWS region to deploy resources to"
  default     = "us-west-2"
}

variable "AWS_ACCESS_KEY" {
  description = "The AWS access key"
  type        = string
}

variable "AWS_SECRET_KEY" {
  description = "The AWS secret key"
  type        = string
  sensitive   = true
}

variable "source_bucket_name" {
  description = "Name of the source S3 bucket"
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the destination S3 bucket"
  type        = string
}

variable "file_name" {
  description = "Name of the file to be uploaded and copied"
  type        = string
}

variable "local_file_path" {
  description = "Local path of the file to be uploaded"
  type        = string
}
```

## Terraform Configuration

Create a `main.tf` file with the following configuration:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "s3-backend"
    key    = "terraform/state.tfstate"
    region = "us-west-1"
  }
}

provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

resource "aws_security_group" "instance_security" {
  name = "terraform-test"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_ec2_instance" {
  ami                    = "ami-0c55b159cbfafe1f0" # us-west-2
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_security.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    sudo echo "<h1>Hello devopssec</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "terraform test"
  }

  depends_on = [aws_security_group.instance_security]
}

resource "aws_ebs_volume" "example" {
  availability_zone = "us-west-2a"
  size              = 10

  depends_on = [aws_instance.my_ec2_instance]
}

resource "aws_volume_attachment" "example" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.my_ec2_instance.id
}

output "instance_id" {
  value = aws_instance.my_ec2_instance.id
}

output "volume_id" {
  value = aws_ebs_volume.example.id
}

output "security_group_id" {
  value = aws_security_group.instance_security.id
}
```

## Usage

1. **Initialize the Terraform working directory**

   ```sh
   terraform init
   ```

2. **Plan and preview the infrastructure changes**

   ```sh
   terraform plan
   ```

3. **Apply the Terraform configuration**

   ```sh
   terraform apply
   ```

4. **Check the outputs**

   After applying, Terraform will output the IDs of the created resources.

## Cleanup

To destroy the created infrastructure, run:

```sh
terraform destroy
```

## License

This project is licensed under the MIT License.