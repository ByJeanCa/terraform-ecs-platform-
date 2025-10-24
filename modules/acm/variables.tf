variable "domain" {
  type = string
  default = "glowlinecr.com"
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Base tags to merge into all resources"
}
