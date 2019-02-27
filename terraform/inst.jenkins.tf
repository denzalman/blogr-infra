###############################################################################
# K8s Master Instance Deploy
###############################################################################

# data "aws_ebs_snapshot" "jenkins" {
#     most_recent = true
#     filter {
#         name   = "tag:Name"
#         values = ["jenkins"]
#     }
# }

# resource "aws_ebs_volume" "jenkins" {
#     availability_zone = "us-east-1a"
#     type = "gp2"
#     #snapshot_id = "snap-03d36aaa725727046"
#     snapshot_id = "${data.aws_ebs_snapshot.jenkins.id}"
# }
# data "aws_ebs_volume" "ebs_volume" {
#     most_recent = true
#     filter {
#         name   = "tag:Name"
#         values = ["jenkins_data"]
#     }
# }
variable "jenkins_file_system_id" {
    type    = "string"
    default = "fs-3fdd53df"
}

data "aws_efs_file_system" "by_id" {
    file_system_id  = "${var.jenkins_file_system_id}"
}

resource "aws_efs_mount_target" "jenkins_data" {
    file_system_id  = "${var.jenkins_file_system_id}"
    subnet_id       = "${aws_subnet.public.id}"
    security_groups = ["${aws_security_group.test.id}"]
}

resource "null_resource" "delay" {
    provisioner "local-exec" {
        command = "sleep 90"
    }

    triggers = {
        "before" = "${aws_efs_mount_target.jenkins_data.id}"
    }
}

# resource "aws_volume_attachment" "jenkins_att" {
#     device_name = "/dev/xvdh"
#     volume_id   = "${data.aws_ebs_volume.ebs_volume.id}"
#     instance_id = "${aws_instance.jenkins.id}"
# }

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
        command = "sleep 60"
    }

    provisioner "file" {
        content      = "${tls_private_key.k8s_key.private_key_pem}"
        destination = "${var.key_name}.pem"
    }
    provisioner "remote-exec" {
    inline = [
        "sudo apt-get update",
        "sudo apt-get install --yes docker-ce",
        "sudo apt-get install --yes nfs-common",
        "sudo mkdir /data",
        "sudo chown -R ubuntu /data",
        "sudo chmod 775 /data",
        "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${data.aws_efs_file_system.by_id.dns_name}:/ /data",
        "sudo chmod 775 /data/jenkins_home",
        "sudo docker run -p 80:8080 -p 50000:50000 -d --rm -v /data/jenkins_home:/var/jenkins_home jenkins/jenkins",
        "sudo mv ${var.key_name}.pem /data/jenkins_home/secrets/ ",
        "sudo chmod 400 /data/jenkins_home/secrets/${var.key_name}.pem"
        ]
    }
    
    # provisioner "remote-exec" {
    # #when = "destroy"
    # on_failure = "continue"
    # inline = [
    #     "umount /dev/xvdh",]
    # }

    tags {
        Name        = "${var.vpc_name}-${var.environment_tag}-jenkins"
        environment = "${var.environment_tag}"
    }

    depends_on = ["aws_efs_mount_target.jenkins_data", "null_resource.delay"]
}