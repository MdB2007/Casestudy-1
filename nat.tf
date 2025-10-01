# Amazon Linux 2 AMI for NAT instance
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# NAT Instance (klein type om kosten te besparen)
resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.public_a.id
  associate_public_ip_address = true
  source_dest_check           = false # cruciaal voor NAT
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]
  key_name                    = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              sysctl -w net.ipv4.ip_forward=1
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              EOF

  tags = { Name = "nat-instance" }
}

# Route table for private subnets (via NAT instance)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block         = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = { Name = "private-rt" }
}

# Associate private subnets with private RT
resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.private.id
}