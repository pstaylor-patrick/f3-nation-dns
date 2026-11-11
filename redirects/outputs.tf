output "distribution_domain" {
  value = aws_cloudfront_distribution.redirects.domain_name
}

output "redirects" {
  value = { for host, h in local.hosts : host => "https://${h.target}" }
}
