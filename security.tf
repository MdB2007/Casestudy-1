  # App SG (toegang vanaf ALB en VPN clients)
  resource "aws_security_group" "app_sg" {
    name   = "app-sg"
    vpc_id = aws_vpc.main.id

    # HTTP verkeer van ALB naar webservers
    ingress {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_sg.id]
    }

    # ICMP (ping) vanaf VPN subnet
    ingress {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # SSH naar webservers via VPN subnet
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # Optioneel: HTTP direct vanaf VPN subnet (voor debug zonder ALB)
    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "app-sg" }
  }

  # OpenVPN SG (toegang van buitenaf)
  resource "aws_security_group" "openvpn_sg" {
    name   = "openvpn-sg"
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 1194
      to_port     = 1194
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "openvpn-sg" }
  }

  # ALB SG
  resource "aws_security_group" "alb_sg" {
    name   = "alb-sg"
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "alb-sg" }
  }

  # RDS SG (alleen toegankelijk vanuit app-sg en VPN subnet)
  resource "aws_security_group" "rds_sg" {
    name   = "rds-sg"
    vpc_id = aws_vpc.main.id

    ingress {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [aws_security_group.app_sg.id]
    }

    ingress {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "rds-sg" }
  }

  # NAT Instance SG
  resource "aws_security_group" "nat_sg" {
    name   = "nat-sg"
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "nat-sg" }
  }

  # Prometheus SG
  resource "aws_security_group" "prometheus_sg" {
    name   = "prometheus-sg"
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "prometheus-sg" }
  }

  # Grafana SG
  resource "aws_security_group" "grafana_sg" {
    name   = "grafana-sg"
    vpc_id = aws_vpc.main.id

    ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
   
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "grafana-sg" }
  }

    # Sta Prometheus toe om Node Exporter (9100) op webservers te scrapen
  resource "aws_security_group_rule" "prometheus_to_node_exporter" {
    type                     = "ingress"
    from_port                = 9100
    to_port                  = 9100
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.prometheus_sg.id
    security_group_id        = aws_security_group.app_sg.id
  }

  # Sta Grafana toe om Prometheus te benaderen (9090)
  resource "aws_security_group_rule" "grafana_to_prometheus" {
    type                     = "ingress"
    from_port                = 9090
    to_port                  = 9090
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.grafana_sg.id
    security_group_id        = aws_security_group.prometheus_sg.id
  }