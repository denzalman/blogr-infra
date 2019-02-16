###############################################################################
# K8s Master Instance Deploy
###############################################################################
resource "aws_instance" "master" {
  count                  = "${var.k8s_master_count}"
  ami                    = "${var.ubuntu_ami_id}"
  instance_type          = "${var.k8s_master_instance_type}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
  vpc_security_group_ids = ["${aws_security_group.test.id}"]
  key_name               = "${var.key_name}"

  user_data = "${file("./static/k8s/master.sh")}"

  connection {
      type        = "ssh"
      user        = "ubuntu"
      #private_key = "${file(var.private_key_path)}"
      private_key = "${aws_key_pair.generated_key.fingerprint}"
      agent       = "false"
    }

  # provisioner "file" {
  #   source = "./static/grafana/datasource.yml"
  #   destination = "/tmp/datasource.yml"
  #   }
    
  provisioner "local-exec" {
    command = "echo ${self.id}"
  }

  # provisioner "local-exec" {
  #       command = "sleep 10"
  #       #command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ./deployer.pem -i '${aws_instance.jenkins_master.public_ip},' master.yml"
  #   }

  tags {
    Name        = "${var.vpc_name}-${var.environment_tag}-master"
    environment = "${var.environment_tag}"
  }

  depends_on = ["aws_instance.minion"]
}