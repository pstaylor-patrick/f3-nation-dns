locals {
  # host => { zone, target }
  hosts = merge([
    for zone, target in var.redirects : {
      (zone)          = { zone = zone, target = target }
      ("www.${zone}") = { zone = zone, target = target }
    }
  ]...)
}

data "aws_route53_zone" "this" {
  provider = aws.dns
  for_each = var.redirects
  name     = each.key
}

resource "aws_acm_certificate" "redirects" {
  domain_name               = keys(local.hosts)[0]
  subject_alternative_names = slice(keys(local.hosts), 1, length(local.hosts))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  provider = aws.dns
  for_each = {
    for o in aws_acm_certificate.redirects.domain_validation_options : o.domain_name => o
  }

  zone_id         = data.aws_route53_zone.this[local.hosts[each.key].zone].zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 300
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "redirects" {
  certificate_arn         = aws_acm_certificate.redirects.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

resource "aws_cloudfront_function" "redirect" {
  name    = "f3-nation-redirects"
  runtime = "cloudfront-js-2.0"
  publish = true
  code = templatefile("${path.module}/redirect.js.tftpl", {
    targets = jsonencode({ for host, h in local.hosts : host => h.target })
  })
}

resource "aws_cloudfront_distribution" "redirects" {
  enabled         = true
  comment         = "301 redirects for retired F3 domains"
  aliases         = keys(local.hosts)
  price_class     = "PriceClass_100"
  is_ipv6_enabled = true

  # Never reached: the viewer-request function answers every request.
  origin {
    domain_name = "f3nation.com"
    origin_id   = "unused"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "unused"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.redirects.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "alias" {
  provider = aws.dns
  for_each = {
    for pair in setproduct(keys(local.hosts), ["A", "AAAA"]) : "${pair[0]}/${pair[1]}" => {
      host = pair[0]
      type = pair[1]
    }
  }

  zone_id         = data.aws_route53_zone.this[local.hosts[each.value.host].zone].zone_id
  name            = each.value.host
  type            = each.value.type
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.redirects.domain_name
    zone_id                = aws_cloudfront_distribution.redirects.hosted_zone_id
    evaluate_target_health = false
  }
}
