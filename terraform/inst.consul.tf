###############################################################################
# Consul Master Instances Deploy
###############################################################################

resource "aws_instance" "consul" {
  count                  = "${var.consul_master_count}"
  ami                    = "${var.ubuntu_ami_id}"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  key_name               = "${var.key_name}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"

  vpc_security_group_ids = ["${aws_security_group.test.id}"]
  # vpc_security_group_ids = ["${aws_security_group.consul_public.id}",
  #                           "${aws_security_group.consul_private.id}"]

  # user_data = "${data.template_file.consul_master.rendered}"
  user_data = "${file("./static/consul/consul_master.sh")}"

  provisioner "local-exec" {
    command = "sleep 20"
  }
  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${tls_private_key.k8s_key.private_key_pem}"
      agent       = "false"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir ansible",
      "chmod 700 ansible",
      "sleep 10"
  ]}

  provisioner "file" {
    source      = "../ansible/"
    destination = "$PWD/ansible/"
  }

  provisioner "file" {
    content      = "${tls_private_key.k8s_key.private_key_pem}"
    destination = "./ansible/${var.key_name}.pem"
  }

  provisioner "remote-exec" {
    on_failure = "continue"
    inline = [
      "sleep 30",
      "cd ansible/",
      "chmod 400 ${var.key_name}.pem",
      "ansible-playbook kube-claster-all.yml",
    ]
  }

  tags {
    Name        = "consul-master"
    environment = "${var.environment_tag}"
  }

  depends_on = ["aws_key_pair.generated_key", 
                "aws_instance.master", 
                "aws_instance.minion", 
                "local_file.hosts",
                "local_file.vars"]
}

resource "aws_iam_role" "consul-join" {
  name  = "consul-join"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create the policy
resource "aws_iam_policy" "consul-join" {
  name  = "consul-join"
  description = "Allows Consul nodes to describe instances for joining."
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the policy
resource "aws_iam_policy_attachment" "consul-join" {
  name  = "consul-join"
  roles      = ["${aws_iam_role.consul-join.name}"]
  policy_arn = "${aws_iam_policy.consul-join.arn}"
}

# Create the instance profile
resource "aws_iam_instance_profile" "consul-join" {
  name  = "consul-join"
  role = "${aws_iam_role.consul-join.name}"
}


