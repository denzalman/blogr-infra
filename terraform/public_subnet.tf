######## Public subnet 
######## all outgouing traffic through internet gateway
resource "aws_subnet" "public" {
  count             = "${var.public_subnet_count}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr_block, 8, count.index + 10)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = "true"
  tags {
    Name = "${var.vpc_name}-${var.environment_tag}-public-${count.index + 1}"
    Environment = "${var.environment_tag}"
  }
}

### Routing table
resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.vpc_name}-${var.environment_tag}-public-rt"
    Environment = "${var.environment_tag}"
  }
}

resource "aws_route" "gateway_route" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internet_gateway.id}"

  depends_on = ["aws_internet_gateway.internet_gateway"]
}

### Associate the routing table to public subnet
resource "aws_route_table_association" "public_rt_assn" {
  count          = "${var.public_subnet_count}"
  subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}