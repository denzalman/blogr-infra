###############################################################################
# MySQL Instances Deploy
###############################################################################

resource "random_string" "rootpassword" { 
  length = 16
  special = false
}

resource "aws_instance" "percona_master" {
  count                  = 1
  ami                    = "${var.ubuntu_ami_id}"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.test.id}"]
  key_name               = "${var.key_name}"
  private_ip             = "10.0.10.10"
  
  user_data = "${file("./static/percona_master.sh")}"

  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${tls_private_key.k8s_key.private_key_pem}"
      agent       = "false"
    }

  #wait for instance UP
  provisioner "local-exec" {
    command = "sleep 60"
  }
  
  tags {
    Name        = "${var.vpc_name}-${var.environment_tag}-percona-master"
    environment = "${var.environment_tag}"
  }

  #depends_on = ["aws_instance.minion", "aws_instance.master", "local_file.vars", "local_file.hosts"]
}