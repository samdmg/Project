# configured aws provider with proper credentials
provider "aws" {
  region = "us-east-1"
  profile   = "samuel"

}

# Data source to fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to fetch the default subnet IDs
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# EC2 Instance with an outdated Linux AMI (for example, Amazon Linux 2)
resource "aws_instance" "mongodb_instance" {
  ami           = "ami-02c21308fed24a8ab"  
  instance_type = "t2.micro"  
  subnet_id     = element(data.aws_subnet_ids.default.ids, 0)

  tags = {
    Name = "MongoDB-Instance"
  }
}

# Install MongoDB using a userdata script
resource "aws_launch_configuration" "mongodb_launch_config" {
  name          = "MongoDB-Launch-Config"
  image_id     = "ami-02c21308fed24a8ab" 
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mongodb-org-<7.0> 
              systemctl start mongod
              systemctl enable mongod
              EOF
}

# Alternatively, you could use an EC2 Instance for the full setup:
resource "aws_instance" "mongodb_full_instance" {
  ami           = "ami-02c21308fed24a8ab"  
  instance_type = "t2.micro"
  subnet_id     = element(data.aws_subnet_ids.default.ids, 0)

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mongodb-org-<7.0>  
              systemctl start mongod
              systemctl enable mongod
              EOF

  tags = {
    Name = "MongoDB-Instance"
  }
}
      
# Create an S3 bucket for MongoDB backups
resource "aws_s3_bucket" "mongodb_backups" {
  bucket = "mongodb-backups-samdmg.click"  

  # Set bucket policy to allow public read access
  acl = "public-read"

  tags = {
    Name        = "MongoDB Backups samdmg.click"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.mongodb_backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.mongodb_backups.arn}/*"
      },
    ]
  })
}
