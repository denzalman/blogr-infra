###############################################################################
# Minions Instances Deploy
###############################################################################

resource "aws_instance" "minion" {
  count                  = "${var.minions_count}"
  ami                    = "${var.ubuntu_ami_id}"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  key_name               = "${var.key_name}"

  vpc_security_group_ids = ["${aws_security_group.test.id}"]
  #change SG to real after all tests
  
  #wait for instance UP
  provisioner "local-exec" {
    command = "echo ${self.id}"
  }

  user_data = "${file("./static/k8s/minion.sh")}"

  tags {
    Name        = "${var.vpc_name}-${var.environment_tag}-minion-${count.index + 1}"
    environment = "${var.environment_tag}"
  }

  #depends_on = ["aws_subnet.private"]
}

