resource "aws_route53_zone" "internal" {
  name = var.private_zone_name
  vpc {
    vpc_id = data.aws_vpc.default.id
  }
  comment = "Private zone for internal service discovery"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "weaviate_internal" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "${var.weaviate_internal_hostname}.${var.private_zone_name}"
  type    = "A"
  alias {
    name                   = aws_lb.weaviate_nlb.dns_name
    zone_id                = aws_lb.weaviate_nlb.zone_id
    evaluate_target_health = true
  }
}
