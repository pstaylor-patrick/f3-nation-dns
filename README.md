# f3-nation-dns

Terraform for F3 Nation domain redirects.

## redirects/

Infra in `f3-nation-production` (522501930613); DNS records in the hosted zones in `f3-nation-dns` (538116017554).

| Host (apex and www) | 301 to |
| --- | --- |
| f3region.info | https://regions.f3nation.com |
| f3regions.com | https://regions.f3nation.com |
| f3challenges.org | https://f3nation.com |

Path and query string are kept. One CloudFront distribution answers every request with a CloudFront Function, so there is no origin and no S3 bucket. One ACM certificate covers all six hosts.

Other records in these zones (for example `staging.f3regions.com`, `admin.f3regions.com`) are not managed here.

State: `s3://f3-nation-production-tfstate-522501930613/redirects/terraform.tfstate`, locked with an S3 lockfile (`use_lockfile`). The bucket was created once by hand with versioning, encryption and public access blocked.

```sh
aws sso login --sso-session personal-sso
cd redirects
terraform init
terraform plan
terraform apply
```

Add a redirect by adding an entry to `var.redirects`; the zone must already exist in `f3-nation-dns`.
