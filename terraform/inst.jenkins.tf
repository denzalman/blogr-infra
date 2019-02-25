###############################################################################
# K8s Master Instance Deploy
###############################################################################

data "aws_ebs_snapshot" "jenkins" {
    most_recent = true
    filter {
        name   = "tag:Name"
        values = ["jenkins"]
    }
}

resource "aws_ebs_volume" "jenkins" {
    availability_zone = "us-east-1a"
    type = "gp2"
    #snapshot_id = "snap-03d36aaa725727046"
    snapshot_id = "${data.aws_ebs_snapshot.jenkins.id}"
}


resource "aws_volume_attachment" "jenkins_att" {
    device_name = "/dev/xvdh"
    volume_id   = "${aws_ebs_volume.jenkins.id}"
    instance_id = "${aws_instance.jenkins.id}"

    depends_on = ["aws_instance.jenkins"]
}

resource "aws_route53_record" "jenkins" {
    zone_id = "${data.aws_route53_zone.blogr.zone_id}"
    name = "jenkins.${data.aws_route53_zone.blogr.name}"
    type = "A"
    ttl = "300"
    records = ["${aws_instance.jenkins.public_ip}"]
}

resource "aws_instance" "jenkins" {
    count                  = 1
    ami                    = "${var.ubuntu_ami_id}"
    instance_type          = "${var.instance_type}"
    subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
    iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
    vpc_security_group_ids = ["${aws_security_group.test.id}"]
    key_name               = "${var.key_name}"

    user_data = "${file("./static/jenkins.sh")}"

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${tls_private_key.k8s_key.private_key_pem}"
        agent       = "false"
    }
    # provisioner "file" {
    #   source = "./static/grafana/datasource.yml"
    #   destination = "/tmp/datasource.yml"
    #   }
        
    provisioner "local-exec" {
        command = "echo ${self.id}"
    }
    # provisioner "remote-exec" {
    # when = "destroy"
    # inline = [
    #     "umount /dev/xvdh",]
    # }

    tags {
        Name        = "${var.vpc_name}-${var.environment_tag}-jenkins"
        environment = "${var.environment_tag}"
    }

    #depends_on = ["aws_instance.minion"]
}