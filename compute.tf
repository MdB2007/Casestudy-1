# AMI voor Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu*22.04*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (Ubuntu)
}

# Webserver instances in private subnets
resource "aws_instance" "webserver" {
  count         = var.app_instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_app
  subnet_id     = element([aws_subnet.app_a.id, aws_subnet.app_b.id], count.index)
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo '<h1>Hello from Terraform on instance ${count.index}</h1>' > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOT

  tags = { Name = "webserver-${count.index}" }
}

# ALB (Application Load Balancer)
resource "aws_lb" "alb" {
  name               = "webserver-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_http2                   = true
  enable_cross_zone_load_balancing = true

  tags = { Name = "webserver-alb" }
}

# ALB Target Group
resource "aws_lb_target_group" "web_tg" {
  name        = "webserver-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = { Name = "webserver-tg" }
}

# ALB Listener (HTTP → forward naar target group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Koppel EC2-instances aan target group
resource "aws_lb_target_group_attachment" "web_attach" {
  count            = var.app_instance_count
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.webserver[count.index].id
  port             = 80
}

# OpenVPN server in public subnet A (EasyRSA v3 automated)
resource "aws_instance" "openvpn" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_openvpn
  subnet_id     = aws_subnet.public_a.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.openvpn_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  user_data = <<-EOT
    #!/bin/bash
    set -eux

    # Systeem updaten
    apt-get update -y
    apt-get upgrade -y

    # OpenVPN install script ophalen
    curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
    chmod +x openvpn-install.sh

    # Non-interactive installatie
    AUTO_INSTALL=y ./openvpn-install.sh

    # Eerste client profiel kopiëren naar home
    cp /root/*.ovpn /home/ubuntu/client1.ovpn
    chown ubuntu:ubuntu /home/ubuntu/client1.ovpn
    chmod 644 /home/ubuntu/client1.ovpn
  EOT

  tags = { Name = "openvpn-server" }
}

# Prometheus instance in private subnet
resource "aws_instance" "prometheus" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.app_a.id  # Je kunt ook app_b gebruiken
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.prometheus_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y prometheus
    systemctl enable prometheus
    systemctl start prometheus
  EOT

  tags = { Name = "prometheus-server" }
}

# Grafana instance in private subnet
resource "aws_instance" "grafana" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.app_a.id  # Je kunt ook app_b gebruiken
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y apt-transport-https
    echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
    curl https://packages.grafana.com/gpg.key | sudo apt-key add -
    apt-get update -y
    apt-get install -y grafana
    systemctl enable grafana-server
    systemctl start grafana-server
  EOT

  tags = { Name = "grafana-server" }
}


