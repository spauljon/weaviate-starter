# --- Outputs ---
output "derived_subnet_id" {
  value       = data.aws_subnet.chosen.id
  description = "Chosen subnet ID"
}

output "derived_availability_zone" {
  value       = data.aws_subnet.chosen.availability_zone
  description = "Availability Zone of chosen subnet"
}

output "derived_subnet_cidr" {
  value       = data.aws_subnet.chosen.cidr_block
  description = "CIDR block of chosen subnet"
}

output "public_ip" {
  value       = aws_instance.weaviate.public_ip
  description = "EC2 public IP"
}

output "weaviate_url" {
  value       = "http://${aws_instance.weaviate.public_ip}:8080"
  description = "Weaviate base URL"
}

output "app_runner_service_url" {
  value       = aws_apprunner_service.weaviate_agent.service_url
  description = "Public HTTPS URL for the agent (if is_publicly_accessible = true)"
}

output "weaviate_internal_fqdn" {
  description = "Internal DNS name to use for Weaviate"
  value       = aws_route53_record.weaviate_internal.fqdn
}

output "weaviate_nlb_dns_name" {
  description = "AWS-provided DNS name of the internal NLB"
  value       = aws_lb.weaviate_nlb.dns_name
}

