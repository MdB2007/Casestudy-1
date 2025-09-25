output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "openvpn_public_ip" {
  value = aws_instance.openvpn.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

# NAT Instance outputs
output "nat_instance_public_ip" {
  description = "Publiek IP-adres van de NAT instance"
  value       = aws_instance.nat.public_ip
}

output "nat_instance_private_ip" {
  description = "Privé IP-adres van de NAT instance (binnen de VPC)"
  value       = aws_instance.nat.private_ip
}
