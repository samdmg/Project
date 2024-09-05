provider "aws" {
  region = "us-east-1"  
}

resource "aws_instance" "mongodb_instance" {
  ami                = "ami-0e86e20dae9224db8"  
  instance_type     = "t2.micro"      
  key_name           = "training" 
  security_groups    = [aws_security_group.allow_ssh.name]
  
  user_data = <<-EOF
              #!/bin/bash
              # Update the package manager
              apt-get update -y

              # Install Maven (for any necessary dependencies)
              apt-get install -y wget gnupg

              # Add MongoDB repository
              echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.6 multiverse" \
              | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
              wget -qO - https://www.mongodb.org/static/pgp/server-3.6.asc | apt-key add -

              # Install MongoDB
              apt-get update -y
              apt-get install -y mongodb-org=3.6.23 mongodb-org-server=3.6.23 \
              mongodb-org-shell=3.6.23 mongodb-org-mongos=3.6.23 \
              mongodb-org-tools=3.6.23

              # Start MongoDB service
              systemctl start mongod
              systemctl enable mongod
              EOF

  tags = {
    Name = "MongoDBInstance"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change this to restrict access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}
