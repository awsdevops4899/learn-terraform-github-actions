# Description : This File is used to create an EC2 instance. 
# Only create Ec2 instance with a specific AMI and instance type.
#Role not needed in this file.

resource "aws_instance" "example" {
    ami           = "ami-0731becbf832f281e" # Replace with your desired AMI ID
    instance_type = "t2.medium" # Replace with your desired instance type
    tags = {
        Name = "cicd-ec2-test-instance"
    }
}
