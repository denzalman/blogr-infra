# AWS CREDENTIALS
# variable "aws_access_key" {
#   description = "AWS access key"
#   default     = ""
# }

# variable "aws_secret_key" {
#   description = "AWS secret key"
#   default     = ""
# }

# variable "private_key_path" {
#   description = "Path to private key .pem file"
#   default = ""
# }

# variable "key_name" {
#   description = "AWS key name"
#   default = ""
# }

variable "vpc_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment_tag" {
  description = "Name of environment"
  default = "dev"
}

# VPC Config
variable "vpc_name" {
  description = "VPC for building demos"
  default     = "k8s"
}

variable "vpc_cidr_block" {
  description = "IP addressing for VPC Network"
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Public Subnet Count"
  default     = 1
}

variable "minions_count" {
  description = "Minions Instnces Count"
  default     = 1
}

# Instances Config
# TODO: Find list with Ubuntu AMIs and implement choise by region
variable "ubuntu_ami_id" {
  description = "AMI ID for ubuntu image"
  default = "ami-0f9cf087c1f27d9b1"
}

variable "instance_type" {
  description = "Amazon instance type for new instances"
  default     = "t2.micro"
}

variable "k8s_master_instance_type" {
  description = "Amazon instance type for new instances"
  default     = "t2.micro"
}

variable "k8s_minion_instance_type" {
  description = "Amazon instance type for new instances"
  default     = "t3.small"
}