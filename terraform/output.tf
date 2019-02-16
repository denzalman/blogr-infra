output "consul_public_8500" {
  value = "${aws_instance.consul.public_ip}"
}

# output "mysql_public" {
#   value = "${aws_instance.percona_master.public_ip}"
# }

# output "blogr_public_5000" {
#   value = "${aws_instance.blogr.*.public_ip}"
# }
