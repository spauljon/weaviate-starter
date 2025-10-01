# (A) Look up an existing private hosted zone
data "aws_route53_zone" "internal" {
  count = var.create_private_zone ? 0 : 1
  name         = var.private_zone_name
  private_zone = true
}

# (B) Create the private hosted zone (attach to this VPC)
resource "aws_route53_zone" "internal" {
  count = var.create_private_zone ? 1 : 0
  name  = var.private_zone_name
  vpc {
    vpc_id = var.vpc_id
  }
  comment = "Private zone for internal service discovery"
}

# Alias record pointing to NLB (no hard-coded IPs)
resource "aws_route53_record" "weaviate_internal" {
  zone_id = coalesce(
    try(aws_route53_zone.internal[0].zone_id, null),
    try(data.aws_route53_zone.internal[0].zone_id, null)
  )

  name = "${var.weaviate_internal_hostname}.${var.private_zone_name}"
  type = "A"

  alias {
    name                   = aws_lb.weaviate_nlb.dns_name
    zone_id                = aws_lb.weaviate_nlb.zone_id
    evaluate_target_health = true
  }
}
