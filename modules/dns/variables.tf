variable "domain" {
  type    = string
  default = "glowlinecr.com"
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Base tags to merge into all resources"
}

variable "dvo" {
  type = list(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
  default = []
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

