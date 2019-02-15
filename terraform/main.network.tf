###############################################################################
# PROVIDER AND SSH KEY
###############################################################################

provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region     = "${var.vpc_region}"
}

variable "key_name" {
  description = "temporary k8s AWS key name"
  default = "k8s_key"
}

resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.k8s_key.public_key_openssh}"
}

#TODO: Delete this resourse after local tests
resource "local_file" "pem" {
    content     = "${tls_private_key.k8s_key.private_key_pem}"
    filename = "../ansible/${var.key_name}.pem"

    depends_on = ["aws_key_pair.generated_key"]

    provisioner "local-exec" {
      command = "echo ${var.key_name}.pem"
      
    }
} 

###############################################################################
# DATA
###############################################################################

data "aws_availability_zones" "available" {}

###############################################################################
### NETWORK
###############################################################################

### VPC initialization
resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.vpc_name}-${var.environment_tag}-vpc"
    Environment = "${var.environment_tag}"
  }
}

### Internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.vpc_name}-${var.environment_tag}-igv"
    Environment = "${var.environment_tag}"
  }
}