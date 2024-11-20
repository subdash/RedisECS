resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "public_elastic_ip" {
  domain = "vpc"
}

// Put the NAT gateway in the public subnet. In the route table
// associated with the private subnet, we provide a route to the
// NAT gateway. Resources can live in the private subnet, and
// be able to egress to the Internet via the public route table's
// route to our Internet gateway.
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.public_elastic_ip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rtb_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
}

resource "aws_route_table_association" "private_rtb_association" {
  depends_on = [aws_subnet.private1, aws_subnet.private2]
  for_each = {
    subnet1-id = aws_subnet.private1.id
    subnet2-id = aws_subnet.private1.id
  }
  subnet_id      = each.value
  route_table_id = aws_route_table.private_route_table.id
}
