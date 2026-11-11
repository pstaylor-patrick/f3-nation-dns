variable "production_profile" {
  description = "AWS CLI profile for the f3-nation-production account."
  type        = string
  default     = "f3-nation-production"
}

variable "dns_profile" {
  description = "AWS CLI profile for the f3-nation-dns account."
  type        = string
  default     = "f3-nation-dns"
}

variable "redirects" {
  description = "Zone apex to redirect target host. Apex and www both 301 to https://<target><path>?<query>."
  type        = map(string)
  default = {
    "f3region.info"    = "regions.f3nation.com"
    "f3regions.com"    = "regions.f3nation.com"
    "f3challenges.org" = "f3nation.com"
  }
}
