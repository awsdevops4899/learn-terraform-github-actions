#################################################
# Description: Create EC2 instance using Terraform
# - Create EC2 instance with a specific AMI and instance type
# - Create security group with inbound and outbound rules
# - Create IAM role and policy for EC2 instance
# - Attach IAM role to EC2 instance
# - Create EBS volume and attach to EC2 instance
# - Give InstanceID and PublicIP and SecurityGroupID and Role ARN as output

# Provider configuration
provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

# Create a security group with inbound and outbound rules
resource "aws_security_group" "ec2_security_group" {
  name        = "cicd-ec2-security-group"
  description = "Allow SSH and HTTP access"

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
}

# Create an IAM role and policy for the EC2 instance
resource "aws_iam_role" "ec2_iam_role" {
  name               = "cicd-ec2-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ec2_iam_policy" {
  name   = "cicd-ec2-iam-policy"
  role   = aws_iam_role.ec2_iam_role.id
  policy = data.aws_iam_policy_document.ec2_policy.json
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    actions   = ["s3:ListBucket", "s3:GetObject"]
    resources = ["*"]
  }
  statement {
    actions = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
}

# Attach the IAM role to the EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-00a929b66ed6e0de6" # Replace with your desired AMI ID
  instance_type = "t2.micro"              # Replace with your desired instance type

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "MyEC2Instance"
    ControlledBy = "TerraformCICD"
  }

  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "cicd-test-ec2-instance-profile"
  role = aws_iam_role.ec2_iam_role.name
}

# Create an EBS volume and attach it to the EC2 instance
resource "aws_ebs_volume" "ec2_ebs_volume" {
  availability_zone = aws_instance.ec2_instance.availability_zone
  size              = 10 # Size in GB
}

resource "aws_volume_attachment" "ec2_volume_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.ec2_ebs_volume.id
  instance_id = aws_instance.ec2_instance.id
}

# Outputs
output "InstanceID" {
  value = aws_instance.ec2_instance.id
}

output "PublicIP" {
  value = aws_instance.ec2_instance.public_ip
}

output "SecurityGroupID" {
  value = aws_security_group.ec2_security_group.id
}

output "RoleARN" {
  value = aws_iam_role.ec2_iam_role.arn
}
