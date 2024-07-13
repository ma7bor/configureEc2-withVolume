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
  default     = "your value"
}

variable "AWS_ACCESS_KEY" {
  description = "The AWS access key"
  type        = string
  default     = "your value"

}

variable "AWS_SECRET_KEY" {
  description = "The AWS secret key"
  type        = string
  default     = "your value"
}
```
## Backend Configuration
# What is a Backend?
  In Terraform, a backend determines how state is loaded and how operations like apply are executed. When you use a backend, you can store your state file in a remote, shared location, which enables collaboration and keeps the state file secure.

# Why Use an S3 Backend?
  Using an S3 backend to store your Terraform state file offers several benefits:

Remote State Storage: Keeps the state file in a central location, accessible by multiple team members.
        - State Locking: Prevents concurrent operations, reducing the risk of state corruption.
        - Versioning: Allows you to maintain a history of state changes, making it easier to rollback if necessary.
        - Encryption: Ensures that your state file is securely stored.

# Backend Configuration in This Project
This project uses an S3 bucket as the backend for storing the Terraform state file. The backend configuration is specified in the main.tf file:

```hcl
terraform {
  backend "s3" {
    bucket = "s3-backend"
    key    = "terraform/state.tfstate"
    region = "us-west-1"
  }
}
```
    - bucket: The name of the S3 bucket where the state file will be stored.
    - key: The path within the bucket where the state file will be stored.
    - region: The AWS region where the S3 bucket is located.

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

## Checking the Terraform State File
  The Terraform state file is stored in the S3 bucket specified in the backend configuration. To check the contents of the ./terraform folder in the bucket that contains the .state file, you can use the AWS Management Console or the AWS CLI.

# Using AWS Management Console
  - Navigate to the S3 service.
  - Find and open the s3-backend bucket.
  - Browse to the terraform/ folder.
  You should see the state.tfstate file.

# Using AWS CLI
  List the contents of the S3 bucket: aws s3 ls s3://s3-backend/terraform/
  You should see the state.tfstate file in the output.
  
## Cleanup

To destroy the created infrastructure, run:

```sh
terraform destroy
```

## License

This project is licensed under the MIT License.