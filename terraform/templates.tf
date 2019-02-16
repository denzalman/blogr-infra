###############################################################################
# Consul Master Count to User_Data provisioning script
###############################################################################

# data "template_file" "consul_master" {
#   template = "${file("./static/consul/consul_master.sh")}"
#   vars {
#     master_count  = "${var.consul_master_count}"
#   }
# }