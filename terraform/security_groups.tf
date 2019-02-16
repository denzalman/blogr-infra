### Test security group
resource "aws_security_group" "test" {
  name        = "Test-${var.environment_tag}-sg"
  description = "Test security group for all subnets"
  vpc_id      = "${aws_vpc.vpc.id}"

  # allow all ingoing traffic 
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  # allow all outgoing traffic 
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}