# Private Hosted Zone (internal)
resource "aws_route53_zone" "private_zone" {
  name = "internal.demo"
  vpc {
    vpc_id = aws_vpc.main.id
  }
  comment = "Private zone for internal service names"
}

# Record for ALB
resource "aws_route53_record" "alb_internal" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "alb.internal.demo"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.alb.dns_name]
}

# Record for OpenVPN
resource "aws_route53_record" "openvpn_internal" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "openvpn.internal.demo"
  type    = "A"
  ttl     = 300
  records = [aws_instance.openvpn.private_ip]
}
