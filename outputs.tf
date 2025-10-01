output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "openvpn_public_ip" {
  value = aws_instance.openvpn.public_ip
}

output "openvpn_private_ip" {
  value = aws_instance.openvpn.private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "nat_instance_public_ip" {
  value       = aws_instance.nat.public_ip
}

output "nat_instance_private_ip" {
  value       = aws_instance.nat.private_ip
}

output "webserver_private_ips" {
  value = [for i in aws_instance.webserver : i.private_ip]
}

output "prometheus_private_ip" {
  value = aws_instance.prometheus.private_ip
}

output "grafana_private_ip" {
  value = aws_instance.grafana.private_ip
}
