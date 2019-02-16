# data "template_file" "haproxy" {
#   template = "${file("../ansible/static/haproxy.tpl")}"
#   vars {
#     minions_private = "${join("\n", aws_instance.minion.*.private_ip)}"
#     master_private  = "${aws_instance.master.private_ip}"
#   }
# }

data "template_file" "vars" {
  template = "${file("./static/ansible/vars.tpl")}"
  vars {
    ip  = "${join("", aws_instance.master.private_ip)}"
  }
}
resource "local_file" "vars" {
    content  = "${data.template_file.vars.rendered}"
    filename = "../ansible/vars.yml"

    depends_on = ["aws_instance.master"]
}

data "template_file" "hosts" {
  template = "${file("./static/ansible/hosts.tpl")}"
  vars {
    minions = "${join("\n", aws_instance.minion.*.private_ip)}"
    master  = "${aws_instance.master.private_ip}"
  }
}

resource "local_file" "hosts" {
    content  = "${data.template_file.hosts.rendered}"
    filename = "../ansible/hosts.txt"

    depends_on = ["aws_instance.minion", 
                  "aws_instance.master"]

    # provisioner "local-exec" {
    # environment = { }
    # working_dir = "../ansible"
    # command = "ansible-playbook install-docker.yml"
    # # --private-key ${tls_private_key.k8s_key.private_key_pem}
    # }

    # provisioner "local-exec" {
    # environment = { }
    # working_dir = "../ansible"
    # command = "ansible-playbook k8s-common.yml"
    # }

    # provisioner "local-exec" {
    # environment = { }
    # working_dir = "../ansible"
    # command = "ansible-playbook k8s-master.yml"
    # }

    # provisioner "local-exec" {
    # environment = { }
    # working_dir = "../ansible"
    # command = "ansible-playbook k8s-minion.yml"
    # }
} 


