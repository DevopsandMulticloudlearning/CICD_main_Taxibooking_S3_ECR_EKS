terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
########################
# DEFAULT VPC + SUBNET
########################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################
# SECURITY GROUP
########################
resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Allow required ports"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App Port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
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

########################
# IAM ROLE (FIXES AWS ERROR)
########################
resource "aws_iam_role" "ec2_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.ec2_role.name
}

########################
# S3 BUCKET
########################
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "my-war-bucket"

  tags = {
    Name = "war-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.artifact_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

########################
# ECR REPO
########################
resource "aws_ecr_repository" "app_repo" {
  name = "taxi-booking-app"

  image_scanning_configuration {
    scan_on_push = true
  }
}

########################
# EC2 INSTANCES
########################

# ANSIBLE
resource "aws_instance" "ansible" {
  ami                    = "ami-0030e4319cbf4dbf2"
  instance_type          = "c7i-flex.large"
  key_name               = "taxi"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "ansible"
  }
}

# JENKINS MASTER
resource "aws_instance" "jenkins_master" {
  ami                    = "ami-0030e4319cbf4dbf2"
  instance_type          = "c7i-flex.large"
  key_name               = "taxi"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "jenkins-master"
  }
}

# JENKINS SLAVE
resource "aws_instance" "jenkins_slave" {
  ami                    = "ami-0030e4319cbf4dbf2"
  instance_type          = "c7i-flex.large"
  key_name               = "taxi"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "jenkins-slave"
  }
}

########################
# OUTPUTS
########################
output "s3_bucket" {
  value = aws_s3_bucket.artifact_bucket.bucket
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}