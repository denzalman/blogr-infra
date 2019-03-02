###############################################################################
# K8s Master Instance Deploy
###############################################################################
resource "aws_instance" "master" {
  count                  = "${var.k8s_master_count}"
  ami                    = "${var.ubuntu_ami_id}"
  instance_type          = "${var.k8s_master_instance_type}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  iam_instance_profile   = "${aws_iam_instance_profile.nlb_k8s_master.name}"
  vpc_security_group_ids = ["${aws_security_group.test.id}"]
  key_name               = "${var.key_name}"

  user_data = "${file("./static/k8s/master.sh")}"

  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${tls_private_key.k8s_key.private_key_pem}"
      agent       = "false"
  }

  provisioner "file" {
    source      = "../k8s/"
    destination = "$PWD"
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

resource "aws_route53_record" "master" {
    zone_id = "${data.aws_route53_zone.blogr.zone_id}"
    name = "master.${data.aws_route53_zone.blogr.name}"
    type = "A"
    ttl = "300"
    records = ["${aws_instance.master.public_ip}"]
}

resource "aws_iam_role" "nlb_k8s_master" {
  name  = "nlb_k8s_master"
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

resource "aws_iam_policy" "nlb_k8s_master" {
  name  = "nlb_k8s_master"
  description = "Allows K8s master create nlb loadBalancer"
  policy      = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "kopsK8sNLBMasterPermsRestrictive",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcs",
                "elasticloadbalancing:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

# Attach the policy
resource "aws_iam_policy_attachment" "nlb_k8s_master" {
  name  = "nlb_k8s_master"
  roles      = ["${aws_iam_role.nlb_k8s_master.name}"]
  policy_arn = "${aws_iam_policy.nlb_k8s_master.arn}"
}

# Create the instance profile
resource "aws_iam_instance_profile" "nlb_k8s_master" {
  name  = "nlb_k8s_master"
  role = "${aws_iam_role.nlb_k8s_master.name}"
}