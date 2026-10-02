output "load_balancer_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.app.dns_name
}

output "application_url" {
  description = "Public URL of the application"
  value       = "https://${aws_route53_record.app.fqdn}"
}